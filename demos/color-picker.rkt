#lang at-exp racket

(provide color-picker)

(require website-js
         "./clicker.rkt")


(define (clicker-on-click kind c)
  (curry clicker 
         #:on-click c))

(define (color-picker
          #:on-change (on-change (const ""))
          #:r (r (curry clicker-on-click button-danger))
          #:g (g (curry clicker-on-click button-success))
          #:b (b (curry clicker-on-click button-primary)))
  (enclose
    (define output-id (id 'output))

    (jumbotron
      id: output-id
      style: (properties background-color: "rgb(0,0,0)")
      (row
        (col
          (r (callback 'change "red")))
        (col
          (g (callback 'change "green")))
        (col
          (b (callback 'change "blue")))))

    (list
      (script ([red 0]
               [green 0]
               [blue 0]
               [output output-id])
              (function (change color amount)
                        @js{
                        if(@color == "red"){
                        @red = @amount 
                        }
                        if(@color == "green"){
                        @green = @amount
                        }
                        if(@color == "blue"){
                        @blue = @amount
                        }

                        var newColor = "rgb(" + @red + "," + @green + "," + @blue + ")"; 

                        document.getElementById(@output).style.backgroundColor = newColor;

                        @(on-change 'newColor)
                        }
                        ))) ))

(define (picker-maker)
  (enclose
    (define to-make (color-picker))

      (card
        (card-body
          (button-primary on-click: (call 'newClicker)
                          "I make pickers")
          (hr)
          (row id: (id 'target))
          (element 'template
                   id: (id 'template)
            (color-picker))))
      (list
        (script
          ([target (id 'target)]
           [template (id 'template)])
          (function (newClicker)
                    (inject-component
                      (id 'template)
                      (id 'target)))))))


(define (test)
  (bootstrap
    (page index.html
          (content
            (js-runtime)
            (h1 "Color Picker Demo")
            (color-picker)
            (picker-maker)))))

(module+ main
  (render (test) #:to "out"))
