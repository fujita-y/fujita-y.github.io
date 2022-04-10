---
layout: default
title: "(core)"
description: "Ypsilon: R7RS/R6RS Scheme Implementation"
permalink: /ypsilon-api/core
---
# (core) — Built-in synaxes and procedures

## Pretty printer

##### `(pretty-print <obj> [<port>])` &nbsp; procedure

- Outputs a formatted scheme object.

##### `(pretty-print-line-length <num>)` &nbsp; parameter

- Changes a preferred line length of the output.
<br /><br />
```
  > (import (core))
  > (pretty-print '(define filter (lambda (pred lst) (let loop ((lst lst)) (cond ((null? lst) (quote ())) ((pred (car lst)) (cons (car lst) (loop (cdr lst)))) (else (loop (cdr lst))))))))
  (define filter
    (lambda (pred lst)
      (let loop ((lst lst))
        (cond ((null? lst) '())
              ((pred (car lst)) (cons (car lst) (loop (cdr lst))))
              (else (loop (cdr lst)))))))
  > (pretty-print-line-length 40)
  > (pretty-print '(define filter (lambda (pred lst) (let loop ((lst lst)) (cond ((null? lst) (quote ())) ((pred (car lst)) (cons (car lst) (loop (cdr lst)))) (else (loop (cdr lst))))))))
  (define filter
    (lambda (pred lst)
      (let loop ((lst lst))
        (cond ((null? lst) '())
              ((pred (car lst))
               (cons (car lst)
                     (loop (cdr lst))))
              (else (loop (cdr lst)))))))
```


## Macro expander

##### `(macro-expand <form>)` &nbsp; procedure

- Returns an expanded form.
<br /><br />
```
  > (import (core))
  > (macro-expand '(do ((i 0 (+ i 1))) ((> i 4)) (display i)))
  (begin
    (define |.L~3`9*|
      (lambda (|i`10*|)
        (if (> |i`10*| 4) (|.unspecified|) (begin (display |i`10*|) (|.L~3`9*| (+ |i`10*| 1))))))
    (|.L~3`9*| 0))
```

## Garbage collection

##### `(collect [<compaction>])` &nbsp; procedure

- When `<compaction>` is #t, perfoms a heap compaction and returns after finished.
- Otherwise starts a concurrent garbage collection and returns immediately.

##### `(collect-notify <boolean>)` &nbsp; parameter

- When `<boolean>` is #t, prints a message when performing a garbage collection.
<br /><br />
```
  > (import (core))
  > (collect-notify #t)
  ...
  ;; [collect concurrent:7.66ms pause:0.01ms/0.00ms/0.02ms]
```

##### `(collect-stack-notify <boolean>)` &nbsp; parameter

- When `<boolean>` is #t, prints a message when performing a vm stack collection.
<br /><br />
```
  > (import (core))
  > (collect-stack-notify #t)
  ...
  ;; [collect-stack: 55.1% free]
```

##### `(collect-trip-bytes <bytes>)` &nbsp; parameter

- Sets the allocation threshold to `<bytes>` to initiate a garbage collection.


##### `(display-heap-statistics)` &nbsp; procedure

- Displays a heap state on a visual map.
<br /><br />
```
  > (import (core))
  > (display-heap-statistics)

    |PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPsPOOOOSoOOOOOOOOOOPPOSOOOOOOsOsP|
    |ssOoSOOP-OOoOOOOOOP---PPooSOOoOoooOOOOOOOOooooooOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOoOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOooOOOOOOOOoooP-----P-----P-----oooooooooOoooPoOOP|
    |P-PoP---oooso.o..o.P-sP--o...OoO.SOooso.o o o o  o.oo   P.......|
    |......ooo.. ...............oooooooooOOO.........OoOoSO  ........|
    |..........................o....ooooo... oo oo.oooo.oo.oo o.o.ooo|
    |oo.oo..ooo .oO..o.ooo.ooooo oo.o.oo.o.oo.ooo ooo.oo.o...oO.o...O|
    | ooooOo..Ooo.o Ooo.Oo....Oo.oooOo ..oO.ooO..oooO.ooo. OoooOoOooo|
    |ooO.o. ..O.oooO.o.OoooooOOOooo.OoooOOoooO.......O..........O....|
    |..........O...........O.........................O ..............|
    |.............O.....o...............................O............|
    |......o.O.................o.OOOOO.OOOO.OOOOOoOOOOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOO OOOOOOOOOO OOOOOO  OO  OOO    OOOOOOOOOOOOOP-O OOOOOOOOO|
    |OOOOOOOOOOOOOOOOOO            P---P---SS OPPPPPP-P-P---P---|
    object:980 static:16 page:104 free:47 watermark:1147 limit:262144

  > (collect #t)
  > (display-heap-statistics)

    |PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPoPOOOOosOOOOOOOOOOPsPOOOOOOOoOoP|
    |OOOsoOOPPOOsOOOOOOsP-OOOssoP-----OOOOOOOOOP-----OOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO|
    |OOOOOOOOOOOOOOOOOOOOOOOOOP---P-----OOOOOOOOoOoo|
    object:298 static:7 page:62 free:0 watermark:367 limit:262144
```
