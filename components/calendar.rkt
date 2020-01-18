#lang at-exp racket

(provide calendar event)

(require website-js
         "./time-select.rkt"
         "./form-row.rkt"
         gregor)

(define (day-square day-num 
                    #:id (id "")
                    #:active? (active? #t)
                    (events (hash)))
  (enclose
   (card id: id class: "dayTarget" 
    (card-body id: (ns 'main)
               (p class: "badge badge-pill badge-light"
                  day-num))
    (div id: (ns 'events)
         (when (hash-has-key? events day-num)
           (hash-ref events day-num))))
   (script ())))


(define (day-name n)
  (card 
    class: "bg-success text-white"
    (card-header n)))

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

    (define week-1-end-wday
      (- 7 (sub1 start-wday)))

    (define week-1 
      (card-group
       (map (thunk* (day-square "" #:active? #f))
            (range start-wday))
       (map normal-day (range 1 week-1-end-wday))))

    (define week-2-end-wday (+ 7 week-1-end-wday))

    (define week-2
      (card-group
       (map normal-day (range week-1-end-wday week-2-end-wday))))

    (define week-3-end-wday (+ 7 week-2-end-wday))

    (define week-3
      (card-group
       (map normal-day (range week-2-end-wday week-3-end-wday))))

    (define week-4-end-wday (+ 7 week-3-end-wday))

    (define week-4
      (card-group
       (map normal-day (range week-3-end-wday week-4-end-wday))))

    (define week-5-end-day
      (days-in-month (->year the-date)
                     (->month the-date)))

    (define week-5-end-wday
      (->wday (date (->year the-date)
                    (->month the-date)
                    week-5-end-day)))

    (define week-5
      (card-group
       (map normal-day (range week-4-end-wday
                              (add1 week-5-end-day)))

       (map (thunk* (day-square "" #:active? #f))
            (range (- 7 (add1 week-5-end-wday))))))

    (card id: (ns 'main) 
     (card-header 
      (h3 month-name))
     (card-body 
      ;(button-danger on-click: (call 'advanceDay) (i class: "fas fa-clock") " Advance")
      day-names
      week-1 
      week-2
      week-3
      week-4
      week-5))
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

