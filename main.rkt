#lang at-exp racket

(provide (all-defined-out)
         (all-from-out website/bootstrap))

(require syntax/parse/define
         website/bootstrap)

;Key concepts:
;  * Minimal amount of javascript language to provide react-like abstractions.  Only compile to that.
;  * Symbols are (currently) used to represent literal javascript code.  'a would be the variable a, '|main();| would be a function call. 
;     May have to change this when it gets slow.
;  * Other values, like strings, are converted to JS values of equivalent types when converted to javasctipt.   "hello" would turn into '|"hello"| when combined with other JS.
;  * Reusable components are a tuple (list HTML JS).  Tools below help keep the JS and HTML identifiers in sync, syntactically nearby, and lexically scoped.

(define (convert-id s)
  (string->symbol
    (string-replace (~a s)
                    "-"
                    "_")))

;Namespace-aware stuff

(define namespace (make-parameter ""))

(define-syntax-rule (with-namespace n stuff ...)
  (parameterize ([namespace n])
    (let () stuff ...)))

(define-syntax-rule (enclose stuff ... html js)
  (with-namespace (gensym 'ns) 
                  stuff 
                  ...
                  (list html js)))

(define (window. name)
  (string->symbol (~a 'window. (namespace) "_" name)))


(define (call fun . args)
  (define name (~a "window." (namespace) "_" fun))

  (string->symbol
    @~a{@name(@params[(map val args)])}))


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

(define (id# s)
  ;No string->symbol because it's for generating HTML ids, and for use with getEl()
  (~a "#" (namespace) "_" s))

;/END Namespace-aware stuff



(define (val x)
  (cond 
    [(string? x) (~s x)]
    [(symbol? x) x]
    [else x]))

(define (statement s)
  (string->symbol
    (~a s ";\n")))


(define (op name a b)
  (string->symbol
    @~a{(@a @name @b)}))

(define (var name val)
  (statement (~a "var " name "=" val)))

(define (set-var name v)
  (statement (~a name "=" (val v))))

(define (get-var name)
  (string->symbol
    (~a name)))


(define (+=! name amount)
  (set-var name (op '+ (get-var name)
                    (val amount))))

(define innerHTML "innerHTML")

(define (dots . things)
  (apply ~a
         (cons
           (if (not (empty? things)) "." "") 
           (add-between (flatten things) "."))) )

(define (getEl id . refs)
  @~a{document.getElementById(@(val id))@(dots refs)})

(define (log s)
  (~a "console.log(" (val s) ")"))


(define on-click: 'onClick:)

(define (html->string element
                      #:keep-script-tags? (keep-script-tags #t))
  (define with-tags
    (string-replace 
      (~s
        (with-output-to-string ;TODO shorten
          (thunk
            (output-xml element))))
      "\n" ""))

  (define fix-end-tags
    (string-replace
      with-tags 
      "</script>" 
      (if keep-script-tags "</scr\"+\"pt>" "")))


  (if keep-script-tags
    fix-end-tags
    (regexp-replaces fix-end-tags 
                     '(
                       [#rx"<script>" ""]
                       [#rx"</script>" ""]
                       [#rx"//<!\\[CDATA\\[" ""] 
                       [#rx"//\\]\\]>" ""]))) )

(define (html->non-script-string e)
  (define no-scripts (scrape-out 'script e))

  (html->string no-scripts))

(define (html->script-string e)
  (define scripts 
    (collect-all 'script e))

  (string-join
    (map (curry html->string #:keep-script-tags? #f)
         scripts)))


(define (alert s)
  (statement @~a{alert(@(val s))}))


(define (js . s)
  (string->symbol
    (string-join 
      (map ~a (flatten s)))))


(define (inject-component id comp)
  (string->symbol
    @~a{
    window.namespace_num = window.namespace_num || 0

    window.namespace_num += 1

    var newNamespace = "ns0000" + window.namespace_num

    var s = @(html->non-script-string comp)
    var oldNamespace = s.match(/(ns\d*)/)[0] //Maybe buggy?  Just grabbing the first thing that looks like a namespace.  Maybe that's usally the component's main namespace and not the callback namespaces??
    
    document.getElementById(@id).innerHTML += s.replace(new RegExp(oldNamespace, "g") , newNamespace)  

    aScript = document.createElement("script") 
    aScript.text = @(html->script-string comp).replace(new RegExp(oldNamespace, "g") , newNamespace) 
    document.getElementById(@id).appendChild(aScript)
    }))


;Syntactic sugarings...

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

(define-syntax-rule (el= the-id chain ... last)
  (set-var (getEl (id 'the-id) 'chain ...) last))

(define-syntax-rule (st= the-id val)
  (set-var the-id val))



(define-syntax-rule (script stuff ...)
  (script/inline
    (state stuff ...)))



(define (wrap f component)
  (list-set component
            0
            (f (first component)))) 


