;; Input file for Ypsilon DocMaker 0.9
;; Ypsilon API Reference (c) 2009 Y.FUJITA / LittleWing Co.Ltd.


(:api
  (:library (ypsilon ffi))
  (:exports
    load-shared-object
    c-function c-function/errno c-function/win32-lasterror
    lookup-shared-object
    make-cdecl-callout
    make-cdecl-callback
    make-stdcall-callout
    make-stdcall-callback
    make-bytevector-mapping
    bytevector-mapping?
    shared-object-errno shared-object-win32-lasterror win32-error->string
    on-darwin on-linux on-freebsd on-openbsd on-posix on-windows on-ia32 on-x64 on-ppc32 on-ppc64
    (ypsilon c-types)
    define-c-enum define-c-typedef define-c-struct-methods define-c-struct-type c-sizeof c-coerce-void*
    bytevector-c-short-ref bytevector-c-int-ref bytevector-c-long-ref bytevector-c-long-long-ref
    bytevector-c-void*-ref bytevector-c-float-ref bytevector-c-double-ref
    bytevector-c-unsigned-short-ref bytevector-c-unsigned-int-ref bytevector-c-unsigned-long-ref bytevector-c-unsigned-long-long-ref
    bytevector-c-short-set! bytevector-c-int-set! bytevector-c-long-set! bytevector-c-long-long-set!
    bytevector-c-void*-set! bytevector-c-float-set! bytevector-c-double-set!
    bytevector-c-int8-ref bytevector-c-int16-ref bytevector-c-int32-ref bytevector-c-int64-ref
    bytevector-c-uint8-ref bytevector-c-uint16-ref bytevector-c-uint32-ref bytevector-c-uint64-ref
    bytevector-c-int8-set! bytevector-c-int16-set! bytevector-c-int32-set! bytevector-c-int64-set!
    bytevector-c-strlen

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

    sizeof:bool sizeof:short sizeof:int sizeof:long sizeof:long-long sizeof:size_t sizeof:void*
    alignof:bool alignof:short alignof:int alignof:long alignof:long-long alignof:size_t
    alignof:void* alignof:float alignof:double
    alignof:int8_t alignof:int16_t alignof:int32_t alignof:int64_t)
  (:abstract "This library provides an on the fly C foreign function interface.")
  (:link-list))
(:api
  (:procedure load-shared-object "<handle>")
  (:abstract
    "load-shared-object loads a shared object, and returns its handle.")
  (:arguments
    :optional
    (filename <string>))
  (:description "notes:"
    "load-shared-object returns the handle for the main program if filename is omitted.")
  (:example #f
    "> (import (rnrs) (ypsilon ffi))"
    "> (load-shared-object)"
    "@3086820976"
    "> (load-shared-object \"libc.so.6\") ; Ubuntu 9.04"
    "@3086481440"))
