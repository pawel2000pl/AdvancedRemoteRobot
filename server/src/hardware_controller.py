import json
import cherrypy

from time import sleep
from tasks import Task
from serial import Serial
from logger import log_error
from threading import Timer
from ws4py.websocket import WebSocket
from configuration import configuration
from ws4py.messaging import Message, TextMessage
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool

HELLO_VALUE = 185
AUTHENTICATED_SOCKETS = set()
SERIAL = Serial(configuration['serial'], 115200)


def send_data(addr, value):
    value = int(value)
    buf = [
        HELLO_VALUE,
        int(addr) & 255,
        value & 255,
        (value >> 8) & 255,
        (((int(addr) & 255) + 1) * (abs(value) + 1)) & 255
    ]
    SERIAL.write(bytes(buf))


def serial_checker():
    sockets = list(AUTHENTICATED_SOCKETS)
    error = False
    while SERIAL.in_waiting >= 5:
        SERIAL.read_until(bytes([HELLO_VALUE]))
        buf = list(map(int, SERIAL.read(4)))
        data = {
            'addr': buf[0],
            'value': buf[1] + buf[2] * 256
        }
        if ((data['addr']+1) * (abs(data['value'])+1) & 255) != buf[3]:
            error = True
            continue # błąd transmisji

        data_str = json.dumps(data)
        for socket in sockets:
            try:
                socket.send(TextMessage(data_str))
            except Exception as err:
                log_error(err)
                try:
                    AUTHENTICATED_SOCKETS.difference_update({socket})
                    socket.close()
                except Exception as _:
                    pass

    # ping
    # send_data(0, 0x7FFF)



class HardwareWebSocketHandler(WebSocket):


    def __init__(self, sock, protocols=None, extensions=None, environ=None, heartbeat_freq=None):
        super().__init__(sock, protocols, extensions, environ, heartbeat_freq)
        Timer(3, self.authentication_timeout).start()
        self.authenticated = False


    def authentication_timeout(self):
        if not self.authenticated:
            self.close()


    def received_message(self, message: Message):
        content = json.loads(message.data.decode(message.encoding))

        try:
            if not self.authenticated and content['action'] == 'authentication':
                if content['token'] == configuration['token']:
                    self.authenticated = True
                    self.send(TextMessage(json.dumps({'status': 'ok'})))
                    AUTHENTICATED_SOCKETS.add(self)
                    cherrypy.log('Authentication ok')

            if not self.authenticated:
                return

            if content['action'] == 'set':
                if 'data' in content:
                    for field in content['data']:
                        send_data(field['addr'], field['value'])
                else:
                    send_data(content['addr'], content['value'])


        except Exception as err:
            log_error(err)


    def closed(self, code, reason=""):
        try:
            AUTHENTICATED_SOCKETS.difference_update({self})
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

