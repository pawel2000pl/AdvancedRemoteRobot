import os
import math
import json
import cherrypy
import itertools
import numpy as np

from tasks import Task
from time import sleep, time
from logger import log_error
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
AUDIO_MAX_CONNECTIONS = get_int_env('AUDIO_MAX_CONNECTIONS', 64)


COMPRESSIONS_MAPS = np.array(tuple([[1] * AUDIO_BUF_SIZE] + [[1 if j % i else 0 for j in range(AUDIO_BUF_SIZE)] for i in np.unique(np.logspace(2, 0, 64, dtype=int))[::-1]]), dtype=np.uint8)
COMPRESSIONS_SIZES = np.array(tuple(tuple(itertools.chain([0], itertools.accumulate(cmap))) for cmap in COMPRESSIONS_MAPS.astype(np.int32)), dtype=np.uint32)

class AudioThread:

    def __init__(self):
        super().__init__()
        self.connections = set()
        self.last_send_time = time()
        self.true_latency = AUDIO_BUFFER_LATENCY


    def clean_old_connections(self):
        current_time = time()
        for connection in list(self.connections):
            if connection.connectTime < current_time - MAX_STREAM_TIME:
                connection.close()


    def run(self):
        if len(self.connections):
            connections = list(self.connections)
            try:
                sleep(AUDIO_BUFFER_LATENCY)
                current_time = time()
                dt = current_time - self.last_send_time
                self.last_send_time = current_time
                self.true_latency = dt
                send_size = min(round(dt * AUDIO_SAMPLE_RATE), AUDIO_BUF_SIZE)

                buffer = np.zeros([len(connections), send_size], dtype=np.int32)
                for i, connection in enumerate(connections):
                    connection_buffer = connection.get_buffer_to_send(send_size)
                    if connection_buffer is not None:
                        buffer[i] = connection_buffer

                if not buffer.any():
                    return
                buffer = np.sum(buffer, axis=0) - buffer
                buffer.clip(-127, 127, out=buffer)
                buffer = buffer.astype(np.int8, copy=False)
                for i, connection in enumerate(connections):
                    if len(connection.buffers_to_send) < 5 and np.sum(np.abs(buffer[i])) != 0:                        
                        connection.buffers_to_send.append(buffer[i].tobytes())
            
            except (KeyboardInterrupt, SystemExit):
                for connection in list(self.connections):
                    connection.close()
            except Exception as err:
                log_error(err)
        


AUDIO_THREAD = AudioThread()


class AudioStreamWebSocketHandler(WebSocket):

    def __init__(self, sock, protocols=None, extensions=None, environ=None, heartbeat_freq=None):
        super().__init__(sock, protocols, extensions, environ, heartbeat_freq)
        self.lock = Lock()
        self.recv_buffers = []
        self.buffer_length = 0
        self.is_closed = False
        self.buffers_to_send = []
        self.connectTime = time()
        self.thread = Thread(target=self.sending_thread)
        self.thread.start()


    def sending_thread(self):
        while not self.is_closed:
            if len(self.buffers_to_send) == 0:
                sleep(AUDIO_BUFFER_LATENCY)
            else:
                try:
                    buf = self.buffers_to_send.pop(0)
                    self.send(buf, binary=True)        
                except (KeyboardInterrupt, SystemExit):
                    break
                except (AttributeError, TimeoutError):
                    self.close()
                    break
                except BrokenPipeError:
                    AUDIO_THREAD.connections = set()
                    break
                except Exception as err:
                    log_error(err)


    def opened(self):                 
        AUDIO_THREAD.connections.add(self)
        self.send(TextMessage(json.dumps({"sample_rate": AUDIO_SAMPLE_RATE})))


    def received_message(self, message: Message):
        try:
            data = message.data               
            dest_size = AUDIO_SAMPLE_RATE * AUDIO_THREAD.true_latency
            with self.lock:
                add_size = min(AUDIO_BUF_SIZE-self.buffer_length, len(data))
                compression_index = max(0, int(math.log((1+self.buffer_length) / dest_size, 1.618)))
                
                if add_size <= 0 or compression_index >= len(COMPRESSIONS_MAPS):
                    return                    
                if add_size < len(data):
                    data = itertools.islice(data, add_size)
                if compression_index > 0:
                    data = itertools.compress(data, COMPRESSIONS_MAPS[compression_index])
                    add_size = COMPRESSIONS_SIZES[compression_index][add_size]

                self.recv_buffers.append(data)
                self.buffer_length += add_size
                                       

        except Exception as err:
            log_error(err)


    def get_buffer_to_send(self, send_size):
        with self.lock:
            if send_size > self.buffer_length:
                return None
            self.buffer_length -= send_size
            buffer_iter = itertools.chain.from_iterable(self.recv_buffers) if len(self.recv_buffers) > 1 else self.recv_buffers[0]
            self.recv_buffers = [buffer_iter]
            return np.fromiter(buffer_iter, count=send_size, dtype=np.uint8).astype(np.int8, copy=False)        
        

    def closed(self, code, reason=""):
        cherrypy.log('Audio connection %s closed')
        self.is_closed = True
        with self.lock:
            self.buffer_length += NOTIFICATION_LENGTH
            self.recv_buffers.append(LEAVE_NOTIFICATION())
        sleep(2 * self.buffer_length / AUDIO_SAMPLE_RATE)
        AUDIO_THREAD.connections.difference_update([self])



class AudioRoot():

    @cherrypy.expose('/audio')
    def audio(self):
        cherrypy.log("Connected hardware controller: "+repr(cherrypy.request.ws_handler))




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
    Task(cherrypy.engine, lambda: AUDIO_THREAD.clean_old_connections(), period=3600, init_delay=600).subscribe()

    cherrypy.engine.start()
    cherrypy.engine.block()

