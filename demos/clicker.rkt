#lang at-exp racket

(provide clicker
         clicker-maker
         meta-clicker-maker)

;TODO:
;  * Child state affects parent state
;  * Injecting new component at runtime from JS? Works?


(require website-js)

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
          0)))

    (script ([button button-id]
             [count 0]) 
            (function (main)
                      (call 'inc 1))

            (function (inc amount)
                      @js{
                      @count += @amount
                      document.getElementById(@button).innerHTML = @count
                      }
                      (on-click count) ;Cutpoint
                      )) ))


(define (clicker-maker
          #:on-click (on-click (const "")))
  (enclose
    (define to-make
      (clicker #:on-click (callback 'updateTotal)  ;Ouch: (callback 'inc) is an infinite loop...
               button-primary))

    (define the-button 
        (wrap col to-make) )
    
      (card
        (card-body
          (button-primary on-click: (call 'newClicker)
                          "I make clickers")
          (span 
            class: "badge badge-pill badge-primary"
            id: (id 'total))
          (hr)
          (row id: (id 'target))))
      (script
         ([target (id 'target)]
          [totalDiv (id 'total)] 
          [total 0])
         (function (newClicker)
                   (inject-component target the-button))

         (function (updateTotal)
                   @js{
                     @total += 1 
                     document.getElementById(@totalDiv).innerHTML = "Total:" + @total
                   }
                   (on-click total)
                   ))))


(define (meta-clicker-maker)
  (enclose
    (define the-clicker-maker 
      (wrap col (clicker-maker
                  #:on-click (callback 'updateTotal))))
    
    
      (card
        (card-body
          (button-primary on-click: (call 'newClicker)
                          "I make clicker-makers")
          (span 
            class: "badge badge-pill badge-primary"
            id: (id 'total))
          (hr)
          (row id: (id 'target))))
      (script
         ([target (id 'target)]
          [totalDiv (id 'total)] 
          [total 0])
         (function (newClicker)
                   (inject-component target the-clicker-maker))
         
         (function (updateTotal)
                   @js{
                     @total += 1 
                     document.getElementById(@totalDiv).innerHTML = "Total:" + @total
                   })   
         ) ))



(define (clickertron)
  (enclose
    (jumbotron
      id: (id 'jumbo)
      (card-deck
        (jumbotron
          (card-deck
            (clicker button-primary
                     ;Gross.  Requires knowing that amount is the name of the variable in the scope where this call gets injected
                     #:on-click (callback 'main))
            (clicker button-success
                     #:on-click (callback 'main))
            (clicker button-danger
                     #:on-click (callback 'main))))))
    (script
      ([count 0]
       [jumbo (id 'jumbo)])
      (function (main amount)
                @js{
                @count = amount 
                if(@count == 10){
                document.getElementById(@jumbo).style.backgroundColor = "red" 
                }
                })) ))



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




