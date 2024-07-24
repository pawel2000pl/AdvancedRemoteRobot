import os
import cherrypy


MY_PATH = os.path.dirname(os.path.abspath(__file__)) + "/"
STATIC_PATH = MY_PATH + '../static/'

SERVER_CONFIG = {
    "/":
        {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': STATIC_PATH,
            'tools.staticdir.index': 'index.html',
        },
    # '/favicon.ico': {
    #     'tools.staticfile.on': True,
    #     'tools.staticfile.filename': STATIC_PATH + "favicon.svg"
    # },
}

class Root:
    pass


if __name__ == '__main__':

    cherrypy.server.socket_host = "127.0.0.1"
    cherrypy.server.socket_port = 8080
    cherrypy.log.screen = True
    cherrypy.config.update({"server.max_request_body_size": 256*1024})
    cherrypy.tree.mount(Root(), '/', SERVER_CONFIG)

    cherrypy.engine.start()
    cherrypy.engine.block()


