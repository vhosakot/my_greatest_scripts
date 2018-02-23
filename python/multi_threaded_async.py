#!/usr/bin/python

from datetime import datetime
import threading 
import time


class AsyncTask(threading.Thread):
    def __init__(self, arg1, arg2, arg3, lock=None):
        threading.Thread.__init__(self)
        self.arg1 = arg1
        self.arg2 = arg2
        self.arg3 = arg3

    def run(self):
        if lock is None:
            for i in range(0, 20):
                print threading.current_thread(), self.arg1, self.arg2, self.arg3, i
                time.sleep(1)
            print "\nthread", threading.current_thread(), "ended in run() at", \
                  datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f'), "after func1() returned\n"
        else:
            with lock:
                for i in range(0, 20):
                    print threading.current_thread(), self.arg1, self.arg2, self.arg3, i
                    time.sleep(1)
                print "\nthread", threading.current_thread(), "ended in run() at", \
                      datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f'), "after func1() returned\n"


# no lock, single thread
#def func1():
#    async_task = AsyncTask("my_arg1", "my_arg2", "my_arg3")
#    async_task.start()
#    print "\nfunc1() returning...\n"
#    return


# no lock, multiple threads
#def func1():
#    for i in range(0, 5):
#        async_task = AsyncTask("my_arg1", "my_arg2", "my_arg3")
#        async_task.start()
#    print "\nfunc1() returning...\n"
#    return


# multiple threads with lock
lock = threading.Lock()
def func1():
    global lock
    for i in range(0, 5):
        async_task = AsyncTask("my_arg1", "my_arg2", "my_arg3", lock=lock)
        async_task.start()
    print "\nfunc1() returning...\n"
    return

func1()

print "\nfunc1() returned at", datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f'), "\n"

while True:
    pass
