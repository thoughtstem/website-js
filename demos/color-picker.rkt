#lang at-exp racket

(provide color-picker)

(require (except-in website/bootstrap var)
         website-js
         "./clicker.rkt")


(define (clicker-on-click kind c)
  (curry clicker 
	 #:max 255
	 #:on-click c))

(define (color-picker
           #:on-change (on-change noop)
           #:r (r (curry clicker-on-click button-danger))
           #:g (g (curry clicker-on-click button-success))
           #:b (b (curry clicker-on-click button-primary)))
  (enclose
    (list
      (jumbotron
        id: (id "output")
        style: (properties background-color: "rgb(0,0,0)")
        (row
          (col
	    (r (callback 'change "red")))
          (col
	    (g (callback 'change "green")))
          (col
	    (b (callback 'change "blue")))))

      (script/inline
        @(set-var (window. 'red) 0)
        @(set-var (window. 'green) 0)
        @(set-var (window. 'blue) 0)

        @js{
          window.@(id 'change) = function (color, amount){
            if(color == "red"){
              @(set-var (window. 'red) 'amount) 
            }
            if(color == "green"){
              @(set-var (window. 'green) 'amount) 
            }
            if(color == "blue"){
              @(set-var (window. 'blue) 'amount) 
            }

              @(set-var
                 (getEl (id "output") 'style 'backgroundColor)
                 @js{
                   "rgb(" + @(window. 'red) + "," + @(window. 'green) + "," + @(window. 'blue) + ")"
                 })

              @(on-change 
                 @js{
                   "rgb(" + @(window. 'red) + "," + @(window. 'green) + "," + @(window. 'blue) + ")"
                 })
         }
        }))))

(define (test)
  (bootstrap
    (page index.html
          (content
            (h1 "Color Picker Demo")
            (color-picker)))))

(module+ main
  (render (test) #:to "out"))
