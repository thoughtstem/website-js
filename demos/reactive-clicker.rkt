#lang at-exp racket

(provide clicker)

(require website-js
         (only-in syntax/parse syntax-parse))

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

(define (add-render-call stx)
  (syntax-parse stx
    [(function (name params ...) stuff ...)
     (if (not (eq? #'name #'render))
         #'(function (name params ...)
                     stuff ...
                     (call 'render))
         stx)]))

(define (debug-log stx)
  (syntax-parse stx
    [(function (name params ...) stuff ...)
     (if (not (eq? #'name #'render))
         #'(function (name params ...)
                     stuff ...
                     @js{console.log("DEBUG...")})
         stx)]))

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
           ;Count will propagate into the innerHTML of this span...
           (span id: (id 'count) 0)))))

    (with-cuts (list debug-log add-render-call)
      (script ([button button-id]
               [count 0]) 
              (function (main)
                        (call 'inc 1))

              (function (clear)
                        @js{
                            @count = 0
                            }
                        
                        (call 'render))

              (function (inc amount)
                        @js{
                            @count += @amount
                            }
                        (call 'render)
                        (on-click count) ;Cutpoint
                        )

              (function (render)
                        (insert-updates)))
      )
  ))

(define (test)
  (list
    (bootstrap-files)
    (page index.html
          (content
            (js-runtime)
            (clicker)))))


(module+ main
  (render (test) #:to "out"))




