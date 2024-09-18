import os
import json
import cherrypy
import itertools
import alsaaudio
import numpy as np

from time import sleep
from logger import log_error
from iter_buffer import IterBuffer
from threading import Thread
from ws4py.websocket import WebSocket
from ws4py.messaging import Message, TextMessage
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool


def get_int_env(name, default):
    try:
        return int(os.getenv(name, default))
    except ValueError:
        return default

MAX_STREAM_TIME = get_int_env('MAX_STREAM_TIME', 43200)
AUDIO_SAMPLE_RATE = get_int_env('AUDIO_SAMPLE_RATE', 16000)
AUDIO_BUF_SIZE = get_int_env('AUDIO_BUF_SIZE', 1024)

RECORD_DEVICE_NAME = os.getenv('RECORD_DEVICE_NAME', 'plughw:CARD=Device_1')
PLAY_DEVICE_NAME = os.getenv('PLAY_DEVICE_NAME', 'plughw:CARD=Device')


class AudioStreamWebSocketHandler(WebSocket):


    def __init__(self, sock, protocols=None, extensions=None, environ=None, heartbeat_freq=None):
        super().__init__(sock, protocols, extensions, environ, heartbeat_freq)
        self.recv_buffer = IterBuffer(0)   
        self.play_strength = 0         
        self.is_closed = False


    def record_audio(self):
        while not self.is_closed:
            try:
                _, buf = self.input_stream.read()
                if sum(map(abs, buf)) >= AUDIO_BUF_SIZE:
                    np_buffer = (np.frombuffer(buf, dtype=np.int8) *  (1 - self.play_strength/768)).astype(np.int8, copy=False)
                    self.send(np_buffer.tobytes(), binary=True)
            except BrokenPipeError as err:
                self.close()                
            except Exception as err:
                log_error(err)


    def play_audio(self):
        while not self.is_closed:
            try:
                if self.recv_buffer.size > 0:
                    np_buffer = np.fromiter(self.recv_buffer.get(AUDIO_BUF_SIZE), dtype=np.uint8).astype(np.int8, copy=False)
                    current_strength = np.max(np.abs(np_buffer)).astype(int)
                    self.play_strength = max(current_strength, (9 * self.play_strength + current_strength) / 10)
                    self.output_stream.write(np_buffer.tobytes())
                else:
                    sleep(0.001)
                    self.play_strength *= 0.99
            except Exception as err:
                log_error(err)


    def received_message(self, message: Message):
        try:
            data = message.data          
            if self.recv_buffer.size < AUDIO_BUF_SIZE:     
                self.recv_buffer.feed(message.data)
        except Exception as err:
            log_error(err)


    def opened(self):                 

        self.send(TextMessage(json.dumps({"sample_rate": AUDIO_SAMPLE_RATE})))

        self.input_stream = alsaaudio.PCM(
            alsaaudio.PCM_CAPTURE, 
            alsaaudio.PCM_NORMAL,
		    channels=1, 
            rate=AUDIO_SAMPLE_RATE, 
            format=alsaaudio.PCM_FORMAT_S8,
		    periodsize=1024,
            device=RECORD_DEVICE_NAME
        )

        self.output_stream = alsaaudio.PCM(
            alsaaudio.PCM_PLAYBACK, 
            alsaaudio.PCM_NORMAL,
            channels=1, 
            rate=AUDIO_SAMPLE_RATE, 
            format=alsaaudio.PCM_FORMAT_S8,
		    periodsize=64,
            device=PLAY_DEVICE_NAME
        )

        self.record_thread = Thread(target=self.record_audio) 
        self.play_thread = Thread(target=self.play_audio)    

        self.record_thread.daemon = True
        self.play_thread.daemon = True
        self.record_thread.start()
        self.play_thread.start()



    def closed(self, code, reason=""):
        cherrypy.log('Audio connection closed')
        self.is_closed = True
        self.record_thread.join()
        self.play_thread.join()

        self.input_stream.close()
        self.output_stream.close()



class AudioRoot():

    @cherrypy.expose('/audio')
    def audio(self):
        cherrypy.log("Connected audio_controller")


if __name__ == '__main__':
    CONFIG = {
        "/audio":
        {
            'tools.websocket.on': True,
            'tools.websocket.handler_cls': AudioStreamWebSocketHandler
        }
    }

    WebSocketPlugin(cherrypy.engine).subscribe()
    cherrypy.tools.websocket = WebSocketTool()
    cherrypy.log.screen = True
    cherrypy.config.update({"server.max_request_body_size": 256*1024})
    cherrypy.config.update({
        'server.socket_host': '127.0.0.1',
        'server.socket_port': 8083
    })
    cherrypy.tree.mount(AudioRoot(), '/', CONFIG)    

    cherrypy.engine.start()
    cherrypy.engine.block()


