#lang at-exp racket

(provide accordion-cards accordion-card)

(require website-js)

(define (accordion-card 
           #:header (header "Click to show")
           #:shown? (shown? #f)
           #:dark? (dark? #f)
           . content)
  (enclose
   (card
    class: (if dark? "bg-secondary" "")
    (card-header
     (button-link class: (if dark? "text-white" "")
                  on-click: (call 'toggle)
       header))
    (div id: (id 'collapse1)
         class: (~a "collapse " (if shown? "show" ""))
      (card-body
       class: (if dark? "text-white" "")
       content)))
   (script ([toToggle (id 'collapse1)])
     (function (toggle)
       @js{$("#"+@toToggle).toggle()}))))

(define (accordion-cards . content)
 (enclose
  (accordion id: (id 'main)
   content)
  (script ())))

(module+ main
  (render (list
           (bootstrap
            (page index.html
                  (content
                    (js-runtime)
                    (include-p5-js)
                    (accordion-cards
                      (accordion-card
                        #:header (p "Click to see!")
                        (p "Now you see!")
                        (p "Click again to hide!")))
                    ))))
          #:to "out"))
