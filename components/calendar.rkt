#lang at-exp racket

(require website-js "./time-select.rkt" "./form-row.rkt")

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
                    #:id (id "")
                    #:active? (active? #t)
                    (events (hash)))
  (enclose
   (card id: id class: "dayTarget" 
    (card-body id: (ns 'main)
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
            [eventTemplate (ns 'eventTemplate)]
            [main (ns 'main)])
    (function (setCurrent)
              @js{$(@(getEl main)).addClass("bg-danger")})
    (function (setNotCurrent)
              @js{$(@(getEl main)).removeClass("bg-danger")})
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

(define (calendar month-name (events (hash)))
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

    (card id: (ns 'main) 
     (card-header 
      (h3 month-name))
     (card-body 
      (button-danger on-click: (call 'advanceDay) (i class: "fas fa-clock") " Advance")
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
                        (calendar "July")))))))
          #:to "out"))

