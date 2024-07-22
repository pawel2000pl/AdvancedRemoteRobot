#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <pthread.h> 
#include <jpeglib.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>


// gcc --std=c11 -O3 cameralib.c -Wall -ljpeg -fpic -shared -o cameralib.so

struct v4l2_thread {
    pthread_t thread_id;
    int quality;
    int terminating;
    unsigned last_size;
    unsigned buffer_size;
    unsigned char* last_frame;
    unsigned char* last_frame_buf_1;
    unsigned char* last_frame_buf_2;
};


struct v4l2_context {
    int fd;
    struct v4l2_buffer buf;
    void *buffer;
    unsigned width;
    unsigned height;
    struct v4l2_thread* thread;
};


inline int constrain(int value, int min, int max) {
    return (value <= min) ? min : (value >= max) ? max : value;
}


unsigned yuv2rgb(unsigned char* yuv, unsigned int size, unsigned char* rgb) {

    unsigned char* yuvEnd = yuv+size;
    
    while (yuv < yuvEnd) {
        int y1 = (int)*(yuv++) << 8;
        int cb = (int)*(yuv++) - 128;
        int y2 = (int)*(yuv++) << 8;
        int cr = (int)*(yuv++) - 128;
        
        int r = + 360 * cr;
        int g = - 89 * cb - 184 * cr;
        int b = + 456 * cb;
     
        *(rgb++) = constrain(y1+r, 0, 65535) >> 8;
        *(rgb++) = constrain(y1+g, 0, 65535) >> 8;
        *(rgb++) = constrain(y1+b, 0, 65535) >> 8;
        *(rgb++) = constrain(y2+r, 0, 65535) >> 8;
        *(rgb++) = constrain(y2+g, 0, 65535) >> 8;
        *(rgb++) = constrain(y2+b, 0, 65535) >> 8;
    }
    
    return size * 3 / 2;
}


void fit_histogram(unsigned char* buf, unsigned size, double cut) {
    
    unsigned values[256] = {0};
    unsigned char* bufEnd = buf + size;
    unsigned int dcut = cut * size;
    for (unsigned char* i=buf;i<bufEnd;i++)
        values[*i]++;
    int min = -1;
    for (unsigned sum=0;sum<dcut;sum+=values[min])
        min++;
    int max = 256;
    for (unsigned sum=0;sum<dcut;sum+=values[max])
        max--;
    double k = 255.f / (double)constrain(max - min, 1, 255);
    double fmin = (double)min;
    
    for (unsigned char* i=buf;i<bufEnd;i++)
        *i = constrain(((double)(*i) - fmin) * k, 0, 255);
}


unsigned long encode_jpeg_to_memory(unsigned char* image, int width, int height, int quality, unsigned char* jpegBuf, unsigned long jpegSize) {
    
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;

    JSAMPROW row_pointer[1];
    int row_stride;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);

    cinfo.image_width = width;
    cinfo.image_height = height;
    cinfo.input_components = 3;
    cinfo.in_color_space = JCS_RGB;

    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE);
    jpeg_mem_dest(&cinfo, &jpegBuf, &jpegSize);
    jpeg_start_compress(&cinfo, TRUE);

    row_stride = width*3;

    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = &image[cinfo.next_scanline * row_stride];
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }

    jpeg_finish_compress(&cinfo);   
    jpeg_destroy_compress(&cinfo);
    
    return jpegSize;
}


unsigned get_frame(struct v4l2_context* context, unsigned char* jpegBuf, unsigned long jpegSize, int quality) {
    
    if (ioctl(context->fd, VIDIOC_QBUF, &context->buf) == -1) {
        perror("Failed to queue buffer");
        munmap(context->buffer, context->buf.length);
        close(context->fd);
        return 0;
    }

    if (ioctl(context->fd, VIDIOC_DQBUF, &context->buf) == -1) {
        perror("Failed to dequeue buffer");
        munmap(context->buffer, context->buf.length);
        close(context->fd);
        return 0;
    }
        
    unsigned rgbBufSize = context->buf.length * 3 / 2;
    unsigned char rgbbuf[rgbBufSize];
    yuv2rgb(context->buffer, context->buf.length, rgbbuf);
    
    fit_histogram(rgbbuf, rgbBufSize, 0.03);
    return encode_jpeg_to_memory(rgbbuf, context->width, context->height, quality, jpegBuf, jpegSize);
    
}


