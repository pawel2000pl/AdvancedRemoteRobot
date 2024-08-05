import json
import cherrypy

from configuration import get_all_configuration
from registers_reader import REGISTERS_ADDRESSES, REGISTERS_LIST, READ_REGISTERS, WRITE_REGISTERS

class Root:
    
    @cherrypy.expose('/settings')
    def settings(self):
        cherrypy.response.headers['Content-Type'] = 'application/json'
        return json.dumps({
            'registers_addresses': REGISTERS_ADDRESSES,
            'registers_list': REGISTERS_LIST,
            'read_registers': READ_REGISTERS,
            'write_registers': WRITE_REGISTERS,
            'configuration': get_all_configuration()
        }).encode('utf-8')



if __name__ == '__main__':

    cherrypy.server.socket_host = "127.0.0.1"
    cherrypy.server.socket_port = 8085
    cherrypy.log.screen = True
    cherrypy.config.update({"server.max_request_body_size": 256*1024})
    cherrypy.tree.mount(Root(), '/')

    cherrypy.engine.start()
    cherrypy.engine.block()

