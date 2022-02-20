;#!/usr/bin/env ypsilon
;               #!r6rs

(import (core)
        (rnrs)
        (rnrs eval)
        (rnrs mutable-pairs)
        (rnrs mutable-strings)
        (rnrs r5rs)
        (ypsilon pregexp))

(define link-r6rs.dat (read (open-input-file "link-r6rs.dat")))

(define get-link-r6rs
  (lambda (id)
    (cond ((assq id link-r6rs.dat) => cdr)
          (else #f))))

(define html-escape-table '((#\< . "&lt;") (#\> . "&gt;") (#\" . "&quot;") (#\& . "&amp;") (#\linefeed . "<br />")))
(define html-escape-table-nbsp+ (cons '(#\space . "&nbsp;") html-escape-table))

(define html-escape
  (lambda (obj)
    (apply string-append
           (map (lambda (ch)
                  (cond ((assq ch html-escape-table) => cdr)
                        (else (string ch))))
                (string->list (format "~a" obj))))))

(define html-put
  (lambda (i html fmt . args)
    (put-string html (make-string i #\space))
    (apply format html fmt args)
    (put-char html #\linefeed)))

(define object-list->string
  (lambda (ref infix)
    (let ((infix (format "~a" infix)))
      (apply string-append
             (cdr (let loop ((lst ref))
                    (if (null? lst)
                        '()
                        (cons infix
                              (cons (format "~a" (car lst))
                                    (loop (cdr lst)))))))))))

(define make-html-link
  (lambda (filename identifier)
    (format "<span class=\"subject_identifier\"><a href=\"~a#~a\">~a</a></span>"
            filename
            identifier
            (html-escape identifier))))

(define sort-identifiers
  (lambda (lst)
    (list-sort (lambda (a b)
                 (string<=? (symbol->string a) (symbol->string b)))
               lst)))

#;(define compare-name
  (lambda (a b)
    (let ((a (format "~a" a)) (b (format "~a" b)))
      (if (= (string-length a) (string-length b))
          (string<=? a b)
          (< (string-length a) (string-length b))))))

(define compare-name
  (lambda (a b)
    (let ((a (object-list->string a #\space)) (b (object-list->string b #\space)))
      (string<=? a b))))

(define get-identifer-list
  (lambda (lib)
    (sort-identifiers
     (map car (hashtable-ref (scheme-library-exports)
                             (string->symbol (object-list->string lib #\.))
                             #f)))))

(define put-mid-jump-menu
  (lambda (html)
    (html-put 0 html "<div class=\"jump_menu\">")
    #;(html-put 2 html "[<a href=\"javascript:history.back()\">Back</a>]")
    (html-put 2 html "[<a href=\"~a\">Top</a>]" "r6rs.html")
    #;(html-put 2 html "[<a href=\"#subjects\">Index</a>]")
    (html-put 0 html "</div>")))

(define ht-index (make-eq-hashtable))
(define library-list '())

(define prepare-index
  (lambda (ref name)
    (or (member ref library-list) (set! library-list (cons ref library-list)))
    (for-each (lambda (id) (hashtable-set! ht-index id (cons ref (hashtable-ref ht-index id '()))))
              (get-identifer-list ref))))

(define get-index-list
  (lambda ()
    (set! library-list (list-sort compare-name library-list))
    (let ((lst (map (lambda (e)
                      (cons (car e) (list-sort compare-name (cdr e))))
                    (hashtable->alist ht-index))))
      (list-sort (lambda (a b)
                   (string<=? (format "~a" (car a)) (format "~a" (car b))))
                 lst))))

(define make-link-box
  (lambda (html ref name)
    (define identifiers (get-identifer-list ref))
    (define total (length identifiers))
    (define each (let ((n (let ((n (/ total 3)))
                            (cond ((integer? n) n)
                                  (else (+ (truncate n) 1))))))
                   (if (< n 4) 4 n)))
    (define count1 (cond ((>= total each) each)
                         (else total)))
    (define count2 (let ((total (- total count1)))
                     (cond ((>= total each) each)
                           ((< total 0) 0)
                           (else total))))
    (define count3 (let ((total (- total count1 count2)))
                     (cond ((>= total each) each)
                           ((< total 0) 0)
                           (else total))))

    (define list1 (list-head identifiers count1))
    (define list2 (list-head (list-tail identifiers count1) count2))
    (define list3 (list-head (list-tail identifiers (+ count1 count2)) count3))

    (html-put 0 html "<span id=\"~a\"></span>" (object-list->string ref #\.))
    (put-mid-jump-menu html)
    (html-put 0 html "<div class=\"library_head\">~a</div>" (html-escape (format "[R6RS] ~a" name)))
    (html-put 0 html "<div class=\"library_body\">")
    (html-put 0 html "<table class=\"exports_parent_box\" border=\"0\">")
    (html-put 0 html "<tr>")
    (html-put 0 html "<td>")
    (if (equal? ref '(rnrs))
        (html-put 0 html "<table class=\"exports_compound_box\" border=\"0\">")
        (html-put 0 html "<table class=\"exports_box\" border=\"0\">"))
    (html-put 0 html "<caption class=\"exports_box_caption\">~a</caption>" (html-escape (format "~a" (append ref '((6))))))
    (html-put 0 html "<tr>")

    (html-put 0 html "<td valign=\"top\">")
    (begin
      (html-put 0 html "<table border=\"0\">")
      (let loop ((lst list1))
        (when (pair? lst)
          (html-put 2 html "<tr>")
          (html-put 4 html "<td>")
          (cond ((get-link-r6rs (car lst))
                 => (lambda (link)
                      (html-put 6 html "<span class=\"exports_identifier\"><a href=\"~a\">~a</a></span>" link (html-escape (car lst)))))
                (else
                 (html-put 6 html "<span class=\"exports_identifier\">~a</span>" (html-escape (car lst)))))
          (html-put 4 html "</td>")
          (html-put 2 html "</tr>")
          (loop (cdr lst))))
      (html-put 0 html "</table>")
      (html-put 0 html "</td>"))

    (html-put 0 html "<td valign=\"top\">")
    (begin
      (html-put 0 html "<table border=\"0\">")
      (let loop ((lst list2))
        (when (pair? lst)
          (html-put 2 html "<tr>")
          (html-put 4 html "<td>")
          (cond ((get-link-r6rs (car lst))
                 => (lambda (link)
                      (html-put 6 html "<span class=\"exports_identifier\"><a href=\"~a\">~a</a></span>" link (html-escape (car lst)))))
                (else
                 (html-put 6 html "<span class=\"exports_identifier\">~a</span>" (html-escape (car lst)))))
          (html-put 4 html "</td>")
          (html-put 2 html "</tr>")
          (loop (cdr lst))))
      (html-put 0 html "</table>")
      (html-put 0 html "</td>"))

    (html-put 0 html "<td valign=\"top\">")
    (begin
      (html-put 0 html "<table border=\"0\">")
      (let loop ((lst list3))
        (when (pair? lst)
          (html-put 2 html "<tr>")
          (html-put 4 html "<td>")
          (cond ((get-link-r6rs (car lst))
                 => (lambda (link)
                      (html-put 6 html "<span class=\"exports_identifier\"><a href=\"~a\">~a</a></span>" link (html-escape (car lst)))))
                (else
                 (html-put 6 html "<span class=\"exports_identifier\">~a</span>" (html-escape (car lst)))))
          (html-put 4 html "</td>")
          (html-put 2 html "</tr>")
          (loop (cdr lst))))
      (html-put 0 html "</table>")
      (html-put 0 html "</td>")
      (html-put 0 html "</tr>")
      (html-put 0 html "</table>")
      (html-put 0 html "</td>")
      (html-put 0 html "</tr>")
      (html-put 0 html "</table>")
      (html-put 0 html "</div>"))))

(define html (current-output-port))

;; head
(html-put 0 html "<div class=\"top_jump_menu\">")
(html-put 2 html
          "&bull; <a href=\"https://github.com/fujita-y/ypsilon\">Project Home</a> \
           &bull; <a href=\"index.html\">Document Home</a>")
(html-put 0 html "</div>")
(html-put 0 html "<div class=\"library_head\">[R6RS] Base library and standard libraries</div>")
(html-put 0 html "<div class=\"library_body\">")
;;
(html-put 0 html "<table class=\"abstract_box\" border=\"0\">")
(html-put 2 html "<tr>")
(html-put 4 html "<td>")
(html-put 6 html
          "<div>Each identifier in this page is linked to the corresponding document in the \
           <a href=\"http://www.r6rs.org/\">www.r6rs.org</a>. \
           Special thanks to <a href=\"http://shibuya.lisp-users.org/\">Shibuya.lisp</a> for providing link data.</div>")
(html-put 4 html "</td>")
(html-put 2 html "</tr>")
(html-put 0 html "</table>")

;; alphabetical index
(prepare-index '(rnrs base) "Base library")
(prepare-index '(rnrs unicode) "Unicode")
(prepare-index '(rnrs bytevectors) "Bytevectors")
(prepare-index '(rnrs lists) "List utilities")
(prepare-index '(rnrs sorting) "Sorting")
(prepare-index '(rnrs control) "Control structures")
(prepare-index '(rnrs records syntactic) "Records — Syntactic layer")
(prepare-index '(rnrs records procedural) "Records — Procedural layer")
(prepare-index '(rnrs records inspection) "Records — Inspection")
(prepare-index '(rnrs exceptions) "Exceptions")
(prepare-index '(rnrs conditions) "Conditions")
(prepare-index '(rnrs io ports) "Port I/O")
(prepare-index '(rnrs io simple) "Simple I/O")
(prepare-index '(rnrs files) "File system")
(prepare-index '(rnrs programs) "Command-line access and exit values")
(prepare-index '(rnrs arithmetic fixnums) "Arithmetic — Fixnums")
(prepare-index '(rnrs arithmetic flonums) "Arithmetic — Flonums")
(prepare-index '(rnrs arithmetic bitwise) "Arithmetic — Exact bitwise arithmetic")
(prepare-index '(rnrs syntax-case) "syntax-case")
(prepare-index '(rnrs hashtables) "Hashtables")
(prepare-index '(rnrs enums) "Enumerations")
(prepare-index '(rnrs) "Composite library")
(prepare-index '(rnrs eval) "eval")
(prepare-index '(rnrs mutable-pairs) "Mutable pairs")
(prepare-index '(rnrs mutable-strings) "Mutable strings")
(prepare-index '(rnrs r5rs) "R5RS compatibility")
(let ()
;  (html-put 0 html "<span id=\"~a\"></span>" "index")
;  (put-mid-jump-menu html)
;  (html-put 0 html "<div class=\"api_head\">~a</div>" (html-escape "[R6RS] Alphabetical Index"))
  (html-put 0 html "<table class=\"exports_parent_box\" border=\"0\">")
  (html-put 0 html "<tr>")
  (html-put 0 html "<td valign=\"top\">")

  (begin
    (html-put 0 html "<table class=\"exports_index_box\" border=\"0\">")
    ;(html-put 0 html "<caption class=\"exports_box_caption\">Alphabetical index:</div>")
    ;(html-put 0 html "<caption class=\"exports_box_caption\">Alphabetical index: a b c d e f g h i l m n o p q r s t u v w z</div>")
    ;(html-put 0 html "<caption class=\"exports_box_caption\">Alphabetical index: A B C D E F G H I J K L M N O P Q R S T U V W Z</div>")
    (html-put 0 html "<caption class=\"exports_box_caption\">Identifiers:")
    (for-each (lambda (c)
                (html-put 2 html " <a href=~s>~a</a>"
                          (format "#char_~a" c)
                          (char-upcase c)))
              (string->list "abcdefghilmnopqrstuvwz"))
    (html-put 0 html "</caption>")
    (for-each (lambda (lst)
                (when (pair? lst)
                  (html-put 2 html "<tr>")
                  (html-put 4 html "<td>")
                  (cond ((get-link-r6rs (car lst))
                         => (lambda (link)
                              (let ((head (case (car lst)
                                            ((abs) "char_a")
                                            ((begin) "char_b")
                                            ((caaaar) "char_c")
                                            ((datum->syntax) "char_d")
                                            ((else) "char_e")
                                            ((fields) "char_f")
                                            ((gcd) "char_g")
                                            ((hashtable-clear!) "char_h")
                                            ((i/o-decoding-error?) "char_i")
                                            ((lambda) "char_l")
                                            ((magnitude) "char_m")
                                            ((nan?) "char_n")
                                            ((odd?) "char_o")
                                            ((pair?) "char_p")
                                            ((quasiquote) "char_q")
                                            ((raise) "char_r")
                                            ((scheme-report-environment) "char_s")
                                            ((tan) "char_t")
                                            ((u8-list->bytevector) "char_u")
                                            ((values) "char_v")
                                            ((warning?) "char_w")
                                            ((zero?) "char_z")
                                            (else #f))))
                                (and head
                                     (html-put 6
                                               html
                                               "<span id=~s></span>" head)))
                              (html-put 6 html "<span class=\"exports_identifier\"><a href=\"~a\">~a</a></span>" link (html-escape (car lst)))))
                        (else
                         (html-put 6 html "<span class=\"exports_identifier\">~a</span>" (html-escape (car lst)))))
                  (html-put 4 html "</td>")
                  (html-put 4 html "<td>")
                  ;(html-put 6 html "<span class=\"exports_identifier\">~a</span>" (html-escape (object-list->string (cdr lst) #\space)))
                  (html-put 6 html "<span class=\"exports_identifier\">")
                  (for-each (lambda (ref)
                              (html-put 8
                                        html
                                        "<a href=\"#~a\">~a</a>"
                                        (object-list->string ref #\.)
                                        ref))
                            (cdr lst))
                  (html-put 6 html "</span>")
                  (html-put 4 html "</td>")
                  (html-put 2 html "</tr>")))
              (get-index-list))
    (html-put 0 html "</table>"))

  (html-put 0 html "</td>")
  (html-put 0 html "<td valign=\"top\">")

  (begin
    (html-put 2 html "<table class=\"exports_box\" border=\"0\">")
    (html-put 2 html "<caption class=\"exports_box_caption\">Libraries:</caption>")
    (for-each (lambda (ref)
                (html-put 4 html "<tr>")
                (html-put 6 html "<td>")
                (html-put 8 html "<span class=\"exports_identifier\">")
                (html-put 10
                          html
                          "<a href=\"#~a\">~a</a>"
                          (object-list->string ref #\.)
                          ref)
                (html-put 8 html "</span>")
                (html-put 6 html "</td>")
                (html-put 4 html "</tr>"))
              library-list)
    (html-put 2 html "</table>"))

  (html-put 0 html "</td>")
  (html-put 0 html "</tr>")
  (html-put 0 html "</table>")
  (html-put 0 html "</div>"))
;; each lib listing
(make-link-box html '(rnrs) "Composite library")
(make-link-box html '(rnrs arithmetic bitwise) "Arithmetic — Exact bitwise arithmetic")
(make-link-box html '(rnrs arithmetic fixnums) "Arithmetic — Fixnums")
(make-link-box html '(rnrs arithmetic flonums) "Arithmetic — Flonums")
(make-link-box html '(rnrs base) "Base library")
(make-link-box html '(rnrs bytevectors) "Bytevectors")
(make-link-box html '(rnrs conditions) "Conditions")
(make-link-box html '(rnrs control) "Control structures")
(make-link-box html '(rnrs enums) "Enumerations")
(make-link-box html '(rnrs eval) "eval")
(make-link-box html '(rnrs exceptions) "Exceptions")
(make-link-box html '(rnrs files) "File system")
(make-link-box html '(rnrs hashtables) "Hashtables")
(make-link-box html '(rnrs io ports) "Port I/O")
(make-link-box html '(rnrs io simple) "Simple I/O")
(make-link-box html '(rnrs lists) "List utilities")
(make-link-box html '(rnrs mutable-pairs) "Mutable pairs")
(make-link-box html '(rnrs mutable-strings) "Mutable strings")
(make-link-box html '(rnrs programs) "Command-line access and exit values")
(make-link-box html '(rnrs r5rs) "R5RS compatibility")
(make-link-box html '(rnrs records inspection) "Records — Inspection")
(make-link-box html '(rnrs records procedural) "Records — Procedural layer")
(make-link-box html '(rnrs records syntactic) "Records — Syntactic layer")
(make-link-box html '(rnrs sorting) "Sorting")
(make-link-box html '(rnrs syntax-case) "syntax-case")
(make-link-box html '(rnrs unicode) "Unicode")

(html-put 0 html "</div>")

