#lang at-exp racket

(provide clicker)

(require website-js
         (only-in syntax/parse syntax-parse))


;Prototype reactive framework

(define things-to-update '())

(define (sync-html #:with var elem)
  (define id (get-attribute 'id: elem))
  (define update-me
    @js{@getEl{"@id".trim()}.innerHTML = @(ns var)})
  (set! things-to-update (cons
                          update-me
                          things-to-update))

  elem) 

(define (insert-updates)
  (define ret things-to-update)

  (set! things-to-update '())

  (string-join (map ~a ret) ";\n"))


(define (add-render-call f-name)
  (if (not (eq? f-name 'render))
      (call 'render)
      ""))

(define-syntax-rule (syncing-script stuff ...)
  (with-cuts (list add-render-call)
    (script stuff ...
            (function (render)
                      (insert-updates)))))






;User code



(define (clicker (type button-primary) 
                 #:on-click (on-click (const "")))
  (enclose
   (define button-id    (id 'clicker))

   (card
    (card-body
     (card-title "Click Me")
     (type
      on-click: (call 'main)
      id: button-id
      (sync-html #:with 'count 
                 ;Count will propagate into the innerHTML of this span
                 ; on every call to render()...
                 (span id: (id 'count) 0)))))
   
   ;syncing-script adds a hidden render function and hidden calls to it
   ;  after every other function....  But that's a bit buggy.  
   ;Maybe the convention should be to call render at the end of any function that doesn't end in a return...?  Or maybe it should be after every state change (detect with set-var?).
   ;Or better yet: we can keep track of the stack of calls into any of these functions and call render() after the stack is empty (i.e. all possible state changes have occurred).
   (syncing-script ([button button-id]
                    [count 0]) 
                   (function (main)
                             (call 'inc 1))

                   (function (clear)
                             @js{
                               @count = 0
                             })

                   (function (inc amount)
                             @js{
                               @count += @amount
                             }
                             (on-click count)))))

(define (test)
  (list
   (bootstrap-files)
   (page index.html
         (content
          (js-runtime)
          (clicker)))))


(module+ main
  (render (test) #:to "out"))




