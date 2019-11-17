#lang at-exp racket

(provide (all-defined-out)
         (all-from-out website/bootstrap)
	 (all-from-out "./js.rkt"))

(require syntax/parse/define
         website/bootstrap
	 "./js.rkt")

;Key concepts:
;  * Minimal amount of javascript language to provide react-like abstractions.  Only compile to that.
;  * Symbols are (currently) used to represent literal javascript code.  'a would be the variable a, '|main();| would be a function call. 
;     May have to change this when it gets slow.
;  * Other values, like strings, are converted to JS values of equivalent types when converted to javasctipt.   "hello" would turn into '|"hello"| when combined with other JS.

(define (convert-id s)
  ;TODO: Camel casing?
  (string->symbol
    (string-replace (~a s)
                    "-"
                    "_")))


;Namespace-aware stuff

(define namespace (make-parameter ""))

(define-syntax-rule (with-namespace n stuff ...)
  (parameterize ([namespace n])
    (let () stuff ...)))


(define num 0)
(define (next-namespace)
  (set! num (add1 num))
  (string->symbol (~a "ns" num)))

(define-syntax-rule (enclose stuff ... html js)
  (with-namespace (gensym 'ns) 
                  stuff 
                  ...
                  (list html js)))

(define (call fun . args)
  (define name (~a "window." (namespace) "_" fun))

  (string->symbol
    @~a{@name(@params[(map val args)])}))

;For calling on child elements, or anything you have the runtime namespace for
(define (js-call elem fun . args)
  @js{window[getNamespace(@elem) + @(val (~a "_" fun))](@params[(map val args)])})

;Simple currying mechanic
(define (callback fun . args)
  (define name (~a "window." (namespace) "_" fun))

  (lambda (x . xs)
    (define all-args (append args
                             (cons x xs)))
    (string->symbol
      @~a{@name(@params[(map val all-args)])})))

(define (params . args)
  @(string->symbol (string-join (add-between (map ~a (flatten args)) ","))))

(define (function name args . body)
  (string->symbol
    @~a{
    window.@(~a (namespace) "_" name) = function(@(params args)){
    @(string-join (map ~a (map statement body)))
    }
    @"\n"}))

(define (id s)
  ;No string->symbol because it's for generating HTML ids, and for use with getEl()
  (~a  (namespace) "_" s))

(define ns id)

;/END Namespace-aware stuff

(define (val x)
  (cond 
    [(string? x) (~s x)]
    [(symbol? x) x]
    [else x]))

(define (statement s)
  (string->symbol
    (~a s ";\n")))

(define innerHTML "innerHTML")

(define (log s)
  (~a "console.log(" (val s) ")"))

(define on-click: 'onClick:)

;Mostly for at-reader support @js{raw js here}
(define (js . s)
  (string->symbol
    (string-join 
      (map ~a (flatten s)))))

(define (inject-component template target)
  (string->symbol
    @~a{
    var s = document.getElementById(@template).innerHTML
    var oldNamespace = "@(namespace)"

    var content = document.getElementById(@template).content
    var clonedContent = document.importNode(content, true) 
    replaceAllText(clonedContent, /ns\d+/g, newNamespaceKeeping(oldNamespace))

    document.getElementById(@target).appendChild(clonedContent)

    window.injected = document.getElementById(@target).lastChild 
    }))


;Syntactic sugarings...

(define (window. name)
    (string->symbol (~a 'window. (namespace) "_" name)))

(define (set-var name v)
    (statement (~a name "="  (val v))))

(define (get-var name)
    (string->symbol
          (~a name)))

(define-syntax-rule (state ([k v] ...)
                           (function (name ps ...) statements ...) ...)
  (let ([k (window. 'k)]
        ...)
    (list
      (set-var k v)
      ...
      (let ([ps 'ps] ...)
        (function 'name '(ps ...)
                  statements ...)) 
      ... )))

(define-syntax-rule (script stuff ...)
  (script/inline
    (state stuff ...)))



