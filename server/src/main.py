import os
import cherrypy

from tasks import Task
from logger import log_error
from video_endpoint import VideoServer
from hardware_controller import HardwareWebSocketHandler, serial_checker

from ws4py.websocket import WebSocket
from ws4py.messaging import TextMessage
from ws4py.server.cherrypyserver import WebSocketPlugin, WebSocketTool

MY_PATH = os.path.dirname(os.path.abspath(__file__)) + "/"
STATIC_PATH = MY_PATH + '../static/'


SERVER_CONFIG = {
    "/":
        {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': STATIC_PATH,
            'tools.staticdir.index': 'index.html'
        },
    "/video": {},
    # "/audio":
    #     {
    #         'tools.websocket.on': True,
    #         'tools.websocket.handler_cls': ChatWebSocketHandler
    #     },
    "/hardware":
        {
            'tools.websocket.on': True,
            'tools.websocket.handler_cls': HardwareWebSocketHandler
        },
    # '/favicon.ico': {
    #     'tools.staticfile.on': True,
    #     'tools.staticfile.filename': STATIC_PATH + "favicon.svg"
    # }
}


class Root:

    @cherrypy.expose()
    def hardware(self):
        cherrypy.log("Connected hardware controller: "+repr(cherrypy.request.ws_handler))


if __name__ == '__main__':

    WebSocketPlugin(cherrypy.engine).subscribe()
    cherrypy.tools.websocket = WebSocketTool()
    cherrypy.server.socket_host = "0.0.0.0"
    cherrypy.server.socket_port = 8080
    cherrypy.log.screen = True
    cherrypy.config.update({"server.max_request_body_size": 256*1024})
    cherrypy.tree.mount(Root(), '/', SERVER_CONFIG)
    cherrypy.tree.mount(VideoServer(), '/video', SERVER_CONFIG)

    Task(cherrypy.engine, serial_checker, period=0.035, init_delay=1).subscribe()


    cherrypy.engine.start()
    cherrypy.engine.block()





