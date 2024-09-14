import json
import cherrypy

from time import sleep
from tasks import Task
from serial import Serial
from threading import Timer
from logger import log_error
from ws4py.websocket import WebSocket
from configuration import configuration
from ws4py.messaging import Message
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool

HELLO_VALUE = 185
SOCKETS = set()
SERIAL = Serial(configuration['serial'], 115200)



def makeSigned16(x):
    return x if x <= 0x7F else x - 0x100


def create_checksum(addr, value):
    return ((addr + 1) * ((value & 0xFFFF) + 1)) & 255


def check_packet(buf: bytes):
    return len(buf) >= 5 and buf[0] == HELLO_VALUE and create_checksum(buf[1], buf[2] | (buf[3] << 8)) == buf[4]


def send_data(addr, value):
    value = int(value)
    buf = [
        HELLO_VALUE,
        int(addr) & 255,
        value & 255,
        (value >> 8) & 255,
        create_checksum(addr, value)
    ]
    SERIAL.write(bytes(buf))


def serial_checker():
    sockets = list(SOCKETS)
    error = False
    send_buf = []
    i = 0
    while SERIAL.in_waiting >= 5:
        i += 1
        SERIAL.read_until(bytes([HELLO_VALUE]))
        buf = bytes(map(int, SERIAL.read(4)))
        if not check_packet(bytes([HELLO_VALUE]) + buf):
            error = True
            continue # błąd transmisji
        send_buf.append(buf[:3])

        if len(send_buf) > 0 and (i % 16 == 0 or SERIAL.in_waiting < 4):
            for socket in sockets:
                try:
                    socket.send(bytes().join(send_buf), binary=True)
                except AttributeError as err:
                    pass # known issue
                except Exception as err:
                    log_error(err)
                    try:
                        SOCKETS.difference_update({socket})
                        socket.close()
                    except Exception as _:
                        pass


class HardwareWebSocketHandler(WebSocket):


    def __init__(self, sock, protocols=None, extensions=None, environ=None, heartbeat_freq=None):
        super().__init__(sock, protocols, extensions, environ, heartbeat_freq)
        SOCKETS.add(self)


    def received_message(self, message: Message):
        for i in range(len(message.data)//3):
            if (i+1) % 50 == 0: sleep(0.02) # avoid buffer overflow
            buf = message.data[3*i:3*(i+1)]
            addr = buf[0]
            value = buf[1] + (buf[2] << 8)
            try:
                send_data(addr, value)
            except Exception as err:
                log_error(err)


    def closed(self, code, reason=""):
        try:
            SOCKETS.difference_update({self})
        except Exception as err:
            log_error(err)



class HardwareRoot():

    @cherrypy.expose('/hardware')
    def hardware(self):
        cherrypy.log("Connected hardware controller: "+repr(cherrypy.request.ws_handler))



if __name__ == '__main__':
    CONFIG = {
        "/hardware":
        {
            'tools.websocket.on': True,
            'tools.websocket.handler_cls': HardwareWebSocketHandler
        }
    }

    WebSocketPlugin(cherrypy.engine).subscribe()
    cherrypy.tools.websocket = WebSocketTool()
    cherrypy.log.screen = True
    cherrypy.config.update({"server.max_request_body_size": 256*1024})
    cherrypy.config.update({
        'server.socket_host': '127.0.0.1',
        'server.socket_port': 8082
    })
    cherrypy.tree.mount(HardwareRoot(), '/', CONFIG)

    Task(cherrypy.engine, serial_checker, period=0.035, init_delay=1).subscribe()

    cherrypy.engine.start()
    cherrypy.engine.block()
