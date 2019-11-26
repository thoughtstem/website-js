#lang at-exp racket

(provide time-select)

(require website-js gregor (only-in gregor/time time=?))

(define (time->option select-time t)
  (define s (~t t "h:mm a"))
  (if (time=? select-time t)
   (option 'selected: #t 
           'value: s s)
   (option 'value: s s)))

(define (make-options #:start (start "00:00:00") 
                      #:inc   (inc 60)
                      #:steps (steps 24)
                      #:selected (selected start))

 (define start-time (iso8601->time start))

 (define times
   (for/list ([i (range steps)])
     (+minutes start-time (* inc i))))

 (map (curry time->option (iso8601->time selected)) times))

(define (time-select 
           #:start (start "00:00:00")
           #:inc   (inc 60)
           #:steps (steps 24)
           #:selected (selected start)
           #:on-change (on-change noop)
           . content)
  (enclose
   (apply select (flatten
                     (list
                         content
                         class: "custom-select mr-sm-2"
                         'onChange: (call 'onChange 'this) 
                         (make-options #:start start 
                                       #:inc inc
                                       #:steps steps
                                       #:selected selected))))
   (script ([time 'null]
            [selectId (ns 'selector)])
     (function (onChange me)
       (set-var time @js{me.options[me.selectedIndex].value})
       (on-change time))
     )))


(module+ test
  (require rackunit)

  (define select (time-select))

  (check-equal? 
    (length (collect-all option select))
    24
    "A default time selector should have 24 hours to select from"))



