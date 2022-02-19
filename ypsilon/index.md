---
layout: default
title: "(ypsilon process)"
description: "Ypsilon: R7RS/R6RS Scheme Implementation"
permalink: /ypsilon/
---

# System process invocation

#### Sample code

```scheme
(import (core) (ypsilon process))

(let ()
  (let-values (((pid stdin stdout stderr) (process "uname")))
    (format #t "stdout: ~a" (get-string-all stdout))
    (format #t "stderr: ~a~%" (get-string-all stderr))
    (format #t "exit:~a~%" (process-wait pid #f))))
```