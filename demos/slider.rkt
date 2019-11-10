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
        (div
	  (span id: (id "output")
		class: "badge badge-secondary"
		0))
        (input id: (id "basic") 
	       type: "text"
	       'data-slider-min: 0
	       'data-slider-max: 255
	       'data-slider-step: 1
	       'data-slider-value: 0)
	;Wart: Slider not portable
	(include-js "https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/10.0.0/bootstrap-slider.min.js"))
      (script/inline
         @js{
	      var slider = new Slider("@(id# "basic")", {
		tooltip: 'always'
	      }).on("slide",(x)=>{
                    @(set-var (getEl (id "output") 'innerHTML) 'x)
                    @(on-slide 'x)});
          }))))

(define (slider-on-slide s)
  (slider #:on-tick s))

(define (test)
  (bootstrap
    (page index.html
          (content
            #:head
            ;Wart: Slider not portable
            (include-css "https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/10.0.0/css/bootstrap-slider.min.css")

            (enclose

              (list
                (list
                  (h1 id: (id "main-title") "Sliders")
                  (h2 id: (id "secondary-title") "Cool, huh?")
                  (a href: "https://codepen.io/riyos94/pen/NXBvEX/"
                     "(Original slider code)")
                  (color-picker
                    #:on-change (callback 'main "primary")
                    #:r (curry slider-on-slide)
                    #:g (curry slider-on-slide)
                    #:b (curry slider-on-slide))
                  (color-picker
                    #:on-change (callback 'main "secondary")
                    #:r (curry slider-on-slide)
                    #:g (curry slider-on-slide)
                    #:b (curry slider-on-slide)))

                (script/inline
                  (function 'main '(kind color)
                            @js{
                              if(kind == "primary"){
                              @(set-var (getEl (id "main-title") 'style 'color)
                                        'color) 
                              }
                              if(kind == "secondary"){
                              @(set-var (getEl (id "secondary-title") 'style 'color)
                                        'color) 
                              }
                            })   
                  )))))))

(module+ main
  (render (test) #:to "out"))
