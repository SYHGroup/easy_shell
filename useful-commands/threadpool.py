'''
    Threading Pool
    Usage:
        with ThreadingPool(processes=N) as pool:
            result = pool.map(lambda x: x**2, range(10))
'''

import threading

class ThreadingPool:
    def __init__(self, processes=4):
        self.__processes = processes
        self.__running = 0
        self.__pending = list()
        self.__result = list()    # List[ {'index': 0, 'args': args, 'ret': ret, 'exc': err} ]
        self.__signallock = threading.Lock()
        self.__racelock = threading.Lock()
        self.__acknowledgelock = threading.Lock()
        self.__func = None
    def __enter__(self):
        return self
    def __exit__(self, *_):
        pass
    def map(self, func, iterable):
        self.__func = func
        for index, args in enumerate(iterable):
            if not isinstance(args, (list, tuple)):
                args = (args,)
            self.__pending.append({'index': index, 'args': args, 'ret': None, 'exc': None})
        self.__start_and_wait_for_trs()
        self.__result.sort(key=lambda x: x['index'])
        return [r['exc'] if r['exc'] else r['ret'] for r in self.__result]
    def __start_and_wait_for_trs(self):
        self.__signallock.acquire()
        while self.__pending or self.__running:
            if self.__pending and self.__running < self.__processes:
                # do some tasks
                taskdict = self.__pending.pop(0)
                threading.Thread(target=self.__inside_tr, args=(taskdict,)).start()
                self.__running += 1
            else:
                self.__signallock.acquire() # block
                self.__acknowledgelock.release() # acknowledge, the thread may end now
                self.__running -= 1
    def __inside_tr(self, taskdict):
        args = taskdict.get('args')
        try:
            taskdict['ret'] = self.__func(*args)
        except Exception as err:
            taskdict['ret'] = None
            taskdict['exc'] = err
        finally:
            with self.__racelock:
                self.__result.append(taskdict)
                self.__acknowledgelock.acquire()
                self.__signallock.release() # notify the main process
                with self.__acknowledgelock: # wait for the main process to release it
                    pass