(:api
  (:macro c-function)
  (:abstract
    "c-function transcribes a stub code—lambda expression—that calls a C foreign function. \
     Ypsilon handles data conversion between C and Scheme.")
  #;(:arguments
    (so-handle <handle>)
    (so-name <string>)
    (return-type <symbol>)
    (__stdcall :optional-literal)
    (function-name <symbol>)
    ((argument-type ...) <subform>))

  (:synopsis
   ((so-handle <handle>)
    (so-name <string>)
    (return-type <symbol>)
    (__stdcall :literal)
    (__cdecl :literal)
    (function-name <symbol>)
    ((argument-type ...) <subform>))
   (c-function so-handle so-name return-type function-name (argument-type ...))
   (c-function so-handle so-name return-type __cdecl function-name (argument-type ...))
   (c-function so-handle so-name return-type __stdcall function-name (argument-type ...)))

  (:indent
    (:definition :keywords #f
      (__cdecl __stdcall)
      "—an optional calling convention declarator. The __stdcall declarator is ignored on that other than Windows platforms. \
       The __cdecl is the default for all of platforms.")
    (:definition :arguments #f
      (so-handle)
      "—a value returned by load-shared-object."
      (so-name)
      "—a value for informational purposes."
      (return-type)
      "—a foreign function return type declarator. Valid declarators are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (short int long long-long int8_t int16_t int32_t int64_t)
          "receives a corresponding type value from C."
          "returns an exact integer value to Scheme."
          (char unsigned-short unsigned-int unsigned-long unsigned-long-long uint8_t uint16_t uint32_t uint64_t size_t void*)
          "receives a corresponding type value from C."
          "returns a non-negative exact integer value to Scheme"
          (float double)
          "receives a corresponding type value from C."
          "returns a flonum value to Scheme."
          (bool)
          "receives a corresponding type value from C."
          "returns 0 or 1 to Scheme."
          (char*)
          "receives a utf-8 null terminated string or NULL from C."
          "returns string or 0 to Scheme."
          (void)
          "receives no value from C."
          "returns an unspecified value to Scheme."
          ))
      ((argument-type ...))
      "—a list of foreign function argument type declarators, (char* int int) for an example. \
       Valid declarators are listed below:"
      (:block #f
        (:definition :keywords "&bull; "
          (char short int long long-long unsigned-short unsigned-int unsigned-long unsigned-long-long int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t size_t)
          "expects an exact integer value from Scheme."
          "passes it to C as a corresponding type value."
          (float double)
          "expects a real value from Scheme."
          "passes it to C as a IEEE floating point number."
          (bool)
          "expects an exact integer value from Scheme."
          "passes it to C as a bool."
          (char*)
          "expects a string or 0 from Scheme."
          "passes it to C as a utf-8 null terminated string, or NULL."
          (void*)
          "expects an exact integer value or a bytevector from Scheme."
          "passes it to C as a void*."
          ("'...'")
          "indicates variadic arguments."
          ("[int]")
          "expects a vector of exact integer values from Scheme."
          "passes it to C as an address of int vector (i.e. int*)."
          ("[char*]")
          "expects a vector of string from Scheme."
          "passes it to C as an address of char* vector (i.e. char**)."
          ("(*[char*])")
          "expects a vector of string from Scheme."
          "passes it to C as an address of pointer to char* vector (i.e. char***)."
          ("(c-callback ...)")
          "expects a Scheme procedure."
          "passes it to C as a C callback function pointer."
          (:block c-callback
            (:synopsis
             ((return-type <symbol>)
              (__stdcall :literal)
              (__cdecl :literal)
              ((argument-type ...) <subform>))
             (c-callback return-type (argument-type ...))
             (c-callback return-type __cdecl (argument-type ...))
             (c-callback return-type __stdcall (argument-type ...)))
            (:indent
              (:definition :keywords #f
                (__cdecl __stdcall)
                "—an optional calling convention declarator. The __stdcall declarator is ignored on that other than Windows platforms. \
                 The __cdecl is the default for all of platforms.")
              (:definition :arguments #f
                (return-type)
                "—a foreign callback return type declarator. Valid declarators are listed below:"
                (:block #f
                  (:definition :keywords "&bull; "
                    (char short int long long-long unsigned-short unsigned-int unsigned-long unsigned-long-long int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t size_t void*)
                    "receives an exact integer value from Scheme."
                    "returns it to C as a corresponding type value."
                    (float double)
                    "receives a real value from Scheme."
                    "returns it to C as a corresponding type value."
                    (bool)
                    "receives an exact integer value from Scheme."
                    "returns false to C if the value is 0, and otherwise returns true to C."
                    (void)
                    "receives no value from Scheme."
                    "returns no value to C."
                    ))
                ((argument-type ...))
                "—a list of foreign callback argument type declarators. Valid declarators are listed below:"
                (:block #f
                  (:definition :keywords "&bull; "
                    (bool)
                    "expects a corresponding type value from C."
                    "passes it to Scheme as 0 or 1."
                    (short int long long-long int8_t int16_t int32_t int64_t)
                    "expects a corresponding type value from C."
                    "passes it to Scheme as an exact integer value."
                    (char unsigned-short unsigned-int unsigned-long unsigned-long-long uint8_t uint16_t uint32_t uint64_t size_t void*)
                    "expects a corresponding type value from C."
                    "passes it to Scheme as a non-negative exact integer value."
                    (float double)
                    "expects a corresponding type value from C."
                    "passes it to Scheme as a real value.")))))))))
  (:example #t
    "(import (rnrs) (ypsilon ffi))"
    "\n"
    ";; load GLUT library"
    "(define lib (load-shared-object \"libglut.so.3\")) ; Ubuntu 8.10"
    "\n"
    ";; void glutPositionWindow(int x, int y)"
    "(define glutPositionWindow"
    "  (c-function lib \"GLUT\""
    "    void glutPositionWindow (int int)))"
    "\n"
    ";; void glutMouseFunc(void (*func)(int button, int state, int x, int y))"
    "(define glutMouseFunc"
    "  (c-function lib \"GLUT\""
    "    void glutMouseFunc ([c-callback void (int int int int)])))"
    "\n"
    ";; void glutAddMenuEntry(const char *label, int value)"
    ";; void glutMotionFunc(void (*func)(int x, int y))"
    "(let-syntax ((defun-glut ; with handy macro"
    "              (syntax-rules ()"
    "                ((_ ret name args)"
    "                 (define name (c-function lib \"GLUT\" ret name args))))))"
    "  (defun-glut void glutAddMenuEntry (char* int))"
    "  (defun-glut void glutMotionFunc ([c-callback void (int int)])))"))
