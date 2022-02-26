;; Input file for Ypsilon DocMaker 0.9
;; Ypsilon API Reference (c) 2009 Y.FUJITA / LittleWing Co.Ltd.

(:api
  (:library (ypsilon socket))
  (:exports
    make-client-socket
    make-server-socket
    socket?
    socket-port
    call-with-socket
    shutdown-output-port
    socket-accept
    socket-send
    socket-recv
    socket-shutdown
    socket-close
    AF_UNSPEC
    AF_INET
    AF_INET6
    SOCK_STREAM
    SOCK_DGRAM
    SOCK_RAW
    AI_ADDRCONFIG
    AI_ALL
    AI_CANONNAME
    AI_NUMERICHOST
    AI_NUMERICSERV
    AI_PASSIVE
    AI_V4MAPPED
    IPPROTO_TCP
    IPPROTO_UDP
    IPPROTO_RAW
    SHUT_RD
    SHUT_WR
    SHUT_RDWR
    MSG_OOB
    MSG_PEEK
    MSG_DONTROUTE
    MSG_CTRUNC
    MSG_PROBE
    MSG_TRUNC
    MSG_DONTWAIT
    MSG_EOR
    MSG_WAITALL
    MSG_FIN
    MSG_SYN
    MSG_CONFIRM
    MSG_RST
    MSG_ERRQUEUE
    MSG_NOSIGNAL
    MSG_MORE
    MSG_EOF)
  (:abstract
    "This library provides an Internet socket interface.")
  (:link-list))
(:api
  (:procedure make-client-socket "<client-socket>")
  (:abstract
    "make-client-socket returns a client socket connected to an Internet address.")
  (:arguments
    (node <string>)
    (service <string>)
    :optional
    (ai-family <int> "(default: AF_INET)")
    (ai-socktype <int> "(default: SOCK_STREAM)")
    (ai-flags <int> "(default: AI_V4MAPPED + AI_ADDRCONFIG)")
    (ai-protocol <int> "(default: 0)"))
  ;;http://www.rfc-editor.org/rfc/rfc3493.txt
  (:indent
    (:definition :arguments #f
      (node)
      "—a network address. (examples: \"www.w3.org\", \"localhost\", \"128.30.52.45\")"
      (service)
      "—a network ~service. (examples: \"http\", \"ssh\", \"80\", \"22\")"
      (ai-family)
      "—an address family specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (AF_INET)
          (AF_INET6)
          (AF_UNSPEC)))
      (ai-socktype)
      "—a socket type specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (SOCK_STREAM)
          (SOCK_DGRAM)
          (SOCK_RAW)))
      (ai-flags)
      "—an additional options specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (AI_ADDRCONFIG)
          (AI_ALL)
          (AI_CANONNAME)
          (AI_NUMERICHOST)
          (AI_NUMERICSERV)
          (AI_PASSIVE)
          (AI_V4MAPPED)))
      (ai-protocol)
      "—a protocol specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (IPPROTO_TCP IPPROTO_UDP IPPROTO_RAW)))))
  (:description #t
    "The Internet address is identified by node and service. make-client-socket uses getaddrinfo(3) to look up it. \
     The arguments node, service, ai-family, ai-socktype, ai-flags, and ai-protocol will be passed to getaddrinfo(3) \
     as a correspondent parameter. \
     Refer to getaddrinfo(3) manual page for details")
  (:example #t
    "> (import (rnrs) (ypsilon socket))"
    "> (make-client-socket \"www.w3.org\" \"http\")"
    "@#<client-socket tcp stream 128.30.52.38:80>"))
(:api
  (:procedure make-server-socket "<server-socket>")
  (:abstract
    "make-server-socket returns a server socket waiting for connections.")
  (:arguments
    (service <string>)
    (ai-family <int> "(default: AF_INET)")
    (ai-socktype <int> "(default: SOCK_STREAM)")
    (ai-protocol <int> "(default: 0)"))
  (:indent
    (:definition :arguments #f
      (service)
      "—a network ~service. (examples: \"http\", \"telnet\", \"80\", \"23\")"
      (ai-family)
      "—an address family specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (AF_INET)
          (AF_INET6)
          (AF_UNSPEC)))
      (ai-socktype)
      "—a socket type specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (SOCK_STREAM)
          (SOCK_DGRAM)
          (SOCK_RAW)))
      (ai-protocol)
      "—a protocol specifier. Predefined specifiers are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (IPPROTO_TCP IPPROTO_UDP IPPROTO_RAW))))
    (:description #t
      "The arguments service, ai-family, ai-socktype, and ai-protocol will be passed to getaddrinfo(3) \
          as a correspondent parameter to setup ~server socket. \
          Refer to getaddrinfo(3) manual page for details")
    (:example #t
      "> (import (rnrs) (ypsilon socket))"
      "> (make-server-socket \"8080\")"
      "@#<server-socket tcp stream 0.0.0.0:8080>")))

(:api
  (:procedure socket? "<boolean>")
  (:abstract
    "socket? returns #t if its argument is a socket, and otherwise returns #f.")
  (:arguments (x <object>)))

