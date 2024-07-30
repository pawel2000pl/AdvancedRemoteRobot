import itertools

from threading import Lock

class IterBuffer:

    def __init__(self, default=None):
        self.lock = Lock()
        self.size = 0
        self.buffers = [[]]
        self.default = default


    def feed(self, data, size=None):
        with self.lock:
            self.buffers.append(data)
            self.size += len(data) if size is None else size


    def get_size(self):
        return self.size


    def __create_single_iterator(self):
        return itertools.chain.from_iterable(self.buffers) if len(self.buffers) > 1 else self.buffers[0]


    def __get_rest(self, size):
        self.size = max(0, self.size - size)
        buffer_iter = self.__create_single_iterator()
        self.buffers = [buffer_iter]
        return itertools.islice(buffer_iter, size)


    def __get_with_default(self, size):
        if size > self.size:
            self.size = 0
            return itertools.chain(self.__create_single_iterator(), itertools.repeat(self.default, size - self.size))            
        return self.__get_rest(size)
        

    def get_all(self):
        self.buffers = [[]]
        return self.__create_single_iterator()


    def get(self, size=None):
        with self.lock:
            if size is None:
                return self.__get_all()
            elif self.default is None:
                return self.__get_rest(size)
            else:
                return self.__get_with_default(size)
