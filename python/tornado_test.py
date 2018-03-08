#!/usr/bin/env python

# Tornado is an asynchronous web server. This is a pattern for the front-end.
# It allows us to run a single thread for the front-end instead of having many
# blocking.
#
# When the code starts up, it will add an HTTP Request Handler on the /file/ API.
# This will trigger the appropriate call in the FileHandler class when a client
# (like curl) makes a request like http://localhost:5001/file/. The get handler
# picks a random number, call it the transaction id and stores the callback
# function into a transaction database.
#
# At the same time (on the same thread, but interleaved as separate events), the
# half_second_loop() function is scheduling events every .5 seconds. This thread
# generates a random number which matches one of the transaction ids, simulating
# a delay in receiving a response from a RabbitMQ consume() call. If we generate
# a matching transaction ID, we look up the function in the dictionary and call
# the callback function. The callback function will send the response back to the
# client.
#
import tornado
import tornado.log
import tornado.options
from tornado import gen
from tornado.web import asynchronous
from tornado.ioloop import IOLoop
import uuid
import random


log = tornado.log.app_log.getChild(__name__)

connection_db = dict()

class FileHandler(tornado.web.RequestHandler):
    @asynchronous
    def get(self):
        log.info("got request: %s" % (self.request.uri))
        bucket = random.randrange(0,10)
        log.info("assigning to %d" % (bucket))        
        connection_db[bucket] = self.on_response

    def on_response(self, response):
        log.info("write response")
        self.write("%d tries" % (response))
        self.finish()

@gen.coroutine        
def half_second_loop():
    count = 0
    while True:
        yield gen.sleep(.5)
        bucket = random.randrange(0,10)
        log.debug("generated %d" % (bucket))
        count = count + 1
        if bucket in connection_db:
            response_func = connection_db[bucket]
            del connection_db[bucket]
            response_func(count)
            count = 0
        
    
        
settings = {
    "autoreload" : True,
    "debug": True,
    "cookie_secret": "String!4543$!@$%fgsdfg4423",
    "login_url": "/login",
    "xsrf_cookies": False,
    }

application = tornado.web.Application([
    tornado.web.URLSpec(r"/file/",
                        FileHandler,
                        name='file_handler')
    ], **settings)


if __name__ == '__main__':
    print "Starting Tornado Tester"
    tornado.options.parse_command_line()    
    application.listen(5001)
    IOLoop.current().spawn_callback(half_second_loop)
    tornado.ioloop.IOLoop.current().start()
