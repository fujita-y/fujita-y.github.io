---
layout: default
title: "(ypsilon process)"
description: "Ypsilon: R7RS/R6RS Scheme Implementation"
permalink: /ypsilon/
---

# System process invocation

(**process** _command:string_ _args:string ..._)

```
(import (core) (ypsilon process))

(let ()
  (let-values (((pid stdin stdout stderr) (process "uname" "-s" "-p")))
    (format #t "stdout: ~a" (get-string-all stdout))
    (format #t "exit: ~a~%" (process-wait pid #f))))

; prints
; stdout: Linux aarch64
; exit: 0
```