---
layout: default
title: "(ypsilon socket)"
description: "Ypsilon: R7RS/R6RS Scheme Implementation"
permalink: /ypsilon-api/socket
---
# (ypsilon socket) — Socket interface

##### `(make-client-socket <node> <service> [<ai-family> <ai-socktype> <ai-flags> <ai-protocol>])` &nbsp; procedure

- Returns a client socket connected to an Internet address.
- `<node>` is a network address --- *(ex. "www.w3.org", "localhost", "127.0.0.1")*.
- `<service>` is a network service --- *(ex. "http", "ssh", "8080")*.
- `<ai-family>` is an address family specifier either `AF_INET` `AF_INET6` `AF_UNSPEC`, default is `AF_INET`.
- `<ai-socktype>` is a socket type specifier either `SOCK_STREAM` `SOCK_DGRAM` `SOCK_RAW`, default is `SOCK_STREAM`.
- `<ai-flags>` is an additional options specifier combination of `AI_ADDRCONFIG` `AI_ALL` `AI_CANONNAME` `AI_NUMERICHOST` `AI_NUMERICSERV` `AI_PASSIVE` `AI_V4MAPPED`, default is `AI_V4MAPPED + AI_ADDRCONFIG`.
- `<ai-protocol>` is a protocol specifier either `IPPROTO_IP` `IPPROTO_TCP` `IPPROTO_UDP` `IPPROTO_RAW`, default is `IPPROTO_IP`.
<br /><br />
```lisp
(import (rnrs) (ypsilon socket))
(make-client-socket "www.w3.org" "http") ;=> #<client-socket tcp stream 128.30.52.100:80>
```
> The Internet address is identified by node and service. make-client-socket uses getaddrinfo(3) to look up it. The arguments node, service, ai-family, ai-socktype, ai-flags, and ai-protocol will be passed to getaddrinfo(3) as a correspondent parameter. Refer to getaddrinfo(3) manual page for details.

##### `(make-server-socket <service> [<ai-family> <ai-socktype> <ai-protocol>])` &nbsp; procedure

- Returns a server socket waiting for connections.
- Arguments `<service>` `<ai-family>` `<ai-socktype>` `<ai-protocol>` are same with `make-client-socket`.
<br /><br />
```lisp
(import (rnrs) (ypsilon socket))
(make-server-socket "8080") ;=> #<server-socket tcp stream 0.0.0.0:8080>")))
```

##### `(call-with-socket <socket> <procedure>)` &nbsp; procedure

- Calls `<procedure>` with `<socket>` as an argument.
- This procedure has an analogy to `call-with-port` of `(rnrs io ports)`.
- If `<procedure>` returns, socket is closed implicitly, and `call-with-socket` returns a value returned by `<procedure>`.

##### `(socket-port <socket>)` &nbsp; procedure

- Returns a fresh binary input/output port associated with a socket.
<br /><br />
```lisp
(import (rnrs) (ypsilon socket))
(call-with-socket
    (make-client-socket "www.w3.org" "http")
    (lambda (socket)
      (call-with-port
        (transcoded-port
          (socket-port socket)
          (make-transcoder (utf-8-codec) (eol-style none)))
        (lambda (port)
          (put-string port "GET / HTTP/1.1\r\n")
          (put-string port "HOST: www.w3.org\r\n")
          (put-string port "\r\n")
          (display (get-string-all port))))))
; =>
; HTTP/1.1 200 OK
; date: Sat, 26 Feb 2022 06:31:32 GMT
; content-location: Home.html
; ...
```

##### `(socket? <obj>)` &nbsp; procedure

- Returns #t if `<obj>` is a socket, and otherwise returns #f.

##### `(socket-accept <socket>)` &nbsp; procedure

- Wait for an incoming connection request, and returns a fresh connected client socket

##### `(socket-send <socket> <bytevector> <flags>)` &nbsp; procedure

- Sends a binary data block `<bytevector>` to `<socket>`.
> `socket-send` uses send(2) to send data. The arguments `<flags>` will be passed to send(2) as a correspondent parameter. Refer to send(2) manual page for details.

##### `(socket-recv <socket> <flags>)` &nbsp; procedure

- Receives a binary data block from `<socket>` and returns new bytevector contains it.
> `socket-recv` uses recv(2) to receive data. The arguments `<flags>` will be passed to recv(2) as a correspondent parameter. Refer to recv(2) manual page for details.

##### `(socket-close <socket>)` &nbsp; procedure

- Closes `<socket>`.

##### `(socket-shutdown <socket> <how>)` &nbsp; procedure

- Shutdowns `<socket>`.
- `<how>` is either `SHUT_RD` `SHUT_WR` `SHUT_RDWR`.

##### `(shutdown-output-port <port>)` &nbsp; procedure

- Flushes `<port>` output, then shutdowns output connection of a socket that associated with `<port>`.

#### Constants
```
AF_UNSPEC       SOCK_STREAM     AI_PASSIVE       IPPROTO_TCP      SHUT_RD
AF_INET         SOCK_DGRAM      AI_CANONNAME     IPPROTO_UDP      SHUT_WR
AF_INET6        SOCK_RAW        AI_NUMERICHOST   IPPROTO_RAW      SHUT_RDWR
                                AI_V4MAPPED
                                AI_ALL
                                AI_ADDRCONFIG

MSG_OOB         MSG_PROBE       MSG_WAITALL       MSG_RST         MSG_EOF
MSG_PEEK        MSG_TRUNC       MSG_FIN           MSG_ERRQUEUE
MSG_DONTROUTE   MSG_DONTWAIT    MSG_SYN           MSG_NOSIGNAL
MSG_CTRUNC      MSG_EOR         MSG_CONFIRM       MSG_MORE
```