(:api
  (:macro c-function/errno)
  (:abstract
    "c-function/errno is similar to c-function, but it transcribes a stub code that returns two values. \
     The first is a C function return value, and the second is a captured errno value on return of the C function.")
  (:example #t
    "> (import (rnrs) (ypsilon ffi))"
    "> (define lib (load-shared-object \"libc.so.6\")) ; Ubuntu 8.10"
    "> (define strerror"
    "    (c-function lib \"libc\""
    "      char* strerror (int)))"
    "> (define chdir"
    "    (c-function/errno lib \"libc\""
    "      int chdir (char*)))"
    "\n"
    "> (chdir \"/\")"
    "@#<values 0 0> ; success, errno is meaningless on success as in C."
    "\n"
    "> (chdir \"/tmp/non-exists/foo/bar\")"
    "@#<values -1 2> ; failure, errno is 2 (ENOENT on linux)."
    "\n"
    "> (define my-chdir ; define wrapper function"
    "    (lambda (path)"
    "      (let-values (((retval errno) (chdir path)))"
    "        (when (< retval 0)"
    "          (assertion-violation 'my-chdir (strerror errno) (list path retval errno))))))"
    "> (my-chdir \"/tmp/non-exists/foo/bar\")"
    "\n"
    "?error in my-chdir: No such file or directory"
    "\n"
    "?irritants:"
    "?  (\"/non-exist/foo/bar\" -1 2)"
    ))
(:api
  (:macro c-function/win32-lasterror)
  (:abstract
    "c-function/win32-lasterror is similar to c-function, but it transcribes a stub code that returns two values. \
     The first is a C function return value, and the second is a value that \
     obtained by calling GetLastError() on return of the C function."))
(:api
  (:procedure lookup-shared-object "<address>")
  (:abstract
    "lookup-shared-object returns an address corresponding to a symbol name in a shared object.")
  (:arguments
    (so-handle "<handle>")
    (so-symbol "<string> or <symbol>"))
  (:example #t
    "> (import (rnrs) (ypsilon ffi))"
    "> (define libc (load-shared-object \"libc.so.6\")) ; Ubuntu 8.10"
    "> (lookup-shared-object libc 'puts)"
    "@1075667872"
    "> (lookup-shared-object libc \"strlen\")"
    "@1075757712"))

