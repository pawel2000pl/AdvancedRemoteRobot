import os
import math
import json
import pyaudio
import cherrypy
import itertools
import numpy as np

from tasks import Task
from time import sleep, time
from logger import log_error
from iter_buffer import IterBuffer
from threading import Thread, Lock
from ws4py.websocket import WebSocket
from ws4py.messaging import Message, TextMessage
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool

def get_int_env(name, default):
    try:
        return int(os.getenv(name, default))
    except ValueError:
        return default

MAX_STREAM_TIME = get_int_env('MAX_STREAM_TIME', 43200)
AUDIO_BUFFER_LATENCY = get_int_env('AUDIO_BUFFER_LATENCY', 120) / 1000
AUDIO_SAMPLE_RATE = get_int_env('AUDIO_SAMPLE_RATE', 16000)
AUDIO_BUF_SIZE = get_int_env('AUDIO_BUF_SIZE', 16384)
CHUNK_SIZE = round(AUDIO_SAMPLE_RATE * AUDIO_BUFFER_LATENCY)

COMPRESSIONS_MAPS = np.array(tuple([[1] * AUDIO_BUF_SIZE] + [[1 if j % i else 0 for j in range(AUDIO_BUF_SIZE)] for i in np.unique(np.logspace(2, 0, 64, dtype=int))[::-1]]), dtype=np.uint8)
COMPRESSIONS_SIZES = np.array(tuple(tuple(itertools.chain([0], itertools.accumulate(cmap))) for cmap in COMPRESSIONS_MAPS.astype(np.int32)), dtype=np.uint32)

class AudioThread:

    def __init__(self):
        super().__init__()
        self.audio_clients = set()
        self.last_send_time = time()
        self.true_latency = AUDIO_BUFFER_LATENCY


    def clean_old_clients(self):
        current_time = time()
        for client in list(self.audio_clients):
            if client.connectTime < current_time - MAX_STREAM_TIME:
                client.close()


    def close_all(self):
        for client in list(self.audio_clients):
            client.close()
            

    def run(self):
        if len(self.audio_clients):
            audio_clients = list(self.audio_clients)
            try:
                sleep(AUDIO_BUFFER_LATENCY)
                current_time = time()
                dt = current_time - self.last_send_time
                self.last_send_time = current_time
                self.true_latency = dt
                send_size = min(round(dt * AUDIO_SAMPLE_RATE), AUDIO_BUF_SIZE)

                buffer = np.zeros([len(audio_clients), send_size], dtype=np.int32)
                for i, client in enumerate(audio_clients):
                    client_buffer = client.get_buffer_to_send(send_size)
                    if client_buffer is not None:
                        buffer[i] = client_buffer

                if not buffer.any():
                    return
                buffer = np.sum(buffer, axis=0) - buffer
                buffer.clip(-127, 127, out=buffer)
                buffer = buffer.astype(np.int8, copy=False)
                for i, client in enumerate(audio_clients):
                    if np.sum(np.abs(buffer[i])) != 0:                        
                        client.add_buffer_to_play(buffer[i].tobytes())
            
            except (KeyboardInterrupt, SystemExit):
                for client in list(self.audio_clients):
                    client.close()
            except Exception as err:
                log_error(err)
        


AUDIO_THREAD = AudioThread()


