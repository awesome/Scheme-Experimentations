
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; response definition

(define-syntax define-response
  (er-macro-transformer
    (lambda (exp rename compare)

      ;; whether a symbols contains a string
      (define (symbol-contains? symbol string)
        (string-contains (symbol->string symbol) string))

      ;; whether a field is a value field
      (define (value-field? field)
        (eq? (length field) 1))

      ;; whether a field is a value list field
      (define (value-list-field? field)
        (and (eq? (length field) 2)
             (eq? (cadr field) 'list)))

      ;; whether a field is a subresponse field
      (define (subresponse-field? field)
        (and (eq? (length field) 2)
             (symbol-contains? (cadr field) "subresponse")))

      ;; whether a field is a subresponse list field
      (define (subresponse-list-field? field)
        (and (eq? (length field) 3)
             (eq? (cadr field) 'list)
             (symbol-contains? (caddr field) "subresponse")))

      ;; json formats a value field
      (define (json-format-value-field field)
        (let* ((field-symbol (car field))
               (field-symbol-string (symbol->string field-symbol)))
          `(json-format-value
            json-object
            ,field-symbol-string
            (json-downgrade-value ,field-symbol))))

      ;; json formats a value list field
      (define (json-format-value-list-field field)
        (let* ((field-symbol (car field))
               (field-symbol-string (symbol->string field-symbol)))
          `(json-format-value-list
            json-object
            ,field-symbol-string
            ,field-symbol)))

      ;; json formats a subresponse field
      (define (json-format-subresponse-field field)
        (let* ((field-symbol (car field))
               (field-symbol-string (symbol->string field-symbol))
               (field-subresponse-type (cadr field)))
          `(json-format-subresponse
            json-object
            ,field-symbol-string
            ,field-symbol
            ,(symbol-append 'json-format- field-subresponse-type))))

      ;; json formats a subresponse list field
      (define (json-format-subresponse-list-field field)
        (let* ((field-symbol (car field))
               (field-symbol-string (symbol->string field-symbol))
               (field-subresponse-type (caddr field)))
          `(json-format-subresponse-list
            json-object
            ,field-symbol-string
            ,field-symbol
            ,(symbol-append 'json-format- field-subresponse-type))))

      ;; parses the expression
      (let* ((response-symbol (cadr exp))
             (fields (cddr exp))
             (fields-symbol (map car fields)))
        `(begin

          (use srfi-1)

          (declare (uses json-convert))
          (declare (uses json-format))

          ;; encapsulates a response
          (define-record ,response-symbol ,@fields-symbol)

          ;; formats a response
          (define (,(symbol-append 'json-format- response-symbol) ,response-symbol json-object)
            ,(if (not (null? fields))
              `(let (
                ,@(map
                  (lambda (field-symbol)
                    `(,field-symbol (,(symbol-append response-symbol '- field-symbol) ,response-symbol)))
                  fields-symbol))
                ,@(map
                  (lambda (field)
                    (cond ((value-field? field)
                           (json-format-value-field field))
                          ((value-list-field? field)
                           (json-format-value-list-field field))
                          ((subresponse-field? field)
                           (json-format-subresponse-field field))
                          ((subresponse-list-field? field)
                           (json-format-subresponse-list-field field))))
                  fields))
              `#f)))))))
