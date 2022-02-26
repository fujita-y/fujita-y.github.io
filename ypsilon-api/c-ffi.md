---
layout: default
title: "(ypsilon c-ffi)"
description: "Ypsilon: R7RS/R6RS Scheme Implementation"
permalink: /ypsilon-api/c-ffi
---
# (ypsilon c-ffi) — C foreign function interface

##### `(c-function <ret> <name> (<args> ...))` &nbsp; syntax<br />`(c-function <ret> <name> (<args> ...) (<varargs> ...))` &nbsp; syntax

- Generates a C callout function procedure.
- `<name>` is a C function name.
- `<ret>`, `<args>`, and `<varargs>` are C data types.
- `<varargs>` are for variadic functions.
- Valid C data types are `void` `bool` `char` `short` `int` `long` `long-long` `unsigned-short` `unsigned-int` `unsigned-long` `unsigned-long-long` `int8_t` `int16_t` `int32_t` `int64_t` `uint8_t` `uint16_t` `uint32_t` `uint64_t` `float` `double` `size_t` `void*`.
- C function refernce is resolved during form evaluation.
<br /><br />
```lisp
(import (rnrs) (ypsilon c-ffi) (ypsilon c-types))
(define strcmp (c-function int strcmp (void* void*)))
(strcmp (make-c-string "foo") (make-c-string "bar")) ;=> 129
(define snprintf (c-function int snprintf (void* size_t void*) (long double)))
(define buf (make-bytevector 128 0))
(define n (snprintf buf 128 (make-c-string "%06lu %.3lf") 246 123.4))
(c-string-ref buf) ;=> "000246 123.400"
n ;=> 14
```

##### `(c-function/weak <ret> <name> (<args> ...))` &nbsp; syntax<br />`(c-function/weak <ret> <name> (<args> ...) (<varargs> ...))` &nbsp; syntax

- Unlike `c-function`, this variant defer resolving C function reference until first call.

##### `(c-callback <ret> (<args> ...) <procedure>)` &nbsp; syntax

- Generates a C callback function procedure.
- `<ret>` and `<args>` are C data types.
- Valid C data types are same with `c-function`.
<br /><br />
```lisp
(import (rnrs) (ypsilon c-ffi) (ypsilon c-types))
(define comparison (c-callback int (void* void*)
    (lambda (a1 a2)
      (let ((n1 (bytevector-c-uint32-ref (make-bytevector-mapping a1 4) 0))
            (n2 (bytevector-c-uint32-ref (make-bytevector-mapping a2 4) 0)))
        (cond ((= n1 n2) 0) ((< n1 n2) 1) (else -1))))))
(define qsort (c-function void qsort (void* int int void*)))
(define nums (uint-list->bytevector '(10000 1000 10 100000 100) (native-endianness) 4))
(qsort nums 5 4 comparison)
(bytevector->uint-list nums (native-endianness) 4)
;=> (100000 10000 1000 100 10))
```

#####  `(load-shared-object)` &nbsp; procedure<br />`(load-shared-object "<filename>")` &nbsp; procedure

- Loads the dynamic shared object named by `<filename>` and returns the handle for the loaded object. If `<filename>` is not specified, it returns the handle for the main program.
<br /><br />
```lisp
(import (ypsilon c-ffi))
(load-shared-object "libglfw.so.3")
```

##### `(c-main-argc)` &nbsp; procedure

- Returns the value passed to argc in ```main(int argc, char *argv[])```.

##### `(c-main-argv)` &nbsp; procedure

- Returns the address passed to argv in ```main(int argc, char *argv[])```.
