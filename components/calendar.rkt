#lang at-exp racket

(provide calendar 
         event)

(require website-js
         "./time-select.rkt"
         "./form-row.rkt"
         gregor)

(define (day-square day-num 
                    #:id (id "")
                    #:active? (active? #t)
                    (events (hash)))
  (enclose
    (card id: id class: (~a "dayTarget" (if (not active?)
                                          " d-none d-sm-block"
                                          ""
                                          )) 
    (card-body id: (ns 'main)
               (p class: "badge badge-pill badge-light"
                  day-num))
    (div id: (ns 'events)
         (when (hash-has-key? events day-num)
           (hash-ref events day-num))))
   (script ())))


(define (day-name n)
  (card 
    class: "bg-success text-white d-none d-sm-block"
    (card-header (span class: "d-sm-none d-md-block" n)
                 (span class: "d-none d-sm-block d-md-none" (substring n 0 1))
                 )))

(define (calendar the-date (events (hash)))
  (define month-name
    (~t the-date "MMMM"))

  (define start-wday
    (->wday the-date))

  (enclose
   (define (normal-day n)
     (day-square #:id (~a (ns 'dayTarget) n) n events))

    (define day-names
      (div
        class: "card-group"
        (day-name "Sun") 
        (day-name "Mon") 
        (day-name "Tue") 
        (day-name "Wed")
        (day-name "Thu") 
        (day-name "Fri") 
        (day-name "Sat")))
      
    (define total-days (days-in-month (->year the-date)
                                      (->month the-date))) 
    
    (define blank-squares (map (thunk* (day-square "" #:active? #f))
                               (range start-wday)))

    (define non-blank-squares 
      (map normal-day (range 1 (add1 total-days)))
      )

    (define all-squares (append blank-squares non-blank-squares))

    (define weeks
      '())
      
    (let loop () 
      (define current-week (if (> 7 (length all-squares))
                             all-squares
                             (take all-squares 7)
                             ))
      (set! all-squares (if (> 7 (length all-squares))
                          '()
                          (drop all-squares 7)
                          ))
      (set! weeks (append weeks
                          (list
                            (card-group
                              (if (= 7 (length current-week))
                                current-week
                                (append current-week (map (thunk* (day-square "" #:active? #f))
                                                          (range (- 7 (length current-week)))
                                                          )) 
                                )
                              ))))
      
      (when (= 7 (length current-week))
        (loop)
        )
      )


    (card id: (ns 'main) 
     (card-header 
      (h3 month-name))
     (card-body 
      ;(button-danger on-click: (call 'advanceDay) (i class: "fas fa-clock") " Advance")
      day-names
      weeks))
    (script ([dayTarget (ns 'dayTarget)]
             [currentDay 0]
             [contruct @js{setTimeout(()=>{@(call 'advanceDay)},1)}])
            (function (advanceDay)
               (set-var currentDay @js{@currentDay + 1})
               @js{
                 document.querySelectorAll("@(id# 'main) .dayTarget").forEach(function(e){ 
                   @(-> 'e setNotCurrent)
                 })
               }
               (-> @getEl{@dayTarget + @currentDay}
                         setCurrent))
            (function (addEvent day event)
                      (-> @getEl{@dayTarget + day}
                          addEvent
                          event)))))

(define (event time name
               (button-f button-primary)
               #:on-click (cb noop))
  (enclose 
   (button-f 
    id: (ns 'main)
    on-click: (call 'clicked)
    (span (b id: (ns 'timeSpan) time) " " (span id: (ns 'nameSpan) name)))
   (script ([nameSpan (ns 'nameSpan)]
            [timeSpan (ns 'timeSpan)]
            [myCb @js{()=>{@(cb @getEl{@main})}}]
            [main (ns 'main)])
           (function (clicked)
             @js{@myCb(@getEl{@main})})
           (function (construct runtimeCallback n t)
             (set-var myCb runtimeCallback)
             @js{@getEl{@nameSpan}.innerHTML = n}
             @js{@getEl{@timeSpan}.innerHTML = t}))))
   

(require website-js/demos/clicker)
(require racket/runtime-path)

(define-runtime-path here "./calendar/")

(module+ main
  (render (list
           (bootstrap
           
            (page index.html
                  (content 
                    (js-runtime)
                    (container
                      (card-group
                        (calendar (date 2020 7))))))))
          #:to "out"))