(:api
  (:procedure make-cdecl-callout "<procedure>")
  (:abstract
    "make-cdecl-callout returns a closure that calls a foreign function using the __cdecl calling convention.")
  (:arguments
    (return-type "<symbol>")
    (argument-types "<list>")
    (function-address "<address>"))
  (:indent
    (:definition :arguments #f
      (return-type)
      "—a foreign function return type declarator. Valid declarators are listed below:"
      (:block #f
        (:definition :keywords ""
          ("short, int, long, long-long, int8_t, int16_t, int32_t, int64_t, unsigned-short, unsigned-int, unsigned-long, unsigned-long-long, uint8_t, uint16_t, \
            uint32_t, uint64_t, size_t, void*, float, double, bool, char*, and void")))
      (argument-types)
      "—a list of foreign function argument type declarators. Valid declarators are listed below:"
      (:block #f
        (:definition :keywords ""
          ("bool, short, int, long, long-long, unsigned-short, unsigned-int, unsigned-long, unsigned-long-long, int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t, \
            size_t, float, double, char*, void*, \
            [int], [char*], (*[char*]) and '...'")))
      (function-address)
      "—a value returned by lookup-shared-object."))
  (:description "notes:"
    "Refer c-function for details of declarators.")
  (:example #t
    "> (import (rnrs) (ypsilon ffi))"
    "> (define libc (load-shared-object \"libc.so.6\")) ; Ubuntu 8.10"
    "> (define strcmp ; int strcmp(const char *s1, const char *s2)"
    "    (make-cdecl-callout 'int '(char* char*) (lookup-shared-object libc \"strcmp\")))"
    "> (strcmp \"foo\" \"bar\")"
    "@1"
    "> (strcmp \"hello\" \"hello\")"
    "@0"))
(:api
  (:procedure make-cdecl-callback "<address>")
  (:abstract
    "make-cdecl-callback returns a C callback function pointer using the __cdecl calling convention.")
  (:arguments
    (return-type "<symbol>")
    (argument-types "<list>")
    (procedure "<procedure>"))
  (:indent
    (:definition :arguments #f
      (return-type)
      "—a foreign callback return type declarator. Valid declarators are listed below:"
      (:block #f
        (:definition :keywords ""
          ("short, int, long, long-long, unsigned-short, unsigned-int, unsigned-long, unsigned-long-long, int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t, size_t, void*, float, double, bool, and void")))
      (argument-types)
      "—a list of foreign callback argument type declarators. Valid declarators are listed below:"
      (:block #f
        (:definition :keywords ""
          ("bool short, int, long, long-long, unsigned-short, unsigned-int, unsigned-long, unsigned-long-long, int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t, size_t, void*, float, and double")))
      (procedure)
      "—a callback ~procedure."))
  (:description "notes:"
    "Refer c-function for details of declarators.")
  (:example #t
    "> (import (rnrs) (ypsilon ffi))"
    "> (define my-expt (lambda (n1 n2) (expt n1 n2)))"
    "> (define callback (make-cdecl-callback 'int '(int int) my-expt))"
    "> callback"
    "@150958158 ; function address"
    "> (define callout (make-cdecl-callout 'int '(int int) callback))"
    "> callout"
    "@#<closure 0x77927a20> ; wrapper closure"
    "> (callout 10 3)"
    "@1000"
    ";; -> (callout 10 3) [Scheme]"
    ";;    -> callback(10, 3) [C]"
    ";;       -> (my-expt 10 3) [Scheme]"
    ";;       1000 [Scheme]"
    ";;    1000 [C]"
    ";; 1000 [Scheme]"
    ))

(:api
  (:procedure make-stdcall-callout "<procedure>")
  (:abstract
    "make-stdcall-callout is similar to make-cdecl-callout, but it uses the __stdcall calling convention."))
(:api
  (:procedure make-stdcall-callback "<address>")
  (:abstract
    "make-stdcall-callback is similar to make-cdecl-callback, but it uses the __stdcall calling convention."))

