#lang at-exp racket

(provide clicker)

;TODO:
;  * Child state affects parent state
;  * Injecting new component at runtime from JS? Works?


(require website/bootstrap
         (except-in website-js var) )

(define (clicker (type button-primary) 
                 #:max (max 10) 
                 #:on-max (on-max '|console.log(amount)|)
                 #:on-click (on-click '|console.log(amount)|))
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
                  @(on-click 'amount)
                  (+=! window.count 'amount)
                  (set-var (getEl button-id innerHTML)
                           window.count)
                  (js/if (js/= window.count max)
                         @on-max
                         noop))))))


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
	                         ;Gross.  Requires knowing that amount is the name of the variable in the scope where this call gets injected
                       #:on-max (call 'main 'amount))
              (clicker button-success
                       #:on-max (call 'main 'amount))
              (clicker button-danger
                       #:on-max (call 'main 'amount))))))
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


(module+ main
  (render (test) #:to "out"))




