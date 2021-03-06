
(use srfi-1)

(declare (unit validation))

(declare (uses datetime))

;; validates a boolean
(define (validate-boolean value)
  (cond ((not (boolean? value)) 'wrong-type)
        (else #f)))

;; validates a date
(define (validate-date value required)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (date? value)) 'wrong-type)
        ((not (date-valid? value)) 'invalid)
        (else #f)))

;; validates a datetime
(define (validate-datetime value required)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (datetime? value)) 'wrong-type)
        ((not (datetime-valid? value)) 'invalid)
        (else #f)))

;; validates an integer
(define (validate-integer value required min-value max-value)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (and (integer? value) (exact? value))) 'wrong-type)
        ((< value min-value) 'too-low)
        ((> value max-value) 'too-high)
        (else #f)))

;; validates a number
(define (validate-number value required min-value max-value)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (number? value)) 'wrong-type)
        ((< value min-value) 'too-low)
        ((> value max-value) 'too-high)
        (else #f)))

;; validates a string
(define (validate-string value required min-length max-length)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (string? value)) 'wrong-type)
        ((< (string-length value) min-length) 'too-short)
        ((> (string-length value) max-length) 'too-long)
        (else #f)))

;; validates a time
(define (validate-time value required)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (time? value)) 'wrong-type)
        ((not (time-valid? value)) 'invalid)
        (else #f)))

;; validates a list
(define (validate-list value required min-length max-length)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (list? value)) 'wrong-type)
        ((< (length value) min-length) 'too-few)
        ((> (length value) max-length) 'too-many)
        (else #f)))

;; validates a record
(define (validate-record value required record-type-validation-procedure)
  (cond ((not value) (if (not required) #f 'missing))
        ((not (record-type-validation-procedure value)) 'wrong-type)
        (else #f)))

;; maps a validation procedure to the elements of a list
(define (map-validation-procedure value element-symbol validation-procedure)
  (concatenate
    (map
      (lambda (index)
        (let* ((index-symbol (string->symbol (number->string index)))
               (element-symbol-indexed (symbol-append element-symbol index-symbol))
               (element-value (list-ref value index)))
          (validation-procedure element-symbol-indexed element-value)))
      (iota (length value)))))

;; validates a list and its elements
(define 
  (validate-list-and-elements
    field-prefix
    field-symbol
    field-value
    field-required
    field-min-length
    field-max-length
    element-field-symbol
    element-field-validation-procedure)
  (let ((validation-error
          (validate-list
            field-value
            field-required
            field-min-length
            field-max-length)))
    (if validation-error
      (list (symbol-append field-prefix field-symbol '- validation-error))
      (if field-value
        (map-validation-procedure
          field-value
          element-field-symbol
          element-field-validation-procedure)
        '()))))

;; validates a value
(define
  (validate-value
    field-prefix
    field-symbol
    field-value
    field-validation-procedure
    field-validation-parameters)
  (let ((validation-error
          (apply
            field-validation-procedure
            field-value
            field-validation-parameters)))
    (if validation-error
      (list (symbol-append field-prefix field-symbol '- validation-error))
      '())))

;; validates a value list
(define
  (validate-value-list
    field-prefix
    field-symbol
    field-value
    field-required
    field-min-length
    field-max-length
    element-field-symbol
    element-field-validation-procedure
    element-field-validation-parameters)
  (validate-list-and-elements
    field-prefix
    field-symbol
    field-value
    field-required
    field-min-length
    field-max-length
    element-field-symbol
    (lambda (element-field-symbol-indexed element-field-value)
      (validate-value
        field-prefix
        element-field-symbol-indexed
        element-field-value
        element-field-validation-procedure
        element-field-validation-parameters))))

;; validates a subrequest
(define
  (validate-subrequest
    field-prefix
    field-symbol
    field-value
    field-required
    field-type-validation-procedure
    field-validation-procedure)
  (let ((validation-error
          (validate-record
            field-value
            field-required
            field-type-validation-procedure)))
    (if validation-error
      (list (symbol-append field-prefix field-symbol '- validation-error))
      (if field-value
        (let ((nested-field-prefix (symbol-append field-prefix field-symbol '-)))
          (field-validation-procedure field-value nested-field-prefix))
        '()))))

;; validates a subrequest list
(define
  (validate-subrequest-list
    field-prefix
    field-symbol
    field-value
    field-required
    field-min-length
    field-max-length
    element-field-symbol
    element-field-required
    element-field-type-validation-procedure
    element-field-validation-procedure)
  (validate-list-and-elements
    field-prefix
    field-symbol
    field-value
    field-required
    field-min-length
    field-max-length
    element-field-symbol
    (lambda (element-field-symbol-indexed element-field-value)
      (validate-subrequest
        field-prefix
        element-field-symbol-indexed
        element-field-value
        element-field-required
        element-field-type-validation-procedure
        element-field-validation-procedure))))

;; raises an exception caused by a validation error
(define (abort-validation-error validation-error)
  (abort-validation-errors (list validation-error)))

;; raises an exception caused by validation errors
(define (abort-validation-errors validation-errors)
  (let ((condition (make-property-condition 'validation 'errors validation-errors)))
    (abort condition)))

;; returns whether an exception was caused by validation errors
(define (validation-exception? exception)
  ((condition-predicate 'validation) exception))

;; returns the validation errors from an exception
(define (validation-errors exception)
  ((condition-property-accessor 'validation 'errors) exception))

;; validates a request
(define (validate-request request validate-request-procedure)
  (let ((validation-errors (validate-request-procedure request)))
    (when (not (null? validation-errors))
      (abort-validation-errors validation-errors))))
