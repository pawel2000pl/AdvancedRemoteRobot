import json
import cherrypy

from time import sleep
from serial import Serial
from logger import log_error
from threading import Timer
from ws4py.websocket import WebSocket
from configuration import configuration
from ws4py.messaging import Message, TextMessage


AUTHENTICATED_SOCKETS = set()
SERIAL = Serial(configuration['serial'], 115200)


def send_data(addr, value):
    value = int(value)
    buf = [
        int(addr) & 255,
        value & 255,
        (value // 256) & 255,
        (((int(addr) & 255) + 1) * (value + 1)) & 255
    ]
    SERIAL.write(bytes(buf))


def serial_checker():
    sockets = list(AUTHENTICATED_SOCKETS)
    error = False
    while SERIAL.in_waiting >= 4:
        buf = list(map(int, SERIAL.read(4)))
        data = {
            'addr': buf[0],
            'value': buf[1] + buf[2] * 256
        }
        if (data['addr']+1) * (abs(data['value'])+1) % 256 != buf[3]:
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

    # sprawdzenie wystąienia błędu transmisji w postaci zaniknięcie bajtu
    if error and (SERIAL.in_waiting % 4 != 0) and (sleep(0.01) or SERIAL.in_waiting % 4 != 0):
        SERIAL.reset_input_buffer()

    # ping
    send_data(0, 0x7FFF)



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
            if content['action'] == 'authentication':
                if content['token'] == configuration['token']:
                    self.authenticated = True
                    self.send(TextMessage(json.dumps({'status': 'ok'})))
                    AUTHENTICATED_SOCKETS.add(self)
                    cherrypy.log('Authentication ok')

            if not self.authenticated:
                return

            if content['action'] == 'set':
                send_data(content['addr'], content['value'])


        except Exception as err:
            log_error(err)



    def closed(self, code, reason=""):
        try:
            AUTHENTICATED_SOCKETS.difference_update({self})
        except Exception as err:
            log_error(err)
