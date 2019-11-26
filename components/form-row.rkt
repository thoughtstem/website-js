#lang at-exp racket

(provide form-row)

(require website-js)

(define (form-row the-label the-input)
 (div class: "form-group row"
  (label class: "col-sm-2 col-form-label" the-label)
  (div class: "col-sm-10"
   the-input)))
