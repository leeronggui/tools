#!/usr/bin/env python3
import socket

class opsocket():
    def listen(self, ip, port):
        ip = self.ip
        port = self.port
        tcpconn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        bindsocket = tcpconn((ip, port))
        bindsocket.listen(1024)

