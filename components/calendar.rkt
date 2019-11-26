#lang at-exp racket

(require website-js)

(define (time-select . content)
   (apply select (flatten
                     (list
                         content
                         class: "custom-select mr-sm-2"
                         (option 'value: "12am" "12am")
                         (option 'value: "1am" "1am")
                         (option 'value: "2am" "2am")
                         (option 'value: "3am" "3am")
                         (option 'value: "4am" "4am")
                         (option 'value: "5am" "5am")
                         (option 'selected: #t 'value: "6am" "6am")
                         (option 'value: "7am" "7am")
                         (option 'value: "8am" "8am")
                         (option 'value: "9am" "9am")
                         (option 'value: "10am" "10am")
                         (option 'value: "11am" "11am")
                         (option 'value: "12pm" "12pm")
                         (option 'value: "1pm" "1pm")
                         (option 'value: "2pm" "2pm")
                         (option 'value: "3pm" "3pm")
                         (option 'value: "4pm" "4pm")
                         (option 'value: "5pm" "5pm")
                         (option 'value: "6pm" "6pm")
                         (option 'value: "7pm" "7pm")
                         (option 'value: "8pm" "8pm")
                         (option 'value: "9pm" "9pm")
                         (option 'value: "10pm" "10pm")
                         (option 'value: "11pm" "11pm")))))

(define (form-row the-label the-input)
 (div class: "form-group row"
  (label class: "col-sm-2 col-form-label" the-label)
  (div class: "col-sm-10"
   the-input)))

(define (new-event-picker
         button-f
         #:callback (callback noop))
  (enclose
   (span
    (button-f 'data-toggle: "modal"
              'data-target: (ns# 'modal))
    (modal id: (ns 'modal)
     (modal-dialog
      (modal-content
       (modal-header
        (modal-title "New Event"))

       (modal-body
        (form-row "Time" (time-select id: (ns "time")))
        (form-row "Name" (input id: (ns "name") type: "text" class: "form-control" 'placeholder: "FunEvent")))

       (modal-footer
        (button-secondary 'data-dismiss: "modal" "Cancel")
        (button-primary on-click: (call 'createEvent)
                        "Create Event"))))))

   (script ([time "8am"]
            [name "Fun event"]
            [nameEl (ns 'name)]
            [timeEl (ns 'time)])
     (function (createEvent)
       (set-var name @js{@getEl{@nameEl}.value}) 
       (set-var time @js{@getEl{@timeEl}.options[@getEl{@timeEl}.selectedIndex].value}) 
       @js{ $('@(ns# 'modal)').modal('hide') }
       (callback name time)))))

(define (day-square day-num 
                    #:active? (active? #t)
                    
                    (events (hash)))
  (enclose
   
   (card
    (card-body 
     (new-event-picker (lambda (content . more)
                         (apply p
                                (flatten
                                 (list
                                  style: (properties
                                          cursor: "pointer"
                                          color: (if active? "black"
                                                     "gray"))
                                  class: "badge badge-pill badge-light"
                                  content more
                                  day-num))))
                       #:callback (callback 'createAndAddEvent)))
    (template id: (ns 'eventTemplate)
             (event #:id (ns 'eventTemplate) "6am" "First Day of Work"))
    (div id: (ns 'events)
         (when (hash-has-key? events day-num)
           (hash-ref events day-num))))

   (script ([events (ns 'events)]
            [eventTemplate (ns 'eventTemplate)])
    (function (addEvent c)
              (inject-component c events))
    (function (createAndAddEvent name time)
             @js{
                 @addEvent(@(instantiate eventTemplate
                                #:then (construct name time)))
                 }))))


(define (day-name n)
  (card 
    class: "bg-success text-white"
    (card-header n)))

(define (calendar month-name
                  #:controls (controls (const ""))
                  (events (hash)))
  (enclose
   (define (normal-day n)
     (day-square n events))

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
        (map normal-day (range 1 7))))

    (define week-2
      (card-group
       (map normal-day (range 7 14))))

    (define week-3
      (card-group
       (map normal-day (range 14 21))))

    (define week-4
      (card-group
       (map normal-day (range 21 28))))

    (define week-5
      (card-group
        (map normal-day (range 28 31))
        (day-square 1 #:active? #f)
        (day-square 2 #:active? #f)
        (day-square 3 #:active? #f)
        (day-square 4 #:active? #f)))

    (card 
     (card-header 
      (h3 month-name))
     (card-body (controls (callback 'addEvent))
                day-names
                week-1 
                week-2
                week-3
                week-4
                week-5))
    (script ([dayTarget (ns 'dayTarget)])
            (function (addEvent day event)
                      (-> @getEl{@dayTarget + day}
                          addEvent
                          event)))))

(define (event time name
               #:id (id "")
               (button-f button-primary)
               #:on-click (cb noop))
  (enclose
   (button-f class: "btn btn-primary btn-block"
             on-click: (cb time name)
             (span (b id: (ns 'timeSpan) time) " " (span id: (ns 'nameSpan) name)))
   (script-id id
              ([nameSpan (ns 'nameSpan)]
               [timeSpan (ns 'timeSpan)])
              (function (construct n t)
                        @js{@getEl{@nameSpan}.innerHTML = n}
                        @js{@getEl{@timeSpan}.innerHTML = t}
                        ))))

   

(define (add-event-controls add-event)
  (enclose
   (span id: (ns 'eventControls)
    )
   (script ([testEvent (ns 'testEvent)]
            [nextEventName ""]
            [nextEventTime ""]) 
           (function (setNameAndTime name time)
                     (set-var nextEventName name)
                     (set-var nextEventTime time)
                     (call 'addEvent))
           (function (addEvent)
                     (add-event
                      @js{Math.floor(Math.random()*30) + 1}
                      )))))



(require website-js/demos/clicker)


;<script src="material-datetime-picker.js" charset="utf-8"></script>

(require racket/runtime-path)

(define-runtime-path here "./calendar/")

(module+ main
  (render (list
           (page material-datetime-picker.css
                 (file->string (build-path here "material-datetime-picker.css")))
           (page material-datetime-picker.js
                 (file->string (build-path here "material-datetime-picker.js")))
           (bootstrap
           
            (page index.html
                  (content 
                   #:head (list
                           (include-css "https://fonts.googleapis.com/icon?family=Material+Icons")
                           (include-css "https://fonts.googleapis.com/css?family=Roboto")
                           (include-css "material-datetime-picker.css")
                           (include-js "https://cdnjs.cloudflare.com/ajax/libs/rome/2.1.22/rome.js")
                           (include-js "https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.17.1/moment.js")
                           (include-js "material-datetime-picker.js"))
                    (js-runtime)
                    (container
                      (card-group
                        (calendar "July"
                                  #:controls add-event-controls 
                                  (hash
                                    5 (event
                                        "2pm"
                                        "Test"
                                        button-danger))
                                  ))
                      )))))
          #:to "out"))

