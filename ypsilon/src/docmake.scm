#!/usr/bin/env ypsilon
#!r6rs

(import (core) (ypsilon pregexp))

(define ht-toc-dict (make-parameter (make-eq-hashtable)))
(define ht-link-map (make-parameter (make-eq-hashtable)))
(define ht-subject-index (make-eq-hashtable))
(define ht-parameter-id-style (make-parameter #f))
(define current-api-name (make-parameter #f))
(define current-library-name (make-parameter #f))
(define current-library-filename (make-parameter ""))
(define port-list-of-exported-identifiers (make-string-output-port))
(define port-header-part (make-string-output-port))
(define port-summaries-part (make-string-output-port))
(define list-of-contents (make-parameter '()))

(define html-escape-table '((#\< . "&lt;") (#\> . "&gt;") (#\" . "&quot;") (#\& . "&amp;") (#\linefeed . "<br />")))
(define html-escape-table-nbsp+ (cons '(#\space . "&nbsp;") html-escape-table))

(define unescape-specials
  (lambda (text)
    (pregexp-replace "~" text "")))

(define html-escape
  (lambda (obj)
    (apply string-append
           (map (lambda (ch)
                  (cond ((assq ch html-escape-table) => cdr)
                        (else (string ch))))
                (string->list (format "~a" obj))))))

(define html-escape-code
  (lambda (obj)

    (define translate
      (lambda (obj)
        (define lastchar-is-space #t)
        (apply string-append
               (map (lambda (ch)
                      (let ((out
                             (cond (lastchar-is-space
                                    (set! lastchar-is-space #f)
                                    (cond ((assq ch html-escape-table-nbsp+) => cdr)
                                          (else (string ch))))
                                   (else
                                    (set! lastchar-is-space (eq? ch #\space))
                                    (cond ((assq ch html-escape-table) => cdr)
                                          (else (string ch)))))))
                        out))
                    (string->list (format "~a" obj))))))

    (cond ((char=? (string-ref obj 0) #\;)
           (format "<span class=\"example_comment\">~a</span>" (translate obj)))
          ((char=? (string-ref obj 0) #\@)
           (format "<span class=\"example_stdout\">~a</span>" (html-escape-code (substring obj 1 (string-length obj)))))
          ((char=? (string-ref obj 0) #\?)
           (format "<span class=\"example_stderr\">~a</span>" (html-escape-code (substring obj 1 (string-length obj)))))
          (else
           (cond ((pregexp-match-positions ";.*$" obj)
                  => (lambda (pos)
                       (destructuring-bind ((start . end)) pos
                         (format "~a<span class=\"example_comment\">~a</span>"
                                 (translate (substring obj 0 start))
                                 (translate (substring obj start end))))))
                 (else (translate obj)))))))

(define html-put
  (lambda (i html fmt . args)
    (put-string html (make-string i #\space))
    (apply format html fmt args)
    (put-char html #\linefeed)))

(define split-arguments
  (lambda (spec)
    (let loop ((spec spec) (front '()))
      (cond ((null? spec)
             (values (reverse front) '()))
            ((eq? (car spec) ':optional)
             (let loop ((spec (cdr spec)) (back '()))
               (if (null? spec)
                   (values (reverse front) (reverse back))
                   (loop (cdr spec) (cons (car spec) back)))))
            (else
             (loop (cdr spec) (cons (car spec) front)))))))

(define concat-arguments
  (lambda (args . select)
    (let ((lst (map (lambda (e)
                      (case (cadr e)
                        ((:optional-literal :literal)
                         (if (pair? select)
                             (format "<span class=\"synopsis_literal\">~a</span>" (list-ref (car e) (car select)))
                             (format "<span class=\"synopsis_literal\">~a</span>" (car e))))
                        (else
                         (format "~a" (car e)))))
                    args)))
      (if (pair? lst)
          (apply string-append
                 (cons (car lst)
                       (fold-right
                        (lambda (x lst)
                          (cons* " " x lst))
                        '() (cdr lst))))
          ""))))

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

(define concat-objects
  (lambda (args . infix)
    (let ((infix (if (pair? infix) (car infix) " ")))
      (let ((lst (map (lambda (e) (format "~a" e)) args)))
        (apply string-append
               (cons (car lst)
                     (fold-right
                      (lambda (x lst)
                        (cons* infix x lst))
                      '() (cdr lst))))))))

(define make-id-extract-regexp
  (lambda (obj)
    (pregexp (string-append "(?:^|[()[:space:]])("
                            (pregexp-quote (html-escape (format "~a" obj)))
                            ")(?:[().,[:space:]])"))))

(define make-parameter-id-style
  (lambda (args)
    (define ht-style (make-hashtable equal-hash equal?))
    (for-each (lambda (e)
                (and (pair? e)
                     (case (cadr e)
                       ((:optional-literal :literal)
                        (if (symbol? (car e))
                            (hashtable-set! ht-style
                                            (format "~a" (car e))
                                            (list (make-id-extract-regexp (car e)) "desc_literal"))
                            (for-each (lambda (id)
                                        (hashtable-set! ht-style
                                                        (format "~a" id)
                                                        (list  (make-id-extract-regexp id) "desc_literal")))
                                      (car e))))
                       (else
                        (hashtable-set! ht-style
                                        (format "~a" (car e))
                                        (list (make-id-extract-regexp (car e)) "desc_argument"))))))
              args)
    ht-style))

(define make-parameter-id-style-for-synopsis
  (lambda (args)
    (define ht-style (make-hashtable equal-hash equal?))
    (for-each (lambda (e)
                (and (pair? e)
                     (case (cadr e)
                       ((:optional-literal :literal)
                        (if (symbol? (car e))
                            (hashtable-set! ht-style
                                            (format "~a" (car e))
                                            (list (make-id-extract-regexp (car e)) "synopsis_literal"))
                            (for-each (lambda (id)
                                        (hashtable-set! ht-style
                                                        (format "~a" id)
                                                        (list (make-id-extract-regexp id) "synopsis_literal")))
                                      (car e))))
                       (else
                        (hashtable-set! ht-style
                                        (format "~a" (car e))
                                        (list (make-id-extract-regexp (car e)) "synopsis_argument"))))))
              args)
    ht-style))

(define apply-parameter-id-style
  (lambda (desc)
    (cond ((ht-parameter-id-style)
           (let loop ((lst (hashtable->alist (ht-parameter-id-style))) (desc desc))
             (cond ((null? lst) (unescape-specials desc))
                   (else
                    (destructuring-bind (key regexp value) (car lst)
                      (cond ((pregexp-match-positions regexp desc)
                             => (lambda (matches)
                                  (destructuring-bind (start . end) (cadr matches)
                                    (loop lst
                                          (string-append (substring desc 0 start)
                                                         (format "<span class=\"~a\">~a</span>" value (html-escape key))
                                                         (substring desc end (string-length desc)))))))
                            (else
                             (loop (cdr lst) desc))))))))
          (else desc))))

(define update-link-map
  (lambda (name identifiers)
    (let ((origin name))
      (let loop ((lst identifiers))
        (when (pair? lst)
          (cond ((pair? (car lst))
                 (let ((filename (format "../libref.~a.html" (object-list->string (car lst) "."))))
                   (cond ((file-exists? filename)
                          (set! origin (car lst))
                          (loop (cdr lst)))
                         (else
                          (format (current-error-port) "docmaker: file ~s not exists, keyword link disabled. ~%" filename)
                          (set! origin #f)
                          (loop (cdr lst))))))
                (origin
                 (hashtable-set! (ht-link-map)
                                 (car lst)
                                 (list (make-id-extract-regexp (car lst))
                                       (format "libref.~a.html" (object-list->string origin "."))
                                       (car lst)))
                 (loop (cdr lst)))
                (else
                 (loop (cdr lst)))))))))

(define apply-link-map
  (lambda (desc)
    (let loop ((lst (list-sort
                     (lambda (e1 e2)
                       (> (string-length (format "~a" (car e1))) (string-length (format "~a" (car e2)))))
                     (hashtable->alist (ht-link-map))))
               (desc desc))
      (cond ((null? lst) (unescape-specials desc))
            (else
             (destructuring-bind (key regexp file anchor) (car lst)
               (cond ((pregexp-match-positions regexp desc)
                      => (lambda (matches)
                           (destructuring-bind (start . end) (cadr matches)
                             (loop lst
                                   (string-append (substring desc 0 start)
                                                  (format "<a href=\"~a#~a\">~a</a>" file anchor (html-escape key))
                                                  (substring desc end (string-length desc)))))))
                     (else
                      (loop (cdr lst) desc)))))))))

(define process-generic-clause
  (lambda (clause html loop)

    (define process-description
      (lambda (html caption text)
        (html-put 0 html "<table class=\"desc_box\" border=\"0\">")
        (cond ((eq? caption #f))
              ((eq? caption #t)
               (html-put 2 html "<caption class=\"desc_box_caption\">description:</caption>"))
              (else
               (html-put 2 html (format "<caption class=\"desc_box_caption\">~a</caption>" caption))))
        (html-put 2 html "<tr>")
        (html-put 4 html "<td>")
        (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (apply-link-map (apply-parameter-id-style (html-escape e))))) text)
        (html-put 4 html "</td>")
        (html-put 2 html "</tr>")
        (html-put 0 html "</table>")))

    (define process-abstract
      (lambda (html text)
        (html-put 0 html "<table class=\"abstract_box\" border=\"0\">")
        (html-put 2 html "<tr>")
        (html-put 4 html "<td>")
        (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (apply-link-map (html-escape e)))) text)
        (html-put 4 html "</td>")
        (html-put 2 html "</tr>")
        (html-put 0 html "</table>")))

    (define process-example
      (lambda (html caption code)
        (html-put 0 html "<table class=\"example_box\" border=\"0\">")
        (cond ((eq? caption #f))
              ((eq? caption #t)
               (html-put 2 html "<caption class=\"example_box_caption\">examples:</caption>"))
              (else
               (html-put 2 html (format "<caption class=\"example_box_caption\">~a</caption>" caption))))
        (html-put 2 html "<tr>")
        (html-put 4 html "<td>")
        (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (html-escape-code e))) code)
        (html-put 4 html "</td>")
        (html-put 2 html "</tr>")
        (html-put 0 html "</table>")))

    (define process-arguments-definition
      (lambda (html defs prefix proc)
        (html-put 0 html "<dl class=\"dl_arguments\">")
        (let ((prefix (if prefix (format "<span class=dt_arguments_prefix>~a</span>" prefix) "")))
          (for-each (lambda (clause)
                      (cond ((and (pair? clause) (memq (car clause) '(:block)))
                             (cond ((cadr clause)
                                    (parameterize ((ht-parameter-id-style (ht-parameter-id-style))
                                                   (current-api-name (cadr clause)))
                                      (html-put 2 html "<dd class=\"dd_arguments\">")

                                      (html-put 4 html "<table class=\"subsection_box\" border=\"0\">")
                                      (html-put 4 html "<tr>")
                                      (html-put 4 html "<td>")
                                      (proc (cdr clause))
                                      (html-put 4 html "</td>")
                                      (html-put 4 html "</tr>")
                                      (html-put 4 html "</table>")

                                      (html-put 2 html "</dd>")))
                                   (else
                                    (html-put 2 html "<dd class=\"dd_arguments\">")
                                    (proc (cdr clause))
                                    (html-put 2 html "</dd>"))))
                            ((list? clause)
                             (for-each (lambda (e) (html-put 2 html "<dt class=\"dt_arguments\">~a~a</dt>" prefix (html-escape e))) clause))
                            ((string? clause)
                             (html-put 2 html "<dd class=\"dd_arguments\">~a</dd>" (apply-link-map (apply-parameter-id-style (html-escape clause)))))
                            (else
                             (assertion-violation 'process-arguments-definition "invalid form" clause))))
                    defs))
        (html-put 0 html "</dl>")))

    (define process-keywords-definition
      (lambda (html defs prefix proc)
        (html-put 0 html "<dl class=\"dl_keywords\">")
        (let ((prefix (if prefix (format "<span class=dt_keywords_prefix>~a</span>" prefix) "")))
          (for-each (lambda (clause)
                      (cond ((and (pair? clause) (memq (car clause) '(:block)))
                             (cond ((cadr clause)
                                    (parameterize ((ht-parameter-id-style (ht-parameter-id-style))
                                                   (current-api-name (cadr clause)))
                                      (html-put 2 html "<dd class=\"dd_keywords\">")

                                      (html-put 4 html "<table class=\"subsection_box\" border=\"0\">")
                                      (html-put 4 html "<tr>")
                                      (html-put 4 html "<td>")
                                      (proc (cdr clause))
                                      (html-put 4 html "</td>")
                                      (html-put 4 html "</tr>")
                                      (html-put 4 html "</table>")

                                      (html-put 2 html "</dd>")))
                                   (else
                                    (html-put 2 html "<dd class=\"dd_keywords\">")
                                    (proc (cdr clause))
                                    (html-put 2 html "</dd>"))))
                            ((list? clause)
                             (for-each (lambda (e) (html-put 2 html "<dt class=\"dt_keywords\">~a~a</dt>" prefix (html-escape e))) clause))
                            ((string? clause)
                             (html-put 2 html "<dd class=\"dd_keywords\">~a</dd>" (apply-link-map (apply-parameter-id-style (html-escape clause)))))
                            (else
                             (assertion-violation 'process-keywords-definition "invalid form" clause))))
                    defs))
        (html-put 0 html "</dl>")))

    (define process-constants-definition
      (lambda (html defs prefix proc)
        (html-put 0 html "<dl class=\"dl_constants\">")
        (let ((prefix (if prefix (format "<span class=dt_constants_prefix>~a</span>" prefix) "")))
          (for-each (lambda (clause)
                      (cond ((and (pair? clause) (memq (car clause) '(:block)))
                             (cond ((cadr clause)
                                    (parameterize ((ht-parameter-id-style (ht-parameter-id-style))
                                                   (current-api-name (cadr clause)))
                                      (html-put 2 html "<dd class=\"dd_constants\">")
                                      (proc (cdr clause))
                                      (html-put 2 html "</dd>")))
                                   (else
                                    (html-put 2 html "<dd class=\"dd_constants\">")
                                    (proc (cdr clause))
                                    (html-put 2 html "</dd>"))))
                            ((list? clause)
                             (for-each (lambda (e) (html-put 2 html "<dt class=\"dt_constants\">~a~a</dt>" prefix (html-escape e))) clause))
                            ((string? clause)
                             (html-put 2 html "<dd class=\"dd_constants\">~a</dd>" (apply-link-map (apply-parameter-id-style (html-escape clause)))))
                            (else
                             (assertion-violation 'process-constant-definition "invalid form" clause))))
                    defs))
        (html-put 0 html "</dl>")))

    (destructuring-match clause
      ((':indent . _)
       (begin
         (html-put 0 html "<div class=\"indent\">")
         (loop clause)
         (html-put 0 html "</div>")))
      ((':abstract text ...)
       (process-abstract html text))
      ((':description caption text ...)
       (process-description html caption text))
      ((':definition type prefix defs ...)
       (case type
         ((:arguments) (process-arguments-definition html defs prefix loop))
         ((:keywords) (process-keywords-definition html defs prefix loop))
         ((:constants) (process-constants-definition html defs prefix loop))
         (else
          (assertion-violation 'process-generic-clause "invalid form" clause))))
      ((':example caption code ...)
       (process-example html caption code))
      ((':separator)
       (html-put 0 html "<hr noshade color=\"#e8e8e8\" size=\"1\">"))
      ((':subsection . _)
       (begin
         (html-put 0 html "<table class=\"subsection_box\" border=\"0\">")
         (html-put 0 html "<tr>")
         (html-put 0 html "<td>")
         (loop clause)
         (html-put 0 html "</td>")
         (html-put 0 html "</tr>")
         (html-put 0 html "</table>")))
      ((':text text ...)
       (begin
         (html-put 0 html "<table class=\"text_box\" border=\"0\">")
         (html-put 0 html "<tr>")
         (html-put 0 html "<td>")
         (for-each (lambda (e) (html-put 2 html "<div>~a</div>" (apply-link-map (apply-parameter-id-style (html-escape e))))) text)
         (html-put 0 html "</td>")
         (html-put 0 html "</tr>")
         (html-put 0 html "</table>")))


      (_
       (assertion-violation 'process-generic-clause "invalid form" clause)))))

(define process-procedure
  (lambda (lst html)
    (let ((return-value "<unspecified>"))
      (destructuring-bind (_ name return-value) (car lst)
        (html-put 0 html "<span id=\"~a\"></span>" name)
        (put-mid-jump-menu html)
        (html-put 0 html "<div class=\"api_head\">Procedure: ~a</div>" (html-escape name))
        (html-put 0 html "<div class=\"api_body\">")
        (parameterize ((current-api-name name))
          (let loop ((lst lst))
            (for-each (lambda (clause)
                        (destructuring-match clause
                          ((':arguments . spec)
                           (begin
                             (ht-parameter-id-style (make-parameter-id-style spec))
                             (html-put 0 html "<table class=\"synopsis_box\" border=\"0\">")
                             (html-put 2 html "<caption class=\"synopsis_box_caption\">syntax:</caption>")
                             (html-put 2 html "<tr>")
                             (html-put 4 html "<td>")
                             (let-values (((front back) (split-arguments spec)))
                               (cond ((null? back)
                                      (html-put 6 html "<div>")
                                      (let ((args (concat-arguments front)))
                                        (if (string=? args "")
                                            (html-put 6 html "(~a)" (current-api-name))
                                            (html-put 6 html
                                                      "(~a <span class=\"synopsis_argument\">~a</span>)"
                                                      (current-api-name)
                                                      args)))
                                      (if (equal? (format "~a" return-value) "unspecified")
                                          (html-put 6 html "<span class=\"synopsis_unspecified\"> =&gt; ~a</span>" (html-escape return-value))
                                          (html-put 6 html "<span class=\"synopsis_retval\"> =&gt; ~a</span>" (html-escape return-value)))
                                      (html-put 6 html "</div>"))
                                     (else
                                      (for-each (lambda (n)
                                                  (let ((args (concat-arguments (append front (list-head back n)))))
                                                    (if (string=? args "")
                                                        (html-put 6 html "<div>(~a)</div>" (current-api-name))
                                                        (html-put 6 html
                                                                  "<div>(~a <span class=\"synopsis_argument\">~a</span>)</div>"
                                                                  (current-api-name)
                                                                  args))))
                                                (iota (+ (length back) 1) 0))
                                      (html-put 6 html "<div><span class=\"synopsis_retval\"> =&gt; ~a</span></div>" (html-escape return-value)))))
                             (html-put 4 html "</td>")
                             (html-put 2 html "</tr>")
                             (html-put 0 html "</table>")
                             (html-put 0 html "<table class=\"param_box\" border=\"0\">")
                             (html-put 2 html "<caption class=\"param_box_caption\">arguments:</caption>")
                             (html-put 2 html "<tr>")
                             (html-put 4 html "<td class=\"param_argument\">")
                             (let ((spec (filter pair? spec)))
                               (for-each (lambda (e) (html-put 6 html "<div>~a:</div>" (html-escape (car e)))) spec)
                               (html-put 4 html "</td>")
                               (html-put 4 html "<td class=\"param_type\">")
                               (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (html-escape (cadr e)))) spec)
                               (html-put 4 html "</td>")
                               (when (exists (lambda (e) (pair? (cddr e))) spec)
                                 (html-put 4 html "<td class=\"param_detail\">")
                                 (for-each (lambda (e)
                                             (if (pair? (cddr e))
                                                 (html-put 6 html "<div>~a</div>" (html-escape (caddr e)))
                                                 (html-put 6 html "<div>&nbsp;</div>")))
                                           spec)
                                 (html-put 4 html "</td>")))
                             (html-put 2 html "</tr>")
                             (html-put 0 html "</table>")))
                          (_
                           (process-generic-clause clause html loop))))
                      (cdr lst))))
        (html-put 0 html "</div>")))))

(define process-parameter
  (lambda (lst html)
    (let ((return-value "<unspecified>"))
      (destructuring-bind (_ name return-value) (car lst)
        (html-put 0 html "<span id=\"~a\"></span>" name)
        (put-mid-jump-menu html)
        (html-put 0 html "<div class=\"api_head\">Parameter: ~a</div>" (html-escape name))
        (html-put 0 html "<div class=\"api_body\">")
        (parameterize ((current-api-name name))
          (let loop ((lst lst))
            (for-each (lambda (clause)
                        (destructuring-match clause
                          ((':arguments . spec)
                           (begin
                             (ht-parameter-id-style (make-parameter-id-style spec))
                             (html-put 0 html "<table class=\"synopsis_box\" border=\"0\">")
                             (html-put 2 html "<caption class=\"synopsis_box_caption\">syntax:</caption>")
                             (html-put 2 html "<tr>")
                             (html-put 4 html "<td>")
                             (html-put 6 html "<div>")
                             (html-put 6 html "(~a <span class=\"synopsis_argument\">~a</span>)" (current-api-name) (concat-arguments spec))
                             (html-put 6 html "<span class=\"synopsis_unspecified\"> =&gt; ~a</span>" (html-escape "unspecified"))
                             (html-put 6 html "</div>")
                             (html-put 6 html "<div>")
                             (html-put 6 html "(~a)" (current-api-name))
                             (html-put 6 html "<span class=\"synopsis_retval\"> =&gt; ~a</span>" (html-escape return-value))
                             (html-put 6 html "</div>")
                             (html-put 4 html "</td>")
                             (html-put 2 html "</tr>")
                             (html-put 0 html "</table>")
                             (html-put 0 html "<table class=\"param_box\" border=\"0\">")
                             (html-put 2 html "<caption class=\"param_box_caption\">arguments:</caption>")
                             (html-put 2 html "<tr>")
                             (html-put 4 html "<td class=\"param_argument\">")
                             (let ((spec (filter pair? spec)))
                               (for-each (lambda (e) (html-put 6 html "<div>~a:</div>" (html-escape (car e)))) spec)
                               (html-put 4 html "</td>")
                               (html-put 4 html "<td class=\"param_type\">")
                               (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (html-escape (cadr e)))) spec)
                               (html-put 4 html "</td>")
                               (when (exists (lambda (e) (pair? (cddr e))) spec)
                                 (html-put 4 html "<td class=\"param_detail\">")
                                 (for-each (lambda (e)
                                             (if (pair? (cddr e))
                                                 (html-put 6 html "<div>~a</div>" (html-escape (caddr e)))
                                                 (html-put 6 html "<div>&nbsp;</div>")))
                                           spec)
                                 (html-put 4 html "</td>")))
                             (html-put 2 html "</tr>")
                             (html-put 0 html "</table>")))
                          (_
                           (process-generic-clause clause html loop))))
                      (cdr lst))))
        (html-put 0 html "</div>")))))


(define process-constant
  (lambda (lst html)
    (destructuring-bind ((_ . names) . clauses) lst
      (for-each (lambda (e) (html-put 0 html "<span id=\"~a\"></span>" e)) names)
      (put-mid-jump-menu html)
;     (html-put 0 html "<div class=\"api_head\">Constants: ~a</div>" (html-escape (concat-objects names ", ")))
;     (html-put 0 html "<div class=\"api_head\">Constants: ~a</div>" (concat-objects (map html-escape names) "<span class=\"const_comma\">,</span> &nbsp;"))

      (html-put 0 html "<div class=\"api_head\">")
      (html-put 0 html "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\">")
      (html-put 2 html "<tr>")
      (html-put 2 html "<td valign=\"top\">")
      (html-put 4 html "Constants:&nbsp;")
      (html-put 2 html "</td>")
      (html-put 2 html "<td class=\"const_word\" valign=\"top\">")
      (html-put 4 html "~a" (concat-objects (map html-escape names) "<span class=\"const_comma\">,</span> "))
      (html-put 2 html "</td>")
      (html-put 2 html "</tr>")
      (html-put 0 html "</table>")
      (html-put 0 html "</div>")

      (html-put 0 html "<div class=\"api_body\">")
      (let loop ((lst lst))
        (for-each (lambda (clause) (process-generic-clause clause html loop)) (cdr lst)))
      (html-put 0 html "</div>"))))

(define process-library
  (lambda (lst html)
    (destructuring-bind ((_ name) . clauses) lst
      (let ((html port-header-part))
        (html-put 0 html "<div class=\"library_head\">Library: ~a</div>" name)
        (html-put 0 html "<div class=\"library_body\">"))
      (let loop ((lst lst))
        (for-each (lambda (clause)
                    (destructuring-match clause
                      ((':link-list)
                       (let ((html port-header-part))
                         #f
                         #;(html-put 0 html "<ul type=\"square\" class=\"library_link_list\">")
                         #;(html-put 2 html
                                   "<li><a href=\"#summaries\">Summaries of ~a library</a></li>"
                                   (current-library-name))
                         #;(html-put 2 html
                                   "<li><a href=\"#exports\">List of identifiers exported from ~a library</a></li>"
                                   (current-library-name))
                         #;(html-put 0 html "</ul>")))
                      ((':exports identifiers ...)
                       (let ((html port-list-of-exported-identifiers))
                         (update-link-map name identifiers)
                         (let ((origin name))
                           (html-put 0 html "<table class=\"exports_parent_box\" border=\"0\" width=\"800\">")
                           (html-put 0 html "<tr>")
                           (html-put 0 html "<td width=\"50%\">")
                           (begin
                             (html-put 0 html "<table class=\"exports_box\" border=\"0\" width=\"100%\">")
                             (html-put 0 html "<caption class=\"exports_box_caption\">Contexual list of all exports:</div>")
                             (let loop ((lst identifiers))
                               (when (pair? lst)
                                 (cond ((pair? (car lst))
                                        (set! origin (car lst))
                                        (loop (cdr lst)))
                                       (else
                                        (cond ((hashtable-ref (ht-toc-dict) (car lst) #f)
                                               => (lambda (dat)
                                                    (list-of-contents (cons (car lst) (list-of-contents)))
                                                    (destructuring-bind (category anchor . _) dat
                                                      (html-put 2 html "<tr>")
                                                      (html-put 4 html "<td>")
                                                      (html-put 6 html "<span class=\"exports_identifier\"><a href=\"#~a\">~a</a></span>" anchor (html-escape (car lst)))
                                                      (html-put 4 html "</td>")
                                                      (unless (equal? origin name)
                                                        (html-put 4 html "<td>")
                                                        (html-put 6 html "<span class=\"exports_origin\">~a</span>" (html-escape origin))
                                                        (html-put 4 html "</td>")
                                                        (html-put 2 html "</tr>"))
                                                      (loop (cdr lst)))))
                                              (else
                                               (html-put 2 html "<tr>")
                                               (html-put 4 html "<td>")
                                               (cond ((hashtable-ref (ht-link-map) (car lst) #f)
                                                      => (lambda (dat)
                                                           (destructuring-bind (_ filename anchor) dat
                                                             (html-put 6 html
                                                                       "<span class=\"exports_identifier\"><a href=\"~a#~a\">~a</a></span>"
                                                                       filename
                                                                       anchor
                                                                       (html-escape (car lst))))))
                                                     (else
                                                      (html-put 6 html "<span class=\"exports_identifier\">~a</span>"(html-escape (car lst)))))
                                               (html-put 4 html "</td>")
                                               (unless (equal? origin name)
                                                 (html-put 4 html "<td>")
                                                 (html-put 6 html "<span class=\"exports_origin\">~a</span>" (html-escape origin))
                                                 (html-put 4 html "</td>"))
                                               (html-put 2 html "</tr>")
                                               (loop (cdr lst))))))))
                             (html-put 0 html "</table>"))
                           (html-put 0 html "</td>")
                           (html-put 0 html "<td width=\"50%\">")
                           (begin
                             (html-put 0 html "<table class=\"exports_index_box\" border=\"0\" width=\"100%\">")
                             (html-put 0 html "<caption class=\"exports_box_caption\">Alphabetical list of all exports:</div>")
                             (let loop ((lst (list-sort (lambda (a b)
                                                          (string<? (format "~a" a) (format "~a" b)))
                                                        (filter (lambda (e) (not (pair? e))) identifiers))))
                               (unless (null? lst)
                                 (cond ((hashtable-ref (ht-toc-dict) (car lst) #f)
                                        => (lambda (dat)
                                             (destructuring-bind (category anchor . _) dat
                                               (html-put 2 html "<tr>")
                                               (html-put 4 html "<td>")
                                               (html-put 6 html "<span class=\"exports_identifier\"><a href=\"#~a\">~a</a></span>" anchor (html-escape (car lst)))
                                               (html-put 4 html "</td>")
                                               (html-put 2 html "</tr>")
                                               (loop (cdr lst)))))
                                       (else
                                        (html-put 2 html "<tr>")
                                        (html-put 4 html "<td>")
                                        (cond ((hashtable-ref (ht-link-map) (car lst) #f)
                                               => (lambda (dat)
                                                    (destructuring-bind (_ filename anchor) dat
                                                      (html-put 6 html
                                                                "<span class=\"exports_identifier\"><a href=\"~a#~a\">~a</a></span>"
                                                                filename
                                                                anchor
                                                                (html-escape (car lst))))))
                                              (else
                                               (html-put 6 html "<span class=\"exports_identifier\">~a</span>"(html-escape (car lst)))))
                                        (html-put 4 html "</td>")
                                        (html-put 2 html "</tr>")
                                        (loop (cdr lst))))))
                             (html-put 0 html "</table>"))
                           (html-put 0 html "</td>")
                           (html-put 0 html "</tr>")
                           (html-put 0 html "</table>"))
                         (list-of-contents (reverse (list-of-contents)))))
                      (_
                       (process-generic-clause clause port-header-part loop))))
                  (cdr lst)))
      (let ((html port-header-part))
        (html-put 0 html "</div>")))))

(define process-macro
  (lambda (lst html)
    (destructuring-bind (_ name return-value) (car lst)
      (html-put 0 html "<span id=\"~a\"></span>" name)
      (put-mid-jump-menu html)
      (html-put 0 html "<div class=\"api_head\">Macro: ~a</div>" (html-escape name))
      (html-put 0 html "<div class=\"api_body\">")
      (parameterize ((current-api-name name))
        (let loop ((lst lst))
          (for-each (lambda (clause)
                      (destructuring-match clause
                        ((':synopsis args . form)
                         (begin
                           (ht-parameter-id-style (make-parameter-id-style-for-synopsis args))
                           (html-put 0 html "<table class=\"synopsis_box_macro\" border=\"0\">")
                           (html-put 2 html "<caption class=\"synopsis_box_caption\">syntax:</caption>")
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td>")
                           (for-each (lambda (e)
                                       (html-put 6 html "<div>~a</div>" (apply-parameter-id-style (html-escape e))))
                                     form)
                           (html-put 4 html "</td>")
                           (html-put 2 html "</tr>")
                           (html-put 0 html "</table>")
                           (ht-parameter-id-style (make-parameter-id-style args))
                           (html-put 0 html "<table class=\"param_box\" border=\"0\">")
                           (html-put 2 html "<caption class=\"param_box_caption\">arguments:</caption>")
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td class=\"param_argument\">")
                           (let ((spec (filter (lambda (e) (case (cadr e) ((:optional-literal :literal) #f) (else e))) args)))
                             (for-each (lambda (e) (html-put 6 html "<div>~a:</div>" (html-escape (car e)))) spec)
                             (html-put 4 html "</td>")
                             (html-put 4 html "<td class=\"param_type\">")
                             (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (html-escape (cadr e)))) spec)
                             (html-put 4 html "</td>")
                             (when (exists (lambda (e) (pair? (cddr e))) spec)
                               (html-put 4 html "<td class=\"param_detail\">")
                               (for-each (lambda (e)
                                           (if (pair? (cddr e))
                                               (html-put 6 html "<div>~a</div>" (html-escape (caddr e)))
                                               (html-put 6 html "<div>&nbsp;</div>")))
                                         spec)
                               (html-put 4 html "</td>"))
                             (html-put 2 html "</tr>")
                             (html-put 0 html "</table>"))))
                        ((':arguments . spec)
                         (begin
                           (ht-parameter-id-style (make-parameter-id-style spec))
                           (html-put 0 html "<table class=\"synopsis_box_macro\" border=\"0\">")
                           (html-put 2 html "<caption class=\"synopsis_box_caption\">syntax:</caption>")
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td>")
                           (let ((spec (filter (lambda (e) (case (cadr e) ((:optional-literal) #f) (else e))) spec)))
                             (html-put 6 html
                                       "<div>(~a <span class=\"synopsis_argument\">~a</span>)</div>"
                                       (current-api-name)
                                       (concat-arguments spec)))
                           (cond ((exists (lambda (e)
                                            (and (memq (cadr e) '(:optional-literal))
                                                 (if (symbol? (car e)) 1 (length (car e)))))
                                          spec)
                                  => (lambda (count)
                                       (if (= count 1)
                                           (html-put 6 html
                                                     "<div>(~a <span class=\"synopsis_argument\">~a</span>)</div>"
                                                     (current-api-name)
                                                     (concat-arguments spec))
                                           (for-each (lambda (c)
                                                       (html-put 6 html
                                                                 "<div>(~a <span class=\"synopsis_argument\">~a</span>)</div>"
                                                                 (current-api-name)
                                                                 (concat-arguments spec c)))
                                                     (iota count))))))
                           (html-put 4 html "</td>")
                           (html-put 2 html "</tr>")
                           (html-put 0 html "</table>")
                           (html-put 0 html "<table class=\"param_box\" border=\"0\">")
                           (html-put 2 html "<caption class=\"param_box_caption\">arguments:</caption>")
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td class=\"param_argument\">")
                           (let ((spec (filter (lambda (e) (case (cadr e) ((:optional-literal) #f) (else e))) spec)))
                             (for-each (lambda (e) (html-put 6 html "<div>~a:</div>" (html-escape (car e)))) spec)
                             (html-put 4 html "</td>")
                             (html-put 4 html "<td class=\"param_type\">")
                             (for-each (lambda (e) (html-put 6 html "<div>~a</div>" (html-escape (cadr e)))) spec)
                             (html-put 4 html "</td>")
                             (when (exists (lambda (e) (pair? (cddr e))) spec)
                               (html-put 4 html "<td class=\"param_detail\">")
                               (for-each (lambda (e)
                                           (if (pair? (cddr e))
                                               (html-put 6 html "<div>~a</div>" (html-escape (caddr e)))
                                               (html-put 6 html "<div>&nbsp;</div>")))
                                         spec)
                               (html-put 4 html "</td>"))
                             (html-put 2 html "</tr>")
                             (html-put 0 html "</table>"))))
                        (_
                         (process-generic-clause clause html loop))))
                    (cdr lst))))
      (html-put 0 html "</div>"))))

(define process-api
  (lambda (lst html)
    (destructuring-match (car lst)
      ((':procedure . _)
       (process-procedure lst html))
      ((':parameter . _)
       (process-parameter lst html))
      ((':macro . _)
       (process-macro lst html))
      ((':library . _)
       (process-library lst html))
      ((':constant . _)
       (process-constant lst html))
      (_
       (assertion-violation 'process-api "invalid form" lst)))))

(define make-toc-dictionary
  (lambda (lst)
    (define extract-constant
      (lambda (names)
        (let ((name (car names)))
          (for-each (lambda (e) (hashtable-set! (ht-toc-dict) e (list ':constant e))) names))))
    (destructuring-match (car lst)
      ((':library name . _)
       (begin
         (current-library-name (format "~a" name))
         (current-library-filename (format "libref.~a.html" (object-list->string name ".")))))
      ((':procedure name . _)
       (hashtable-set! (ht-toc-dict) name (list ':procedure name)))
      ((':parameter name . _)
       (hashtable-set! (ht-toc-dict) name (list ':parameter name)))
      ((':macro name . _)
       (hashtable-set! (ht-toc-dict) name (list ':macro name)))
      ((':constant . names)
       (extract-constant names)))))

(define load-linkmap
  (lambda ()
    (when (file-exists? "linkmap.dat")
      (call-with-port (transcoded-port (open-file-input-port "linkmap.dat") (native-transcoder))
        (lambda (port)
          (let loop ((dat (get-datum port)))
            (unless (eof-object? dat)
              (hashtable-set! (ht-link-map) (car dat) (cdr dat))
              (loop (get-datum port)))))))))

(define save-linkmap
  (lambda ()
    (call-with-port (transcoded-port (open-file-output-port "linkmap.dat" (file-options no-fail)) (native-transcoder))
      (lambda (port)
        (for-each (lambda (dat) (put-datum port dat) (put-char port #\linefeed)) (hashtable->alist (ht-link-map)))))))

(define in (open-string-input-port (get-string-all (current-input-port))))
(define out (make-string-output-port))

(define put-top-jump-menu
  (lambda (html)
    (html-put 0 html "<div class=\"top_jump_menu\">")
    #;(html-put 2 html "<div>")
    #;(html-put 2 html
              "&bull; <a href=\"http://code.google.com/p/ypsilon/\">Project Home</a> \
               &bull; <a href=\"index.html\">Document Home</a> \
               &bull; <a href=\"index.html#master_toc\">Contents</a> \
               &bull; <a href=\"index.html#master_index\">Master Index</a>")
    #;(html-put 2 html
              "&bull; <a href=\"http://code.google.com/p/ypsilon/\">Project Home</a> \
               &bull; <a href=\"index.html\">Document Home</a> \
               &bull; <a href=\"index.html#master_index\">Summaries</a> \
               &bull; <a href=\"index.html#master_toc\">Contents</a>")
    (html-put 2 html
              "&bull; <a href=\"http://code.google.com/p/ypsilon/\">Project Home</a> \
               &bull; <a href=\"index.html\">Document Home</a> \
               &bull; <a href=\"index.html#master_toc\">Contents</a>")
    #;(html-put 2 html "</div>")
    (html-put 0 html "</div>")))

(define put-mid-jump-menu
  (lambda (html)
    (html-put 0 html "<div class=\"jump_menu\">")
    #;(html-put 2 html "<div>")
    #;(html-put 2 html "&bull; <a href=\"index.html#master_toc\">Contents</a> &bull; <a href=\"index.html#master_index\">Master Index</a>")
    #;(html-put 2 html "&bull; <a href=\"index.html#master_toc\">Table of Contents</a>")
    #;(html-put 2 html "</div>")
    #;(html-put 2 html "<div>")
    (html-put 2 html "[<a href=\"javascript:history.back()\">Back</a>]")
    (html-put 2 html "[<a href=\"~a\">Top</a>]" (current-library-filename))
    #;(html-put 2 html "[<a href=\"#summaries\">Summaries</a>]")
    #;(html-put 2 html "</div>")
    (html-put 0 html "</div>")))

;; pass 1 - retrieve links etc
(let ()
  (load-linkmap)
  (let loop ((form (get-datum in)))
    (unless (eof-object? form)
      (destructuring-match form
        ((':api . spec)
         (begin
           (make-toc-dictionary spec)
           (loop (get-datum in))))
        (_
         (assertion-violation #f "invalid form 1" form))))))

;; pass 2 - generate body
(let ()
  (put-top-jump-menu port-header-part)
  (set-port-position! in 0)
  (let loop ((form (get-datum in)))
    (unless (eof-object? form)
      (destructuring-match form
        ((':api . spec)
         (begin
           (process-api spec out)
           (loop (get-datum in))))
        (_
         (assertion-violation #f "invalid form 2" form))))))

;; pass 3 - generate index
(let ()
  (define load-index
    (lambda ()
      (when (file-exists? "index.dat")
        (call-with-port (transcoded-port (open-file-input-port "index.dat") (native-transcoder))
          (lambda (port)
            (let loop ((dat (get-datum port)))
              (unless (eof-object? dat)
                (hashtable-set! ht-subject-index (car dat) (cdr dat))
                (loop (get-datum port)))))))))
  (define save-index
    (lambda ()
      (call-with-port (transcoded-port (open-file-output-port "index.dat" (file-options no-fail)) (native-transcoder))
        (lambda (port)
          (for-each (lambda (dat) (put-datum port dat) (put-char port #\linefeed)) (hashtable->alist ht-subject-index))))))

  (define make-index-record
    (lambda (ht-subject-index lst)
      (define extract-constant
        (lambda (names)
          (let ((name (car names)))
            (for-each (lambda (e) (hashtable-set! ht-subject-index e (list ':constant (current-library-name) #f))) names))))
      (define prettey
        (lambda (name text)
          (let ((text (pregexp-replace (format "^~a " (pregexp-quote (format "~a" name))) text "")))
            (cond ((string-contains text ". ") => (lambda (end) (substring text 0 end)))
                  ((eq? (string-ref text (- (string-length text) 1)) #\.) => (lambda (end) (substring text 0 (- (string-length text) 1))))
                  (else text)))))
      (destructuring-match lst
        (((':procedure name . _) (':abstract text . _) . _)
         (hashtable-set! ht-subject-index name (list ':procedure (current-library-name) (prettey name text))))
        (((':parameter name . _) (':abstract text . _) . _)
         (hashtable-set! ht-subject-index name (list ':parameter (current-library-name) (prettey name text))))
        (((':macro name . _ ) (':abstract text . _) . _)
         (hashtable-set! ht-subject-index name (list ':macro (current-library-name) (prettey name text))))
        (((':constant . names) . _)
         (extract-constant names)))))

  (load-index)
  (set-port-position! in 0)
  (let loop ((form (get-datum in)))
    (unless (eof-object? form)
      (destructuring-match form
        ((':api . spec)
         (begin
           (make-index-record ht-subject-index spec)
           (loop (get-datum in))))
        (_
         (assertion-violation #f "invalid form 1" form)))))
  (save-index))

;; pass 4 - generate subject index
(let ()

  (define make-link
    (lambda (identifier)
      (format "<span class=\"subject_identifier\"><a href=\"#~a\">~a</a></span>"
              identifier
              (html-escape identifier))))

  (define output-library-contents
    (lambda (html lst)
      (html-put 0 html "<div id=\"summaries\"></div>")
      #;(put-mid-jump-menu html)
      #;(html-put 0 html
                "<div class=\"library_head\">Summaries of ~a</a> library</div>"
                (html-escape (current-library-name)))
      (html-put 0 html "<div class=\"library_body\">")
      (html-put 0 html "<table class=\"subject_box\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">")
      (html-put 0 html "<caption class=\"subject_box_caption\">Summaries:</caption>")
      (for-each #;(lambda (e)
                  (destructuring-bind (name type lib . text) e
                    (cond ((eq? type ':constant)
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td class=\"subject_td\">")
                           (html-put 6 html (make-link name))
                           (html-put 4 html "<span class=\"subject_td_na\">")
                           (html-put 6 html (html-escape "<constant>"))
                           (html-put 4 html "</span>")
                           (html-put 4 html "</td>")
                           (html-put 2 html "</tr>"))
                          (else
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td class=\"subject_td\">")
                           (html-put 6 html (make-link name))
                           (html-put 6 html "~a." (html-escape (car text)))
                           (html-put 4 html "</td>")
                           (html-put 2 html "</tr>")))))
                (lambda (e)
                  (destructuring-bind (name type lib . text) e
                    (cond ((eq? type ':constant)
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td class=\"subject_td\" nowrap>")
                           (html-put 6 html (make-link name))
                           (html-put 4 html "</td>")
                           (html-put 4 html "<td class=\"subject_td_na\">")
                           (html-put 6 html (html-escape "<constant>"))
                           (html-put 4 html "</td>")
                           (html-put 2 html "</tr>"))
                          (else
                           (html-put 2 html "<tr>")
                           (html-put 4 html "<td class=\"subject_td\" nowrap>")
                           (html-put 6 html (make-link name))
                           (html-put 4 html "</td>")
                           (html-put 4 html "<td class=\"subject_td\">")
                           (let ((text (string-copy (car text))))
                             (string-set! text 0 (char-upcase (string-ref text 0)))
                             (html-put 6 html "~a" (html-escape text)))
                           (html-put 4 html "</td>")
                           (html-put 2 html "</tr>")))))
                lst)
      (html-put 0 html "</table>")
      (html-put 2 html "<ul type=\"square\" class=\"library_link_list\">")
      (html-put 4 html
                "<li><a href=\"#exports\">List of identifiers exported from ~a library</a></li>"
                (current-library-name))
      (html-put 2 html "</ul>")
      (html-put 0 html "</div>")))
  (let ((lst (map (lambda (id) (cons id (hashtable-ref ht-subject-index id #f))) (list-of-contents))))
      (output-library-contents port-summaries-part lst)))

;; pass 3 - list of exports
(let ()
  (html-put 0 out "<div id=\"exports\"></div>")
  (put-mid-jump-menu out)
  (html-put 2 out
            "<div class=\"library_head\">Identifiers exported from ~a</a> library</div>"
            (current-library-name))
  (html-put 4 out "<div class=\"library_body\">")
  (html-put 0 out (extract-accumulated-string port-list-of-exported-identifiers))
  (html-put 4 out "</div>")
  (html-put 2 out "</div>")
  (put-mid-jump-menu out)
  (save-linkmap))

(call-with-port (transcoded-port (standard-output-port) (make-transcoder (utf-8-codec)))
  (lambda (port)
    (put-string port (extract-accumulated-string port-header-part))
    (put-string port (extract-accumulated-string port-summaries-part))
    (put-string port (extract-accumulated-string out))))