(:api
  (:procedure make-bytevector-mapping "<bytevector-mapping>")
  (:abstract
    "make-bytevector-mapping provides transparent access to an arbitrary memory block.")
  (:arguments
    (address <address>)
    (bytesize <int>))
  (:description #f
    "The bytesize must be non-negative.")
  (:description #t
    "make-bytevector-mapping returns a bytevector-mapping object that can be used as an ordinary bytevector. \
     Its contents are mapped to the memory block within the range of address to (address + bytesize - 1).")
  (:description "notes:"
    "Be aware that misuse of this procedure causes a fatal error, segmentation fault for an example.")
  (:example #t
    "> (import (rnrs) (ypsilon ffi))"
    "> (define libc (load-shared-object \"libc.so.6\")) ; Ubuntu 8.10"
    "> (define qsort"
    "    (c-function libc \"libc\""
    "      void qsort (void* int int [c-callback int (void* void*)])))"
    "> (define comp"
    "    (lambda (a1 a2)"
    "      (let ((n1 (bytevector-u32-native-ref (make-bytevector-mapping a1 4) 0))"
    "            (n2 (bytevector-u32-native-ref (make-bytevector-mapping a2 4) 0)))"
    "        (cond ((= n1 n2) 0)"
    "              ((> n1 n2) 1)"
    "              (else -1)))))"
    "> (define nums (uint-list->bytevector '(10000 1000 10 100000 100) (native-endianness) 4))"
    "> (bytevector->uint-list nums (native-endianness) 4)"
    "@(10000 1000 10 100000 100)"
    "> (qsort nums 5 4 comp)"
    "> (bytevector->uint-list nums (native-endianness) 4)"
    "@(10 100 1000 10000 100000)"))

(:api
  (:procedure bytevector-mapping? "<boolean>")
  (:abstract
    "bytevector-mapping? returns #t if its argument is a bytevector-mapping object, and otherwise returns #f.")
  (:arguments (x <object>)))

(:api
  (:parameter shared-object-errno <int>)
  (:abstract
    "shared-object-errno is a parameter contains a copy of thread local errno value.")
  (:arguments
    (errno-value <int>))
  (:description #f
    "The errno-value must be within the range [INT_MIN, INT_MAX].")
  (:description #t
    "Ypsilon captures the thread local errno value for each return of a foreign C function call. \
     An assignment to this parameter also changes the thread local errno value."))
(:api
  (:parameter shared-object-win32-lasterror <int>)
  (:abstract
    "shared-object-win32-lasterror is a parameter contains a copy of thread local win32 lasterror value.")
  (:arguments
    (lasterror-value <int>))
  (:description #f
    "The lasterror-value must be within the range [INT32_MIN, UINT32_MAX].")
  (:description #t
    "On Windows platforms, Ypsilon captures a win32 lasterror value by calling GetLastError() for each return \
     of a foreign C function call. \
     An assignment to this parameter also changes the win32 lasterror value by calling SetLastError().")
  (:description "notes:"
    "Using this parameter on that other than Windows platforms causes an assertion violation."))
(:api
  (:procedure win32-error->string "<string>")
  (:abstract
    "win32-error->string returns an error message string corresponding to a win32 error code.")
  (:arguments
    (win32-error-code <int>))
  (:description #f
    "The win32-error-code must be within the range [INT32_MIN, UINT32_MAX].")
  (:description #t
    "On Windows platforms, this procedure uses FormatMessage() to get an error message from a system.")
  (:description "notes:"
    "Using this procedure on that other than Windows platforms causes an assertion violation."))


(:api
  (:constant on-darwin on-linux on-freebsd on-openbsd on-windows on-posix)
  (:abstract "Each constant is defined to a boolean value. It can be used to determine a operating system.")
  (:indent
    (:definition :constants "&bull; "
      (on-darwin) "is #t if the operating system is Darwin (Mac OS X)."
      (on-linux) "is #t if the operating system is Linux."
      (on-freebsd) "is #t if the operating system is FreeBSD."
      (on-openbsd) "is #t if the operating system is OpenBSD."
      (on-posix) "is #t if the operating system is either Darwin, Linux, FreeBSD, or OpenBSD."
      (on-windows) "is #t if the operating system is Windows.")))
(:api
  (:constant on-ia32 on-x64 on-ppc32 on-ppc64)
  (:abstract "Each constant is defined to a boolean value. It can be used to determine a CPU instruction set.")
  (:indent
    (:definition :constants "&bull; "
      (on-ia32) "is #t if the CPU instruction set is IA-32."
      (on-x64) "is #t if the CPU instruction set is Intel64 or AMD64."
      (on-ppc32) "is #t if the CPU instruction set is 32-bit PowerPC."
      (on-ppc64) "is #t if the CPU instruction set is 64-bit PowerPC.")))


; [end]
