import os
import cherrypy

from threading import Thread
from time import time, sleep
from cameralib import AsyncCamera


def find_video_device():
    i = 0
    while not os.path.exist('/dev/video%d'%i):
        i += 1
    return '/dev/video%d'%i


class VideoServer:

    def __init__(self, device='/dev/video0', size=(640,480)):
        self.device = device
        self.size = size


    @cherrypy.expose
    def index(self):
        return '<img src="./stream"/>'


    @cherrypy.expose
    def stream(self):
        cherrypy.response.headers['Content-Type'] = 'multipart/x-mixed-replace; boundary=frame'
        return self.generate()
    stream._cp_config = {'response.stream': True}


    def generate(self):
        camera = AsyncCamera(self.device, *self.size)
        while True:
            while not camera.frame_available():
                sleep(1/100)   
            yield b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + camera.get_frame()  + b'\r\n'


if __name__ == '__main__':
    cherrypy.config.update({
        'server.socket_host': '0.0.0.0',
        'server.socket_port': 8080
    })
    cherrypy.quickstart(VideoServer())
