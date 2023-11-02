(define foo 4)

(defun bar (x y)
    (if (and (numberp x) (numberp y))
        (+ x y)
        (error "x and y must be numbers")))
