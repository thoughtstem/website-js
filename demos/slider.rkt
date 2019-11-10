#lang at-exp racket

;Exercise in coverting a codepen...
;https://codepen.io/riyos94/pen/NXBvEX/

(require (except-in website/bootstrap var)
         website-js
         "./color-picker.rkt" 
         "./clicker.rkt")

(define (slider #:on-tick (on-slide noop))
  (enclose
    (list
      (list
	(jumbotron class: "text-center"
		   (label "Single slider") 
		   (input id: (id "basic") 
			  type: "text"
			  'data-slider-min: 0
			  'data-slider-max: 100
			  'data-slider-step: 5
			  'data-slider-value: 15))

	(include-js "https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/10.0.0/bootstrap-slider.min.js"))
      (script/inline
         @js{
	      var slider = new Slider("@(id# "basic")", {
		tooltip: 'always'
	      }).on("slide",()=>{@on-slide});
          }))))

(define (slider-on-slide s)
  (slider #:on-tick s))

(define (test)
  (bootstrap
    (page index.html
          (content
            #:head
            (include-css "https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/10.0.0/css/bootstrap-slider.min.css")

            (h1 "Code Pen Conversion: ")
            (a href: "https://codepen.io/riyos94/pen/NXBvEX/"
               "(Original)")

            (color-picker
              #:r (curry slider-on-slide)
              #:g (curry slider-on-slide)
              #:b (curry slider-on-slide))))))

(module+ main
  (render (test) #:to "out"))
