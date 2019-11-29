#lang at-exp racket

(provide gradient)

(require website-js)

(define (gradient . content)
 (enclose
  (div
    @style/inline{
      @(id# 'main) {
	background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
	background-size: 400% 400%;
	animation: gradientBG 15s ease infinite;
      }

      @"@"keyframes gradientBG {
              0% {
                      background-position: 0% 50%;
              }
              50% {
                      background-position: 100% 50%;
              }
              100% {
                      background-position: 0% 50%;
              }
      }
    }
    (apply div (flatten (list id: (id 'main) content))))
  (script ())))

(module+ main
  (render (list
           (bootstrap
            (page index.html
                  (content 
                    (js-runtime)
                    (gradient class: "p-5"
                      (button-primary "HI") 
                      (button-success "HI") 
                      (button-warning "HI") 
                      (button-danger "HI") 
                      )))))
          #:to "out"))
