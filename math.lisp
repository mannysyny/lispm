;; Define basic logic gates
(defun or-gate (a b)
    (or a b))

(defun xor-gate (a b)
    (not (equal a b)))

(defun not-gate (a)
    (not a))

;; Define functions for binary addition
(defun add (a b)
    (if (null b) a
        (add (carry a b) (cdr b))))

(defun carry (a b)
    (if (and (null a) (null b)) '()
        (or-gate (and-gate (car a) (car b))
                 (carry (cdr a) (cdr b))))

;; Define functions for binary subtraction
(defun subtract (a b)
    (if (null b) a
        (subtract (borrow a b) (cdr b))))

(defun borrow (a b)
    (if (and (null a) (null b)) '()
        (and-gate (not-gate (car a)) (borrow (cdr a) (cdr b))))

;; Define '+' and '-' as wrappers for add and subtract functions
(defun + (a b)
    (add a b))

(defun - (a b)
    (subtract a b))
