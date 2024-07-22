import cherrypy
import traceback


def log_error(error):
    if isinstance(error, Exception):
        return log_error(str(error) + "\n\n" + str().join(traceback.TracebackException.from_exception(error).format()))
    global DB_COMMANDS
    error = str(error)
    cherrypy.log(error)
