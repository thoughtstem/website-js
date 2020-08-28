#lang at-exp web-server ;Made this webserver lang so things serialize appropriately across continuations.

(provide (except-out (all-defined-out) state) 
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

(define namespace (make-web-parameter ""))

(define-syntax-rule (with-namespace n stuff ...)
  (web-parameterize ([namespace n])
    (let () stuff ...)))


(define num 0)
(define (next-namespace)
  (set! num (add1 num))
  (string->symbol (~a "ns" num)))

(define (call fun . args)
  (define name (~a "window." (namespace) "_" fun))

  (string->symbol
    @~a{@name(@params[(map val args)])}))

;Deprecated: Use (call-method ) instead
(define-syntax-rule (-> elem fun args ...)
  @js{window[getNamespace(@elem) + @(val (~a "_" 'fun))](@params[(map val (list args ...))])}
  )

(define (call-method elem fun-name . args)
  @js{
  (function(){
  var funName =  @elem .getAttribute("data-ns") + @(val (~a "_" @fun-name))
  return window[funName](@params[(map val args)])
  })()
  }
  )

;Simple currying mechanic
(define (callback fun . args)
  (define name (~a "window." (namespace) "_" fun))

  (define (the-fun . xs)
    (define all-args (append args xs))
    (string->symbol
      @~a{@name(@params[(map val all-args)])}))

  the-fun)

(define (params . args)
  @(string->symbol (string-join (add-between (map ~a (flatten args)) ","))))


(provide with-cuts)
(define cuts (make-parameter '()))


(define (do-end-cuts f-name)
  (string-join (map (compose ~a
                             (lambda (c)
                               (c f-name))) (cuts))
               ";\n"))

(define-syntax-rule (with-cuts c stuff ...)
  (parameterize ([cuts (append (cuts) c)])
    stuff ...))

(define (function name args . body)
  (string->symbol
    @~a{
    window.@(~a (namespace) "_" name) = function(@(params args)){
    @(string-join (map ~a (map statement body)))
    @(do-end-cuts name)
    }
    @"\n"}))


(define (id s)
  ;No string->symbol because it's for generating HTML ids, and for use with getEl()
  (~a  (namespace) "_" s))

(define (id# s)
  ;No string->symbol because it's for generating HTML ids, and for use with getEl()
  (~a  "#" (namespace) "_" s))

(define ns id)
(define ns# id#)

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

;Make this take dom objects and strings alike
;Deprecated: use html->js-injector, which does not require template nonsense or the special runtime
(define (inject-component template target)
  (string->symbol
    @~a{
     injectComponent(@template, @target, "@(namespace)");
    }))


;Syntactic sugarings...

(define (window. name)
    (string->symbol (~a 'window. (namespace) "_" name)))

(define (set-var name v)
    (statement (~a name "="  (val v))))

(define (get-var name)
    (string->symbol
          (~a name)))


(define-syntax-rule (enclose stuff ... html js)
  (with-namespace (gensym 'ns) 
                  stuff 
                  ...
                  (list (add-namespace-attribute html) js)))

(define (add-namespace-attribute elem)
  (local-require website/util)
  (set-attribute elem 'data-ns: (namespace)))

;Abstraction barriers
(define (enclosed-html e) 
  (if (list? e)
      (first e)
      e))
(define (enclosed-js e) 
  (if (list? e)
      (let ()
	(define with-tags
	  (~a
	    (with-output-to-string ;TODO shorten
	      (thunk
		(output-xml (second e))))))

	;Hmmm, may have problems if scripts contain <script> tags,
	;  might want to only get the first and last ones.
	(regexp-replaces
	  with-tags
	  '([#rx"<script>" ""]
	    [#rx"</script>" ""]
	    [#rx"//<!\\[CDATA\\[" ""] 
	    [#rx"//\\]\\]>" ""])))
      ""))


(define-syntax-rule (state ([k v] ...)
                           (function (name ps ...) statements ...) ...)
  (let ([k (window. 'k)]
        ...)
    (list
      (let ([ps 'ps] ...
            [name (window. 'name)] ...)
        (function 'name '(ps ...)
                  statements ...))
      ... 
      ;Putting state vars after functions allows for "constructors" in the form of variables that call previously defined functions.
      (set-var k v)
      ...)))

(define-syntax-rule (script stuff ...)
   (script/inline
    (state stuff ...)))


;Hack for now
(define-syntax-rule (script-id id stuff ...)
  (script/inline id: id
    (state stuff ...)))

(define (html->string element
                      #:keep-script-tags? (keep-script-tags #f))
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
      (if keep-script-tags "</scri\"+\"pt>" "")))


  (if keep-script-tags
    fix-end-tags
    (regexp-replaces fix-end-tags 
                     '(
                       [#rx"<script>" ""]
                       [#rx"</script>" ""]
                       [#rx"//<!\\[CDATA\\[" ""] 
                       [#rx"//\\]\\]>" ""]))) )


(define-syntax-rule (instantiate id #:then (meth ps ...))
  @js{
      (function(){
        var e = @(getEl id);
        e.afterInject = function(e){@(-> 'e meth ps ...)};
        return e;
      }())
   })

(define noop (const ""))

;DOM Helpers

(define (getEl . stuff)
  @js{document.getElementById(@stuff)})

(define (~j template . args)
  (~s
    (string-replace
      (apply format template args)
      "NAMESPACE" (~a (namespace)))))


;An injector is a JS function that takes an injection DOM target, and
;  injects a newly instatiated DOM enclosure there,
;  Freshens up the namespaces for that enclosure and all child enclosures
;  evals the JS code associated with that enclosure
(define (html->js-injector e)
  (define the-html (enclosed-html e))
  (define the-js (enclosed-js e))

  @js{
    function(target){
      var element = document.implementation.createHTMLDocument()
      element.body.innerHTML = @(string-replace
				  (~s (element->string e))
				  "</script>"
				  "</scri\"+\"pt>")
      

      var nonScripts = Array.from(element.body.querySelectorAll(':not(script)'))
      var nameSpaces = nonScripts.map((ns)=>ns.getAttribute("data-ns")).filter((i)=>i)

      //Now redo element with the right namespace
      //  Fixes the script tags too

      if(!window.namespaceMappingIndex){
        window.namespaceMappingIndex = 0
      }

      window.namespaceMappingIndex += 1

      nameSpaces.map((ns)=>{
		     var Nns = "N"+ window.namespaceMappingIndex + ns
		     element.body.innerHTML = element.body.innerHTML.replace(new RegExp(ns, "g"),Nns) 
		     })

      //Now that the enclosures are in the DOM, eval the scripts

      var scripts = Array.from(element.body.getElementsByTagName('script')).map((s)=>s.innerHTML)


      var e = element.body.children.item(0) //Should only be one, aside from the script
      var ret = target.appendChild(e)

      for (var n = 0; n < scripts.length; n++){
        var s = scripts[n]
        eval(s)
      }

      return ret
    }
  })
