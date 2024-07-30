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
AUDIO_BUFFER_LATENCY = 1000 * AUDIO_BUF_SIZE // AUDIO_SAMPLE_RATE

RECORD_DEVICE_NAME = os.getenv('RECORD_DEVICE_NAME', 'plughw:CARD=Device_1')
PLAY_DEVICE_NAME = os.getenv('PLAY_DEVICE_NAME', 'plughw:CARD=Device')


def create_resampler(source_rate, dest_rate, max_buf_size=AUDIO_BUF_SIZE):
    k = max_buf_size / min(source_rate, dest_rate)
    index_map = np.linspace(0, k * source_rate - 0.5, round(k * dest_rate), dtype=int)    
    def resampler(buf: bytes):
        np_buf = np.frombuffer(buf, dtype=np.int8)
        dest_size = np_buf.shape[0] * dest_rate // source_rate
        return np_buf[index_map[:dest_size]]
    return resampler


class AudioStreamWebSocketHandler(WebSocket):


    def __init__(self, sock, protocols=None, extensions=None, environ=None, heartbeat_freq=None):
        super().__init__(sock, protocols, extensions, environ, heartbeat_freq)
        self.recv_buffer = IterBuffer(0)            
        self.is_closed = False


    def record_audio(self):
        while not self.is_closed:
            try:
                _, buf = self.input_stream.read()
                if sum(map(abs, buf)) >= AUDIO_BUF_SIZE:
                    self.send(buf, binary=True)
            except BrokenPipeError as err:
                self.close()                
            except Exception as err:
                log_error(err)


    def play_audio(self):
        while not self.is_closed:
            try:
                if self.recv_buffer.size > 0:
                    self.output_stream.write(bytes(self.recv_buffer.get(AUDIO_BUF_SIZE)))
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
		    periodsize=AUDIO_BUFFER_LATENCY,
            device=RECORD_DEVICE_NAME
        )

        self.output_stream = alsaaudio.PCM(
            alsaaudio.PCM_PLAYBACK, 
            alsaaudio.PCM_NORMAL,
            channels=1, 
            rate=AUDIO_SAMPLE_RATE, 
            format=alsaaudio.PCM_FORMAT_S8,
		    periodsize=AUDIO_BUFFER_LATENCY,
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


