import itertools

from threading import Lock

class IterBuffer:

    def __init__(self, default=None):
        self.lock = Lock()
        self.size = 0
        self.buffers = []
        self.default = default
        self.get = self.__get_rest if default is None else self.__get_with_default


    def feed(self, data):
        with self.lock:
            self.buffers.append(data)
            size += len(data)


    def get_size(self):
        return self.size


    def __get_rest(self, size):
        self.size = max(0, self.size - size)
        buffer_iter = itertools.chain.from_iterable(self.buffers) if len(self.buffers) > 1 else self.buffers[0]
        self.buffers = [itertools.islice(buffer_iter, size, None)]
        return itertools.islice(buffer_iter, count=size)


    def __get_with_default(self, size):
        if size > self.size:
            self.feed(itertools.repeat(self.default, self.size - size))
        return self.get_rest()
        
