#lang at-exp racket

(require syntax/parse/define)

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

(define-syntax-rule (enclose stuff ...)
  (with-namespace (gensym 'ns) stuff ...))

(define (window. name)
  (string->symbol (~a 'window. (namespace) "_" name)))

(define (call fun . args)
  (define name (~a (namespace) "_" fun))

  (string->symbol
    @~a{@name(@params[args])}))


(define (params . args)
  @(string->symbol (string-join (add-between (map ~a (flatten args)) ","))))

(define (function name args . body)
  (string->symbol
    @~a{
    function @(~a (namespace) "_" name)(@(params args)){
    @(string-join (map ~a (map statement body)))
    }
    @"\n"}))

(define (id s)
  ;No string->symbol because it's for generating HTML ids, and for use with getEl()
  (~a (namespace) "_" s))

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
  (statement (~a name "=" v)))

(define (get-var name)
  (string->symbol
    (~a name)))


(define (+=! name amount)
  (set-var name (op '+ (get-var name)
                    'amount)))

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

(define noop "")



(define (js/if c t f)
  (string->symbol
    @~a{
      if(@c){
    @(statement t) 
    }else{
      @(statement f) 
    }}))

(define (js/= a b)
  (op '== a b))


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



;Assumes the HTML-then-Script property...
(define (html->non-script-string element)
  (html->string (first element)))

;Assumes the HTML-then-Script property...
(define (html->script-string element)
  (html->string (second element)
                #:keep-script-tags? #f))


;TODO:
;  * Child state affects parent state
;  * Injecting new component at runtime from JS? Works?


(require website/bootstrap)

(define (clicker type 
                 #:max (max 10) 
                 #:on-max (on-max (log "Max Reached")))
  (enclose
    (define button-id    (id "clicker"))
    (define window.count (window. 'count))

    (list
      (card
        (card-body
          (card-title "Click Me")
          (type
            on-click: (call 'main)
            id: button-id
            0)))

      (script/inline
        (statement (log "Mounted Clicker"))
        (statement (set-var window.count 0))
        (function 'main '()
                  (call 'inc 1))

        (function 'inc '(amount)
                  (log "Inc")
                  (+=! window.count 'amount)
                  (set-var (getEl button-id innerHTML)
                           window.count)
                  (js/if (js/= window.count max)
                         on-max
                         noop))))))


(define (inject-component id comp)
  (string->symbol
    @~a{
    document.getElementById("@id").innerHTML = @(html->non-script-string comp)

    aScript = document.createElement("script") 
    aScript.text = @(html->script-string comp)
    document.getElementById("@id").appendChild(aScript)
    }))

(define (clicker-maker)
  (enclose
    (define the-button (clicker button-primary))
    (list
      (div
        (button-primary on-click: (call 'newClicker)
                        "I make clickers")
        (div id: (id "target")))
      (script/inline
        (function 'newClicker '()
                  (inject-component (id "target") the-button))))))


(define (meta-clicker-maker)
  (enclose
    (define the-clicker-maker (clicker-maker))
    (list
      (div
        (button-primary on-click: (call 'newClicker)
                        "I make clicker-makers")
        (div id: (id "target")))
      (script/inline
        (function 'newClicker '()
                  (inject-component (id "target") the-clicker-maker))))))



(define (clickertron)
  (enclose
    (list
      (jumbotron
        id: (id 'jumbo)
        (card-deck
          (jumbotron
            (card-deck
              (clicker button-primary
                       #:on-max (call 'main))
              (clicker button-success
                       #:on-max (call 'main))
              (clicker button-danger
                       #:on-max (call 'main))))))
      (script/inline
        (function 'main '()
                  (set-var (getEl (id 'jumbo) 'style 'backgroundColor)
                           (val "red")))))))



(define (test)
  (list
    (bootstrap-files)
    (page index.html
          (content
            (clickertron)
            (clicker-maker)
            (meta-clicker-maker) ))))


(render (test) #:to "out")











