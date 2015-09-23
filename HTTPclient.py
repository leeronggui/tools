#/usr/bin/env pyton3

import http.client
from contextlib import closing

class HTTPclient():
#    def __init__(self, server, port=80):
#        self.server = server
#        self.port = port
#        print(self.port)
    def get(self, server, port, location):
        self.server = server
        self.port = port
        self.location = location
        with closing(http.client.HTTPConnection(server, port=port)) as conn:
            conn.request('GET',self.location)
            res = conn.getresponse().readlines()
            type(res)
            return(res)


if __name__ == '__main__':
    hc = HTTPclient()
    res = hc.get('www.baidu.com', port=80, location='/')
    print(type(res))
    print(res)
