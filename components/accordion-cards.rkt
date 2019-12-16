#lang at-exp racket

(provide accordion-cards accordion-card)

(require website-js)

(define (accordion-card 
           #:header (header "Click to show")
           #:shown? (shown? #f)
           . content)
  (enclose
   (card
    (card-header 
     (button-link 'data-toggle: "collapse" 'data-target: (id# 'collapse1) header))
    (div id: (id 'collapse1)
         class: (~a "collapse " (if shown? "show" ""))
      (card-body content)))
   (script ())))

(define (accordion-cards . content)
 (enclose
  (accordion id: (id 'main)
   content)
  (script ())))
