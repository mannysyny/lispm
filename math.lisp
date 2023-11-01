;; Defining basic logic gates
(defun and-gate (a b)
    (if (and a b) 'true '()))

(defun or-gate (a b)
    (if (or a b) 'true '()))

(defun xor-gate (a b)
    (if (not (equal a b)) 'true '()))

(defun not-gate (a)
    (if a '() 'true))

;; Defining functions for binary addition
(defun add (a b)
    (if (null b) a
            (add (carry a b) (cdr b))))

(defun carry (a b)
    (if (and (null a) (null b)) '()
            (or-gate (and-gate (car a) (car b))
                             (carry (cdr a) (cdr b)))))

;; Define '+' as a wrapper for add function
(defun + (a b)
    (add a b))
