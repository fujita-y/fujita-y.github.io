;; Input file for Ypsilon DocMaker 0.9
;; Ypsilon API Reference (c) 2009 Y.FUJITA / LittleWing Co.Ltd.

(:api
  (:library (ypsilon c-types))
  (:exports
    define-c-enum
    define-c-typedef define-c-struct-methods define-c-struct-type c-sizeof c-coerce-void*

    make-bytevector-mapping
    bytevector-c-short-ref bytevector-c-int-ref bytevector-c-long-ref bytevector-c-long-long-ref
    bytevector-c-void*-ref bytevector-c-float-ref bytevector-c-double-ref
    bytevector-c-unsigned-short-ref bytevector-c-unsigned-int-ref bytevector-c-unsigned-long-ref bytevector-c-unsigned-long-long-ref
    bytevector-c-int8-ref bytevector-c-int16-ref bytevector-c-int32-ref bytevector-c-int64-ref
    bytevector-c-uint8-ref bytevector-c-uint16-ref bytevector-c-uint32-ref bytevector-c-uint64-ref
    bytevector-c-short-set! bytevector-c-int-set! bytevector-c-long-set! bytevector-c-long-long-set!
    bytevector-c-void*-set! bytevector-c-float-set! bytevector-c-double-set! bytevector-c-int8-set!
    bytevector-c-int16-set! bytevector-c-int32-set! bytevector-c-int64-set! bytevector-c-strlen

    make-c-bool
    make-c-short
    make-c-int
    make-c-long
    make-c-long-long
    make-c-void*
    make-c-float
    make-c-double
    make-c-int8
    make-c-int16
    make-c-int32
    make-c-int64
    c-bool-ref
    c-short-ref
    c-int-ref
    c-long-ref
    c-long-long-ref
    c-void*-ref
    c-float-ref
    c-double-ref
    c-unsigned-short-ref
    c-unsigned-int-ref
    c-unsigned-long-ref
    c-unsigned-long-long-ref
    c-int8-ref
    c-int16-ref
    c-int32-ref
    c-int64-ref
    c-uint8-ref
    c-uint16-ref
    c-uint32-ref
    c-uint64-ref
    c-string-ref
    c-bool-set!
    c-short-set!
    c-int-set!
    c-long-set!
    c-long-long-set!
    c-void*-set!
    c-float-set!
    c-double-set!
    c-int8-set!
    c-int16-set!
    c-int32-set!
    c-int64-set!
    c-string-set!

    alignof:bool alignof:short alignof:int alignof:long alignof:long-long alignof:size_t alignof:void* alignof:float alignof:double
    alignof:int8_t alignof:int16_t  alignof:int32_t alignof:int64_t
    sizeof:bool sizeof:short sizeof:int sizeof:long sizeof:long-long sizeof:size_t sizeof:void*)
  (:abstract
    "This library provides C typedef and C struct interface.")
  #;(:abstract
    "This library provides C typedef and C struct interface for Scheme. \
     It is designed to use with a foreign function interface.")
  (:link-list))

(:api
  (:macro define-c-enum)
  (:abstract
    "define-c-enum defines a C enumeration constant. \
     This macro has an analogy to the C enum statement.")
  (:synopsis
   ((spec "<subform>") (symbol :literal) (value :literal))
   (define-c-enum spec ...))
  (:definition :arguments #f
    (spec)
    "—a enumeration specifier. It should be either symbol or (symbol . value). \
       In the later case, constant will be assigned to the value.")
  (:example #t
    "> (import (rnrs) (ypsilon c-types))"
    "> (define-c-enum FOO (BAR . 10) BAZ)"
    "> (list FOO BAR BAZ)"
    "@(0 10 11)"))

