#lang at-exp racket

(require website-js)

(define (day-square day-num 
                    #:active? (active? #t)
                    (events (hash)))
  (card
    (card-body 
      (p style: (properties
                  color: (if active? "black"
                           "gray"))
         day-num))
    (when (hash-has-key? events day-num)
      (hash-ref events day-num))))


(define (day-name n)
  (card 
    class: "bg-success text-white"
    (card-header n)))

(define (event time name
               (button-f button-primary)
               #:on-click (cb (const "")))
  (button-f class: "btn btn-primary btn-block"
            on-click: (cb time name)
          (span (b time) " " name)))

(define (calendar month-name
                  #:controls (controls (void))
                  (events (hash)))
  (enclose
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

    (define week-1 
      (card-group
        (day-square 31 #:active? #f)
        (day-square 1 events)
        (day-square 2 events)
        (day-square 3 events)
        (day-square 4 events)
        (day-square 5 events)
        (day-square 6 events)))

    (define week-2
      (card-group
        (day-square 7 events) 
        (day-square 8 events)
        (day-square 9 events)
        (day-square 10 events)
        (day-square 11 events)
        (day-square 12 events)
        (day-square 13 events)))

    (define week-3
      (card-group
        (day-square 14 events)
        (day-square 15 events)
        (day-square 16 events)
        (day-square 17 events)
        (day-square 18 events)
        (day-square 19 events)
        (day-square 20 events)))

    (define week-4
      (card-group
        (day-square 21 events)
        (day-square 22 events)
        (day-square 23 events)
        (day-square 24 events)
        (day-square 25 events)
        (day-square 26 events)
        (day-square 27 events)))

    (define week-5
      (card-group
        (day-square 28 events)
        (day-square 29 events)
        (day-square 30 events)
        (day-square 1 #:active? #f)
        (day-square 2 #:active? #f)
        (day-square 3 #:active? #f)
        (day-square 4 #:active? #f)))

    (card 
      (card-header 
        (h3 month-name))
      (card-body
        controls
        day-names
        week-1 
        week-2
        week-3
        week-4
        week-5))
    (script ()
            (function (main)
                      
                      ))))

(require website-js/demos/clicker)

(define (clicker-calendar m)
  (enclose
    (span id: (ns "cal")
          (calendar m
                    #:controls
                    (clicker
                      #:on-click (callback 'main))

                    (hash
                      3 (event "8am"
                               "Meeting"
                               button-success
                               #:on-click
                               (callback 'eventClick))

                      5 (event "2pm"
                               "Exercise"
                               button-danger
                               #:on-click
                               (callback 'eventClick))
                      10 (event "6pm"
                                "Call Mom"
                                #:on-click
                                (callback 'eventClick))))) 
    (script ()
            (function (main)
                      @js{alert("Can we inject a new, clickable event at runtime?")}  
                      )
            (function (eventClick time name)
                      @js{alert(name)}))
    ))


(module+ main
  (render (bootstrap
            (page index.html
                  (content 
                    (container
                      (card-group
                        (clicker-calendar "June")
                        (calendar "July"
                                  (hash
                                    5 (event
                                        "2pm"
                                        "Test"
                                        button-danger))
                                  ))
                      (card-group
                        (calendar "August") 
                        (calendar "September"))
                      (card-group
                        (calendar "October") 
                        (calendar "November"))
                      ))))
          #:to "out"))

