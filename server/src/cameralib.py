import os
import ctypes

# Kompilacja biblioteki
os.system("gcc --std=c11 -O3 cameralib.c -ljpeg -Wall -fpic -shared -o /dev/shm/cameralib.so")

# Wczytanie biblioteki .so
lib = ctypes.CDLL("/dev/shm/cameralib.so")

# Deklaracje funkcji z biblioteki
lib.open_device.restype = ctypes.c_void_p
lib.open_device.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_int]

lib.close_device.restype = None
lib.close_device.argtypes = [ctypes.c_void_p]

lib.get_frame.restype = ctypes.c_uint
lib.get_frame.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ubyte), ctypes.c_uint, ctypes.c_int]

lib.start_thread.restype = None
lib.start_thread.argtypes = [ctypes.c_void_p, ctypes.c_int]

lib.stop_thread.restype = None
lib.stop_thread.argtypes = [ctypes.c_void_p]

lib.thread_frame_available.restype = ctypes.c_int
lib.thread_frame_available.argtypes = [ctypes.c_void_p]

lib.get_thread_frame.restype = ctypes.c_uint
lib.get_thread_frame.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ubyte), ctypes.c_uint]


lib.set_thread_quality.restype = None
lib.set_thread_quality.argtypes = [ctypes.c_void_p, ctypes.c_int]


class Camera:
    
    def __init__(self, device, width=640, height=480):
        self.context = lib.open_device(device.encode('utf-8'), width, height)
        self.width = width
        self.height = height
        if not self.context:
            raise ValueError("Failed to open device")


    def __del__(self):
        if self.context:
            lib.close_device(self.context)


    def get_frame(self, quality=95):
        buffer_size = self.width * self.height * 3  # Assuming 3 bytes per pixel (RGB) and jpg should be lesser
        jpeg_buffer = ctypes.create_string_buffer(buffer_size)
        jpeg_buffer_ptr = ctypes.cast(jpeg_buffer, ctypes.POINTER(ctypes.c_ubyte))
        bytes_written = lib.get_frame(self.context, jpeg_buffer_ptr, buffer_size, quality)
        if bytes_written == 0:
            raise RuntimeError("Failed to get frame")
        return bytes(jpeg_buffer[:bytes_written])


class AsyncCamera(Camera):

    def __init__(self, device, width=640, height=480, init_quality=95):
        super().__init__(device, width=640, height=480)
        lib.start_thread(self.context, init_quality)


    def frame_available(self):
        return bool(lib.thread_frame_available(self.context))


    def get_frame(self, quality=95):
        lib.set_thread_quality(self.context, quality)
        buffer_size = self.width * self.height * 3  # Assuming 3 bytes per pixel (RGB) and jpg should be lesser
        jpeg_buffer = ctypes.create_string_buffer(buffer_size)
        jpeg_buffer_ptr = ctypes.cast(jpeg_buffer, ctypes.POINTER(ctypes.c_ubyte))
        bytes_written = lib.get_thread_frame(self.context, jpeg_buffer_ptr, buffer_size, quality)
        if bytes_written == 0:
            raise RuntimeError("Failed to get frame")
        return bytes(jpeg_buffer[:bytes_written])


if __name__ == "__main__":
    camera = Camera("/dev/video0", 1280, 720)
    with open("test.mjpeg", "wb") as f:
        for i in range(100):
            f.write(camera.get_frame(70))