(:api
  (:macro define-c-typedef)
  (:abstract
    "define-c-typedef defines a C structure type. \
     This macro has an analogy to the C typedef statement.")
  (:subsection
   (:synopsis
    ((type-name <symbol>) (struct :literal) (field-type <symbol>) (field-name <symbol>))
    (define-c-typedef type-name (struct (field-type field-name) ...)))
   (:indent
     (:definition :arguments #f
       (type-name)
       "—a type name."
       (field-type)
       "—a field type declarator. Valid declarators are listed below:"
       (:block #f
         (:definition :keywords "&bull; "
           ("short, int, long, int8_t, int16_t, int32_t, and int64_t;")
           "specifies a signed integer field, and a size of the field is the same as in C."
           ("bool, char, unsigned-short, unsigned-int, unsigned-long, size_t, uint8_t, uint16_t, uint32_t, uint64_t, and void*;")
           "specifies an unsigned integer field, and a size of the field is the same as in C."
           ("float and double;")
           "specifies an IEEE floating number field, and a size of the field is the same as in C."
           ))
       (field-name)
       "—a field name."))
   (:description #t
     "A defined type is bound to type-name, \
     and subsequent define-c-typedef can use it for field names to define compound types."))
  (:subsection
   (:arguments
     (new-name <symbol>)
     (old-name <symbol>))
   (:description #t
     "This syntax defines an alias type name for an existing type."))
  (:description "notes:"
    "define-c-typedef does not define a constructor, accessors, nor mutators, use define-c-struct-methods to define them.")
  (:example #t
    "> (import (rnrs) (ypsilon c-types))"
    "> (define-c-typedef time_t long)"
    "> (define-c-typedef suseconds_t long)"
    "> (define-c-typedef timeval (struct (time_t tv_sec) (suseconds_t tv_usec)))"
    "> timeval"
    "@#<c-typedef timeval 8 4 (struct (time_t tv_sec) (suseconds_t tv_usec))>"))
(:api
  (:macro define-c-struct-methods)
  (:abstract
    "define-c-struct-methods defines a constructor, accessors, \
     and mutators for a C structure type.")
  (:synopsis
   ((type-name <symbol>))
   (define-c-struct-methods type-name ...))
  (:description #t
    "The constructor returns a bytevector for a strage to hold field values. \
     The mutator stores a two's complement representation of a value to a field, and \
     it is an assertion violation if the value does not fit to the field. \
     Methods defined by define-c-struct-methods are macro, and \
     following naming convention is used to name them:")
  (:indent
    (:subsection
     (:text
      "The constructor's name is generated by appending 'make-' and type-name. \
        Each accessor's name is generated by appending type-name, '-', and a field name. \
        Each mutator's name is generated by appending type-name, '-', a field name, and '-set!'.")))
  (:example #t
    "> (import (rnrs) (ypsilon c-types))"
    "> (define-c-typedef point (struct (int x) (int y)))"
    "> point"
    "@#<c-typedef point 8 4 (struct (int x) (int y))>"
    "> (define-c-struct-methods point)"
    "> (define pt (make-point)) ; make-point"
    "> pt"
    "@#vu8(0 0 0 0 0 0 0 0)"
    "> (point-x-set! pt 1000)   ; point-x-set!"
    "> (point-y-set! pt -500)   ; point-y-set!"
    "> pt"
    "@#vu8(232 3 0 0 12 254 255 255)"
    "> (point-x pt)             ; point-x"
    "@1000"
    "> (point-y pt)             ; point-y"
    "@-500")
  (:example #f
    ";; demonstrate assignments to 32bit fields"
    "> (import (rnrs) (ypsilon c-types))"
    "> (define-c-typedef type32b (struct (uint32_t u) (int32_t s)))"
    "> (define-c-struct-methods type32b)"
    "> (define nums (make-type32b))"
    "> (type32b-u-set! nums #xffffffff)"
    "> (type32b-u nums)"
    "@4294967295"
    "\n"
    ";; int32_t s = (signed)4294967295U;"
    ";; cout << s; /* prints -1 */"
    "> (type32b-s-set! nums 4294967295)"
    "> (type32b-s nums)"
    "@-1"
    "\n"
    ";; uint32_t u = (unsigned)-1;"
    ";; cout << u; /* prints 4294967295 */"
    "> (type32b-u-set! nums -1)"
    "> (type32b-u nums)"
    "@4294967295"))
(:api
  (:macro define-c-struct-type)
  (:abstract
    "define-c-struct-type is a handy macro that combines \
     define-c-typedef and define-c-struct-methods.")
  (:synopsis
   ((type-name <symbol>) (field-type <symbol>) (field-name <symbol>))
   (define-c-struct-type type-name (field-type field-name) ...))
  (:example #t
    "> (import (rnrs) (ypsilon c-types))"
    "> (define-c-struct-type point (int x) (int y))"
    "> (define pt (make-point))"
    "> (point-x-set! pt 1000)"
    "> (point-y-set! pt -500)"
    "> pt"
    "@#vu8(232 3 0 0 12 254 255 255)"
    "> (point-x pt)"
    "@1000"
    "> (point-y pt)"
    "@-500"))
(:api
  (:macro c-sizeof)
  (:abstract
    "c-sizeof returns a byte size of C primitive or C structure type.")
  (:arguments
    (type-name <symbol>))
  (:example #t
    "> (import (ypsilon c-types))"
    ";; primitive type"
    "> (c-sizeof unsigned-int)"
    "@4"
    ";; structure type"
    "> (define-c-typedef foo (struct (int8_t u8) (int32_t u32)))"
    "> (c-sizeof foo)"
    "@8"))