void *thread_fun(void *vargp) {
    struct v4l2_context* context = (struct v4l2_context*)vargp;
    while (!context->thread->terminating) {
        unsigned char* new_frame = context->thread->last_frame_buf_1 == context->thread->last_frame ? context->thread->last_frame_buf_2 : context->thread->last_frame_buf_1;
        context->thread->last_size = get_frame(context, new_frame, context->thread->buffer_size, context->thread->quality);
        context->thread->last_frame = new_frame;
    }
    return NULL;
}


unsigned get_thread_frame(struct v4l2_context* context, unsigned char* jpegBuf, unsigned long jpegSize) {
    if (!context->thread) 
        return 0;
    unsigned size = context->thread->last_size;
    if (jpegSize < size)
        return 0;
    memcpy(jpegBuf, context->thread->last_frame, size);
    context->thread->last_size = 0;
    return size;
}


int thread_frame_available(struct v4l2_context* context) {
    return context->thread && context->thread->last_size;
}


void set_thread_quality(struct v4l2_context* context, int quality) {
    if (!context->thread) return;
    context->thread->quality = quality;
}


void start_thread(struct v4l2_context* context, int quality) {
    if (!context->thread) {
        context->thread = malloc(sizeof(struct v4l2_thread));
        context->thread->terminating = 0;
        context->thread->quality = quality;
        context->thread->buffer_size = context->width * context->height * 3;
        context->thread->last_frame_buf_1 = malloc(context->thread->buffer_size);
        context->thread->last_frame_buf_2 = malloc(context->thread->buffer_size);
        context->thread->last_frame = context->thread->last_frame_buf_1;
        pthread_create(&context->thread->thread_id, NULL, thread_fun, context); 
    }
}


void stop_thread(struct v4l2_context* context) {
    if (context->thread) {
        context->thread->terminating = 1;
        pthread_join(context->thread->thread_id, NULL); 
        free(context->thread->last_frame_buf_1);
        free(context->thread->last_frame_buf_2);
    }
    free(context->thread);
    context->thread = NULL;
}


struct v4l2_context* open_device(const char* device, int width, int height) {
    
    struct v4l2_context* context = malloc(sizeof(struct v4l2_context));
    struct v4l2_format fmt;
    struct v4l2_requestbuffers req;
    
    context->fd = open(device, O_RDWR);    
    if (context->fd == -1) {
        perror("Failed to open video device");
        return NULL;
    }
    context->width = width;
    context->height = height;
    
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    fmt.fmt.pix.width = width; // Ustaw szerokość obrazu
    fmt.fmt.pix.height = height; // Ustaw wysokość obrazu
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV; // Ustaw format MJPEG
    if (ioctl(context->fd, VIDIOC_S_FMT, &fmt) == -1) {
        perror("Failed to set pixel format");
        close(context->fd);
        return NULL;
    }
            
    req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    req.memory = V4L2_MEMORY_MMAP;
    req.count = 1;
    if (ioctl(context->fd, VIDIOC_REQBUFS, &req) == -1) {
        perror("Failed to request buffers");
        close(context->fd);
        return NULL;
    }
    
    memset(&context->buf, 0, sizeof(context->buf));
    context->buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    context->buf.memory = V4L2_MEMORY_MMAP;
    context->buf.index = 0;
    if (ioctl(context->fd, VIDIOC_QUERYBUF, &context->buf) == -1) {
        perror("Failed to query buffer");
        close(context->fd);
        return NULL;
    }
    
    context->buffer = mmap(NULL, context->buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, context->fd, context->buf.m.offset);
    if (context->buffer == MAP_FAILED) {
        perror("Failed to map buffer");
        close(context->fd);
        return NULL;
    }

    if (ioctl(context->fd, VIDIOC_STREAMON, &context->buf.type) == -1) {
        perror("Failed to start streaming");
        munmap(context->buffer, context->buf.length);
        close(context->fd);
        return NULL;
    }
    
    return context;
}


void close_device(struct v4l2_context* context) {
    stop_thread(context);
    ioctl(context->fd, VIDIOC_STREAMOFF, &context->buf.type);
    munmap(context->buffer, context->buf.length);
    close(context->fd);
    free(context);
}
