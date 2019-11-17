#lang at-exp racket

(provide clicker
         clicker-maker
         meta-clicker-maker)

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
              @js{document.getElementById(@button).innerHTML = @count} 
              ))))


(define (clicker-maker
          #:on-click (on-click (const "")))
  (enclose
    (define to-make
      (clicker #:on-click (callback 'updateTotal)  ;Ouch: (callback 'inc) is an infinite loop...
               button-primary))

    (define the-button (col to-make))

    (card
      (card-body
        (button-primary on-click: (call 'newClicker)
                        "I make clickers")
        (span 
          class: "badge badge-pill badge-primary"
          id: (id 'total))
        (hr)
        (row id: (id 'target))
        (template id: (id 'template)
                  the-button)
       (button-danger
          on-click: (call 'clearAll)
          "Clear All")))
    (script
      ([target (id 'target)]
       [template (id 'template)] 
       [totalDiv (id 'total)] 
       [total 0]
       [children '|[]|])

      (function (clearAll)
                @js{
                   for(var c of @children) 
                     @(js-call 'c 'clear)  
                 })

      (function (newClicker)
                (inject-component template target)
                @js{ @|children|.push(injected) })


      (function (updateTotal)
                @js{
                @total += 1 
                document.getElementById(@totalDiv).innerHTML = "Total:" + @total
                }
                (on-click total)))))


(define (meta-clicker-maker)
  (enclose
    (define the-clicker-maker 
      (col (clicker-maker
                  #:on-click (callback 'updateTotal))))
    
    
      (card
        (card-body
          (button-primary on-click: (call 'newClicker)
                          "I make clicker-makers")
          (span 
            class: "badge badge-pill badge-primary"
            id: (id 'total))
          (hr)
          (row id: (id 'target))
          (template id: (id 'template)
             the-clicker-maker)))
      (script
         ([target (id 'target)]
          [template (id 'template)] 
          [totalDiv (id 'total)] 
          [total 0])
         (function (newClicker)
           (inject-component template target))
         
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
            (js-runtime)
            (clickertron)
            (clicker-maker)
            (meta-clicker-maker) ))))


(module+ main
  (render (test) #:to "out"))