class AudioClient:

    def __init__(self):
        self.lock = Lock()
        self.is_closed = False
        self.connectTime = time()      

        self.play_buffer = IterBuffer(0)
        self.record_buffer = IterBuffer(0)

        self.thread = Thread(target=self.playing_thread)
        self.thread.start()
        AUDIO_THREAD.audio_clients.add(self)


    def __del__(self):
        self.close()


    def add_buffer_to_play(self, data):
        if self.play_buffer.size < AUDIO_BUF_SIZE:                        
            self.play_buffer.feed(data)


    def playing_thread(self):
        while not self.is_closed:
            if self.play_buffer.size == 0:
                sleep(AUDIO_BUFFER_LATENCY)
            else:
                self.play_audio(bytes(self.play_buffer.get(CHUNK_SIZE)))


    def play_audio(self, data):
        pass


    def get_buffer_to_send(self, send_size):
        with self.lock:
            if self.record_buffer.size > 0:
                return np.fromiter(self.record_buffer.get(send_size), count=send_size, dtype=np.uint8).astype(np.int8, copy=False)        


    def feed_data(self, data):
        if self.is_closed:
            return
        dest_size = AUDIO_SAMPLE_RATE * AUDIO_THREAD.true_latency
        with self.lock:
            add_size = min(AUDIO_BUF_SIZE-self.record_buffer.size, len(data))
            compression_index = max(0, int(math.log((1+self.record_buffer.size) / dest_size, 1.618)))
            
            if add_size <= 0 or compression_index >= len(COMPRESSIONS_MAPS):
                return                    
            if add_size < len(data):
                data = itertools.islice(data, add_size)
            if compression_index > 0:
                data = itertools.compress(data, COMPRESSIONS_MAPS[compression_index])
                add_size = COMPRESSIONS_SIZES[compression_index][add_size]

            self.record_buffer.feed(data, add_size)


    def close(self):
        if self.is_closed:
            return
        self.is_closed = True
        sleep(2 * self.record_buffer.size / AUDIO_SAMPLE_RATE)
        AUDIO_THREAD.audio_clients.difference_update([self])



class AudioStreamWebSocketHandler(WebSocket, AudioClient):

    def __init__(self, sock, protocols=None, extensions=None, environ=None, heartbeat_freq=None):
        WebSocket.__init__(self, sock, protocols, extensions, environ, heartbeat_freq)
        AudioClient.__init__(self)


    def play_audio(self, data):
        try:
            self.send(data, binary=True)
        except (AttributeError, TimeoutError, BrokenPipeError):
            self.close()
        except Exception as err:
            log_error(err)


    def received_message(self, message: Message):
        try:
            data = message.data               
            self.feed_data(message.data)
        except Exception as err:
            log_error(err)


    def opened(self):                 
        self.send(TextMessage(json.dumps({"sample_rate": AUDIO_SAMPLE_RATE})))


    def closed(self, code, reason=""):
        cherrypy.log('Audio connection closed')


    def close(self, *args, **kwargs):
        WebSocket.close(self, *args, **kwargs)
        AudioClient.close(self)


HARDWARE_CLIENT_ENABLED = False


class AudioHardwareClient(AudioClient):

    def __init__(self):
        AudioClient.__init__(self)
        global HARDWARE_CLIENT_ENABLED
        HARDWARE_CLIENT_ENABLED = True

        self.pyaudio = pyaudio.PyAudio()

        self.input_stream = self.pyaudio.open(format=pyaudio.paInt8,
                            channels=1,
                            rate=AUDIO_SAMPLE_RATE,
                            input=True,
                            frames_per_buffer=CHUNK_SIZE)

        self.output_stream = self.pyaudio.open(format=pyaudio.paInt8,
                            channels=1,
                            rate=AUDIO_SAMPLE_RATE,
                            output=True,
                            frames_per_buffer=CHUNK_SIZE)

        self.record_thread = Thread(target=self.record_audio, args=(self, self.input_stream, frames))        
        self.record_thread.start()



    def close(self):
        global HARDWARE_CLIENT_ENABLED
        HARDWARE_CLIENT_ENABLED = False
        super().close()
        try:
            self.record_thread.join()
            self.input_stream.stop_stream()
            self.input_stream.close()
            self.output_stream.stop_stream()
            self.output_stream.close()
            self.pyaudio.terminate()
        except AttributeError:
            pass


    def record_audio(self):
        while not self.is_closed:
            self.feed_data(self.input_stream.read(self.CHUNK_SIZE) )


    def play_audio(self, data):
        self.output_stream.write(data)



class AudioRoot():

    @cherrypy.expose('/audio')
    def audio(self):
        cherrypy.log("Connected audio_controller")
        if not HARDWARE_CLIENT_ENABLED:
            AudioHardwareClient()



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

    Task(cherrypy.engine, lambda: AUDIO_THREAD.run(), period=AUDIO_BUFFER_LATENCY/1000, init_delay=1).subscribe()
    Task(cherrypy.engine, lambda: AUDIO_THREAD.clean_old_clients(), period=3600, init_delay=600, before_close=AUDIO_THREAD.close_all).subscribe()

    cherrypy.engine.start()
    cherrypy.engine.block()