(:api
  (:macro c-coerce-void*)
  (:abstract
    "c-coerce-void* coerces a C void* value to a C structure object.")
  (:arguments
    (expression <subform>)
    (type-name <symbol>))
  (:description #f
    "The expression must be evaluated as an exact integer.")
  (:description "notes:"
    "Be aware that misuse of this procedure causes a fatal error, segmentation fault for an example.")
  (:example #t
    "> (import (ypsilon sdl))"
    "> (SDL_Init SDL_INIT_EVERYTHING)"
    "@0 ; init success"
;    "\n"
    "> (define screen (SDL_SetVideoMode 256 256 32 SDL_SWSURFACE))"
    "> screen"
    "@159419344 ; 0x9808bd0"
;    "\n"
    "> (define surface (c-coerce-void* screen SDL_Surface))"
    "> surface"
    "@#<bytevector-mapping 0x9808bd0 60>"
;    "\n"
    "> (SDL_MapRGB (SDL_Surface-format surface) #x20 #xff #x10)"
    "@2162448 ; 0x20ff10"))

(:api
  (:procedure bytevector-c-short-ref <int>)
  (:abstract
    "bytevector-c-short-ref retrieves a short value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-int-ref <int>)
  (:abstract
    "bytevector-c-int-ref retrieves an int value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-long-ref <int>)
  (:abstract
    "bytevector-c-long-ref retrieves a long value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-long-long-ref <int>)
  (:abstract
    "bytevector-c-long-long-ref retrieves a long long value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-void*-ref <int>)
  (:abstract
    "bytevector-c-void*-ref retrieves a void* value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-float-ref "<flonum>")
  (:abstract
    "bytevector-c-float-ref retrieves a float value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-double-ref "<flonum>")
  (:abstract
    "bytevector-c-double-ref retrieves a double value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-unsigned-short-ref <int>)
  (:abstract
    "bytevector-c-unsigned-short-ref retrieves an unsigned short value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-unsigned-int-ref <int>)
  (:abstract
    "bytevector-c-unsigned-int-ref retrieves an unsigned int value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-unsigned-long-ref <int>)
  (:abstract
    "bytevector-c-unsigned-long-ref retrieves an unsigned long value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-unsigned-long-long-ref <int>)
  (:abstract
    "bytevector-c-unsigned-long-long-ref retrieves an unsigned long long value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-int8-ref <int>)
  (:abstract
    "bytevector-c-int8-ref retrieves an int8_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-int16-ref <int>)
  (:abstract
    "bytevector-c-int16-ref retrieves an int16_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-int32-ref <int>)
  (:abstract
    "bytevector-c-int32-ref retrieves an int32_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-int64-ref <int>)
  (:abstract
    "bytevector-c-int64-ref retrieves an int64_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-uint8-ref <int>)
  (:abstract
    "bytevector-c-uint8-ref retrieves an uint8_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-uint16-ref <int>)
  (:abstract
    "bytevector-c-uint16-ref retrieves an uint16_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-uint32-ref <int>)
  (:abstract
    "bytevector-c-uint32-ref retrieves an uint32_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-uint64-ref <int>)
  (:abstract
    "bytevector-c-uint64-ref retrieves an uint64_t value from a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-short-set! "unspecified")
  (:abstract
    "bytevector-c-short-set! stores a short value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [SHORT_MIN, USHORT_MAX]."))
(:api
  (:procedure bytevector-c-int-set! "unspecified")
  (:abstract
    "bytevector-c-int-set! stores an int value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [INT_MIN, UINT_MAX]."))
(:api
  (:procedure bytevector-c-long-set! "unspecified")
  (:abstract
    "bytevector-c-long-set! stores a long value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [LONG_MIN, ULONG_MAX]."))
(:api
  (:procedure bytevector-c-long-long-set! "unspecified")
  (:abstract
    "bytevector-c-long-long-set! stores a long long value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [LONGLONG_MIN, ULONGLONG_MAX]."))
(:api
  (:procedure bytevector-c-void*-set! "unspecified")
  (:abstract
    "bytevector-c-void*-set! stores a void* value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [INTPTR_MIN, UINTPTR_MAX]."))
(:api
  (:procedure bytevector-c-float-set! "unspecified")
  (:abstract
    "bytevector-c-float-set! stores a float value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value "<flonum>"))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-double-set! "unspecified")
  (:abstract
    "bytevector-c-double-set! stores a double value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value "<flonum>"))
  (:description #f
    "The byteoffset must be non-negative."))
(:api
  (:procedure bytevector-c-int8-set! "unspecified")
  (:abstract
    "bytevector-c-int8-set! stores an int8_t value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [INT8_MIN, UINT8_MAX]."))
(:api
  (:procedure bytevector-c-int16-set! "unspecified")
  (:abstract
    "bytevector-c-int16-set! stores an int16_t value to a bytevector.")
  (:arguments (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [INT16_MIN, UINT16_MAX]."))
(:api
  (:procedure bytevector-c-int32-set! "unspecified")
  (:abstract "bytevector-c-int32-set! stores an int32_t value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [INT32_MIN, UINT32_MAX]."))
(:api
  (:procedure bytevector-c-int64-set! "unspecified")
  (:abstract
    "bytevector-c-int64-set! stores an int64_t value to a bytevector.")
  (:arguments
    (bytevector <bytevector>)
    (byteoffset <int>)
    (value <int>))
  (:description #f
    "The byteoffset must be non-negative."
    "The value must be within the range [INT64_MIN, UINT64_MAX]."))
(:api
  (:procedure bytevector-c-strlen "<int>")
  (:abstract
    "bytevector-c-strlen returns a C string length of its contents.")
  (:arguments
    (bytevector <bytevector>))
  (:description #t
    "If no terminating zero byte exists in the bytevector, bytevector-c-strlen returns bytevector-length of the bytevector."))

(:api
  (:procedure make-c-bool "<bytevector>")
  (:abstract
    "make-c-bool returns a bytevector contains a bool value.")
  (:arguments
    (value <int>)))
(:api
  (:procedure make-c-short "<bytevector>")
  (:abstract
    "make-c-short returns a bytevector contains a short value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [SHORT_MIN, USHORT_MAX]."))
(:api
  (:procedure make-c-int "<bytevector>")
  (:abstract
    "make-c-int returns a bytevector contains an int value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [INT_MIN, UINT_MAX]."))
(:api
  (:procedure make-c-long "<bytevector>")
  (:abstract
    "make-c-long returns a bytevector contains a long value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [LONG_MIN, ULONG_MAX]."))
(:api
  (:procedure make-c-long-long "<bytevector>")
  (:abstract
    "make-c-long-long returns a bytevector contains a long long value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [LONGLONG_MIN, ULONGLONG_MAX]."))
(:api
  (:procedure make-c-void* "<bytevector>")
  (:abstract
    "make-c-void* returns a bytevector contains a void* value.")
  (:arguments
    (value <int>))  (:description #f
                      "The value must be within the range [INTPTR_MIN, UINTPTR_MAX]."))
(:api
  (:procedure make-c-float "<bytevector>")
  (:abstract
    "make-c-float returns a bytevector contains a float value.")
  (:arguments
    (value <flonum>)))
(:api
  (:procedure make-c-double "<bytevector>")
  (:abstract
    "make-c-double returns a bytevector contains a double value.")
  (:arguments
    (value <flonum>)))
(:api
  (:procedure make-c-int8 "<bytevector>")
  (:abstract
    "make-c-int8 returns a bytevector contains an int8_t value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [INT8_MIN, UINT8_MAX]."))
(:api
  (:procedure make-c-int16 "<bytevector>")
  (:abstract
    "make-c-int16 returns a bytevector contains an int16_t value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [INT16_MIN, UINT16_MAX]."))
(:api
  (:procedure make-c-int32 "<bytevector>")
  (:abstract
    "make-c-int32 returns a bytevector contains an int32_t value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [INT32_MIN, UINT32_MAX]."))

(:api
  (:procedure make-c-int64 "<bytevector>")
  (:abstract
    "make-c-int64 returns a bytevector contains an int64_t value.")
  (:arguments
    (value <int>))
  (:description #f
    "The value must be within the range [INT64_MIN, UINT64_MAX]."))

(:api
  (:procedure make-c-string "<bytevector>")
  (:abstract
    "make-c-string returns a bytevector contains a C string.")
  (:arguments
    (value <string>))
  (:description #t
    "A terminating zero byte will be appended."))

(:api
  (:procedure c-bool-ref "<int>")
  (:abstract
    "c-bool-ref retrieves a bool value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-short-ref "<int>")
  (:abstract
    "c-short-ref retrieves a short value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-int-ref "<int>")
  (:abstract
    "c-int-ref retrieves an int value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-long-ref "<int>")
  (:abstract
    "c-long-ref retrieves a long value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-long-long-ref "<int>")
  (:abstract
    "c-long-long-ref retrieves a long long value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-void*-ref "<int>")
  (:abstract
    "c-void*-ref retrieves a void* value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-float-ref "<flonum>")
  (:abstract
    "c-float-ref retrieves a float value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-double-ref "<flonum>")
  (:abstract
    "c-double-ref retrieves a double value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-unsigned-short-ref "<int>")
  (:abstract
    "c-unsigned-short-ref retrieves an unsigned short value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-unsigned-int-ref "<int>")
  (:abstract
    "c-unsigned-int-ref retrieves an unsigned int value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-unsigned-long-ref "<int>")
  (:abstract
    "c-unsigned-long-ref retrieves an unsigned long value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-unsigned-long-long-ref "<int>")
  (:abstract
    "c-unsigned-long-long-ref retrieves an unsigned long long value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))

(:api
  (:procedure c-int8-ref "<int>")
  (:abstract
    "c-int8-ref retrieves an int8_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-int16-ref "<int>")
  (:abstract
    "c-int16-ref retrieves an int16_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-int32-ref "<int>")
  (:abstract
    "c-int32-ref retrieves an int32_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-int64-ref "<int>")
  (:abstract
    "c-int64-ref retrieves an int64_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-uint8-ref "<int>")
  (:abstract
    "c-uint8-ref retrieves an uint8_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-uint16-ref "<int>")
  (:abstract
    "c-uint16-ref retrieves an uint16_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-uint32-ref "<int>")
  (:abstract
    "c-uint32-ref retrieves an uint32_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-uint64-ref "<int>")
  (:abstract
    "c-uint64-ref retrieves an uint64_t value from a memory.")
  (:arguments
    (location "<address> or <bytevector>")))
(:api
  (:procedure c-string-ref "<string>")
  (:abstract
    "c-string-ref retrieves a C string from a memory.")
  (:arguments
    (location "<address> or <bytevector>"))
  (:description #t
    "A terminating zero byte will be removed."))
(:api
  (:procedure c-bool-set! "unspecified")
  (:abstract
    "c-bool-set! stores a bool value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>)))
(:api
  (:procedure c-short-set! "unspecified")
  (:abstract
    "c-short-set! stores a short value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [SHORT_MIN, USHORT_MAX]."))
(:api
  (:procedure c-int-set! "unspecified")
  (:abstract
    "c-int-set! stores a int value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [INT_MIN, UINT_MAX]."))
(:api
  (:procedure c-long-set! "unspecified")
  (:abstract
    "c-long-set! stores a long value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [LONG_MIN, ULONG_MAX]."))
(:api
  (:procedure c-long-long-set! "unspecified")
  (:abstract
    "c-long-set! stores a long long value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [LONGLONG_MIN, ULONGLONG_MAX]."))
(:api
  (:procedure c-void*-set! "unspecified")
  (:abstract
    "c-void*-set! stores a void* value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [INTPTR_MIN, UINTPTR_MAX]."))
(:api
  (:procedure c-float-set! "unspecified")
  (:abstract
    "c-float-set! stores a float value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <flonum>)))
(:api
  (:procedure c-double-set! "unspecified")
  (:abstract
    "c-double-set! stores a double value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <flonum>)))
(:api
  (:procedure c-int8-set! "unspecified")
  (:abstract
    "c-int8-set! stores a int8_t value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [INT8_MIN, UINT8_MAX]."))
(:api
  (:procedure c-int16-set! "unspecified")
  (:abstract
    "c-int16-set! stores a int16_t value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [INT16_MIN, UINT16_MAX]."))
(:api
  (:procedure c-int32-set! "unspecified")
  (:abstract
    "c-int32-set! stores a int32_t value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [INT32_MIN, UINT32_MAX]."))
(:api
  (:procedure c-int64-set! "unspecified")
  (:abstract
    "c-int64-set! stores a int64_t value to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <int>))
  (:description #f
    "The value must be within the range [INT64_MIN, UINT64_MAX]."))
(:api
  (:procedure c-string-set! "unspecified")
  (:abstract
    "c-string-set! stores a C string to a memory.")
  (:arguments
    (location "<address> or <bytevector>")
    (value <string>))
  (:description #t
    "A terminating zero byte will be appended."))

(:api
  (:constant alignof:bool alignof:short alignof:int alignof:long alignof:long-long alignof:size_t
             alignof:void* alignof:float alignof:double
             alignof:int8_t alignof:int16_t alignof:int32_t alignof:int64_t)
  (:abstract "Each constant is defined to an alignment size of correspondent C types."))
(:api
  (:constant sizeof:bool sizeof:short sizeof:int sizeof:long sizof:long-long sizeof:size_t sizeof:void*)
  (:abstract "Each constant is defined to a byte size of correspondent C types."))

; [end]
