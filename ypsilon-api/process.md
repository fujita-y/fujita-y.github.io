---
layout: default
title: "(ypsilon process)"
description: "Ypsilon: R7RS/R6RS Scheme Implementation"
permalink: /ypsilon-api/process
---
# (ypsilon process) — Posix process interface

##### `(process <name> <args> ...)` &nbsp; procedure

- Runs a child process and returns `pid` and new textual ports `stdin`, `stdout`, `stderr` opened for the child process.
<br /><br />
```lisp
  (import (rnrs) (ypsilon process) (only (core) format))
  (call-with-values
    (lambda ()
      (process "grep" "-oE" "([a-z]+)" "-"))
    (lambda (pid stdin stdout stderr)
      (write "1234 hoge 5678" stdin)
      (close-port stdin)
      (format #t "stdout: ~a" (get-string-all stdout))
      (format #t "stderr: ~a~%" (get-string-all stderr))
      (format #t "exit:~a~%" (process-wait pid #f))))
  ; stdout: hoge
  ; stderr: #<eof>
  ; exit:0
```

##### `(process-wait <pid> <nohang>)` &nbsp; procedure

- Waits for the child process specified by `<pid>` to terminate, then returns its exit status.
- Returns #f immediately if `<nohang>` is #t and the child process has not terminated.

##### `(process-spawn <search> <env> <stdin> <stdout> <stderr> <name> <args> ...)` &nbsp; procedure

- Runs a child process and returns `pid` and new binary ports `stdin`, `stdout`, `stderr` if the port is not specified in `<stdin>` `<stdout>` `<stderr>`.
- If `<search>` is #t, `<name>` is treated as a filename and the process image is searched using the environment variable PATH. Otherwise name is treated as a pathname.
- `<env>` is an association list of child process environment.
- `<stdin>` `<stdout>` `<stderr>` can be either #f, port, or socket --- specifying #f creates and assigns a new binary port.
<br /><br />
```lisp
  (import (rnrs) (ypsilon process) (only (core) format destructuring-bind))
  (system "echo '1234 hoge 5678' > /tmp/temp-ypsilon-input")
  (system "rm /tmp/temp-ypsilon-output")
  (call-with-input-file
    "/tmp/temp-ypsilon-input"
    (lambda (in)
      (call-with-output-file
        "/tmp/temp-ypsilon-output"
        (lambda (out)
          (destructuring-bind (pid _ _ stderr)
              (process-spawn #t #f in out #f "grep" "-oE" "([a-z]+)" "-")
            (format #t "exit:~a~%" (process-wait pid #f))
            (system "cat /tmp/temp-ypsilon-output")
            (format #t "stderr: ~a~%" (get-string-all (transcoded-port stderr (native-transcoder)))))))))
  ; exit:0
  ; hoge
  ; stderr: #<eof>
```

##### `(process-shell-command <command>)` &nbsp; procedure

- Runs `<command>` in the shell.
- Returns `pid` and ports `stdin`, `stdout`, `stderr` opened for the shell process.
<br /><br />
```lisp
  (import (rnrs) (ypsilon process) (only (core) format))
  (call-with-values
    (lambda ()
      (process-shell-command "pwd"))
    (lambda (pid stdin stdout stderr)
      (format #t "stdout: ~a" (get-string-all stdout))
      (format #t "exit:~a~%" (process-wait pid #f))))
  ; stdout: /home/digamma/github/ypsilon
  ; exit:0
```

##### `(system <command>)` &nbsp; procedure

- Runs `<command>` in the shell.
- Returns an exit status after `<command>` is complete.
<br /><br />
```lisp
  (import (rnrs) (ypsilon process))
  (system "uname -svr") ;=> 0
  ; Linux 5.13.0-30-generic #33-Ubuntu SMP Fri Feb 4 17:05:14 UTC 2022
```

