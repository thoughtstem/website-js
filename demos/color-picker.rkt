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
	    (r (call 'change "red")))
          (col
	    (g (call 'change "green")))
          (col
	    (b (call 'change "blue")))))

      (script/inline
        @(set-var (window. 'red) 0)
        @(set-var (window. 'green) 0)
        @(set-var (window. 'blue) 0)

        @js{
          window.@(id 'change) = function (color){
            if(color == "red"){
              @(+=! (window. 'red) 16) 
            }
            if(color == "green"){
              @(+=! (window. 'green) 16) 
            }
            if(color == "blue"){
              @(+=! (window. 'blue) 16) 
            }

              @(set-var
                 (getEl (id "output") 'style 'backgroundColor)
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
