import json
import cherrypy

from configuration import get_configuration, set_configuration, is_token_valid, add_token, TOKEN_TIMEOUT

class Root:


    @cherrypy.expose()
    def logout(self):
        cherrypy.response.headers['Content-Type'] = 'application/json'
        cookie = cherrypy.response.cookie
        cookie['token'] = ''
        cookie['token']['max-age'] = 0
        return b'{"status": "ok"}'


    @cherrypy.expose()
    def set_password(self):
        if not self.check_access():
            return
        cherrypy.response.headers['Content-Type'] = 'application/json'
        data = json.loads(cherrypy.request.body.read().decode("utf-8"))
        set_configuration('password', data['password'])
        return b'{"status": "ok"}'


    @cherrypy.expose()
    def login(self):
        cherrypy.response.headers['Content-Type'] = 'application/json'
        data = json.loads(cherrypy.request.body.read().decode("utf-8"))
        if data['password'] == get_configuration('password', 'changeit'):
            cookie = cherrypy.response.cookie
            cookie['token'] = add_token()
            cookie['token']['max-age'] = TOKEN_TIMEOUT
            return b'{"status": "ok"}'
        else:
            cherrypy.response.status = 403
            return b'{"status": "error"}'


    def check_access(self):
        return 'token' in cherrypy.request.cookie and is_token_valid(cherrypy.request.cookie['token'].value)
    
    
    @cherrypy.expose()
    def auth(self):
        cherrypy.response.headers['Content-Type'] = 'application/json'
        if self.check_access():
            cherrypy.response.status = 200
            return b'{"status": "ok"}'
        cherrypy.response.status = 401
        return b'{"status": "error"}'


if __name__ == '__main__':

    cherrypy.server.socket_host = "0.0.0.0"
    cherrypy.server.socket_port = 8084
    cherrypy.log.screen = True
    cherrypy.config.update({"server.max_request_body_size": 256*1024})
    cherrypy.tree.mount(Root(), '/')

    cherrypy.engine.start()
    cherrypy.engine.block()