(:api
  (:procedure socket-port "<port>")
  (:abstract
    "socket-port returns a fresh binary input/output port associated with a socket.")
  (:arguments (socket "<socket>"))
  (:description #t
    "A port returned by socket-port can be used as an ordinary port."))

(:api
  (:procedure call-with-socket "<object>")
  (:abstract
    "call-with-socket calls a procedure with a socket as an argument. This procedure has an analogy to call-with-port of (rnrs io ports).")
  (:arguments (socket "<socket>") (proc <procedure>))
  (:description #t
    "If proc returns, socket is closed implicitly, and call-with-socket returns a value returned by proc."))

(:api
  (:procedure shutdown-output-port "unspecified")
  (:abstract
    "shutdown-output-port shutdowns output connection of a socket that associated with a port.")
  (:arguments (port <port>))
  (:description #f
    "The port must be associated with a socket.")
  (:example #t
    "> (import (rnrs) (ypsilon socket))"
    "> (call-with-socket"
    "    (make-client-socket \"www.w3.org\" \"http\")"
    "    (lambda (socket)"
    "      (call-with-port"
    "        (transcoded-port (socket-port socket)"
    "                         (make-transcoder (utf-8-codec)"
    "                                          (eol-style none)))"
    "        (lambda (port)"
    "          (put-string port \"GET / HTTP/1.1\\r\\n\")"
    "          (put-string port \"HOST: www.w3.org\\r\\n\")"
    "          (put-string port \"\\r\\n\")"
    "          (shutdown-output-port port)"
    "          (display (get-string-all port))))))"
    "\n"
    "@HTTP/1.1 200 OK"
    "@Date: Thu, 29 Jan 2009 11:18:38 GMT"
    "@Server: Apache/2"
    "@Content-Location: Home.html"
    "@Vary: negotiate,accept"
    "@        :"
    "@        :"))

(:api
  (:procedure socket-accept "<client-socket>")
  (:abstract
    "socket-accept wait for an incoming connection request, and returns a fresh connected client socket.")
  (:arguments (socket "<server-socket>")))

(:api
  (:procedure socket-send unspecified)
  (:abstract
    "socket-send sends a binary data block to a socket.")
  (:arguments
    (socket <socket>)
    (buffer <bytevector>)
    (flags <int>))
  (:description #t
    "socket-send uses send(2) to send data. \
     The arguments flags will be passed to send(2) as a correspondent parameter. \
     Refer to send(2) manual page for details."))

(:api
  (:procedure socket-recv <bytevector>)
  (:abstract
    "socket-recv receives a binary data block from a socket.")
  (:arguments
    (socket <socket>)
    (flags <int>))
  (:description #t
    "socket-recv uses recv(2) to receive data. \
     The arguments flags will be passed to recv(2) as a correspondent parameter. \
     Refer to recv(2) manual page for details."))

(:api
  (:procedure socket-shutdown unspecified)
  (:abstract
    "socket-shutdown shutdowns a socket.")
  (:arguments
    (socket <socket>)
    (how "SHUT_RD, SHUT_WR, or SHUT_RDWR"))
  (:description #t
    "If how is SHUT_RD, a input is shutdowned."
    "If how is SHUT_WR, an output is shutdowned."
    "If how is SHUT_RDWR, both input and output are shutdowned."))

(:api
  (:procedure socket-close unspecified)
  (:abstract
    "socket-close closes a socket.")
  (:arguments
    (socket "<socket>")))

(:api
  (:constant AF_UNSPEC
             AF_INET
             AF_INET6)
  (:abstract "Each constant is defined to an exact integer value of a correspondent C header file definition."))
(:api
  (:constant SOCK_STREAM
             SOCK_DGRAM
             SOCK_RAW)
  (:abstract "Each constant is defined to an exact integer value of a correspondent C header file definition."))
(:api
  (:constant AI_ADDRCONFIG
             AI_ALL
             AI_CANONNAME
             AI_NUMERICHOST
             AI_NUMERICSERV
             AI_PASSIVE
             AI_V4MAPPED)
  (:abstract "Each constant is defined to an exact integer value of a correspondent C header file definition."))
(:api
  (:constant IPPROTO_TCP
             IPPROTO_UDP
             IPPROTO_RAW)
  (:abstract "Each constant is defined to an exact integer value of a correspondent C header file definition."))
(:api
  (:constant SHUT_RD
             SHUT_WR
             SHUT_RDWR)
  (:abstract "Each constant is defined to an exact integer value of a correspondent C header file definition."))
(:api
  (:constant MSG_OOB
             MSG_PEEK
             MSG_DONTROUTE
             MSG_CTRUNC
             MSG_PROBE
             MSG_TRUNC
             MSG_DONTWAIT
             MSG_EOR
             MSG_WAITALL
             MSG_FIN
             MSG_SYN
             MSG_CONFIRM
             MSG_RST
             MSG_ERRQUEUE
             MSG_NOSIGNAL
             MSG_MORE
             MSG_EOF)
  (:abstract "Each constant is defined to an exact integer value of a correspondent C header file definition."))
; [end]



