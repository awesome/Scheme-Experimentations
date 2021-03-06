
Value fields
------------

__Definition__

    (define-request new-customer-request
      (name string #t 1 100)
      (credit-score integer #t 1 10)
      (credit-limit number #f 0.00 10000.00))

- A required name of type string between 1 and 100 characters long
- A required credit score of type integer between the values 1 and 10
- An optional credit limit of type number between the values 0.00 and 10000.00

__Contructor and selectors__

    (define new-customer-request (make-new-customer-request "Alice" 8 5000.00))
    (new-customer-request-name new-customer-request)
    (new-customer-request-credit-score new-customer-request)
    (new-customer-request-credit-limit new-customer-request)

__Validation__

    (validate-new-customer-request
      (make-new-customer-request "Alice" #f 12000.00))

- credit-score-missing
- credit-limit-too-high

__Json representation__

    {
      "name": "Alice",
      "credit-score": 8,
      "credit-limit": 5000.00
    }

Value list fields
-----------------

__Definition__

    (define-request new-product-request
      (sizes list #t 1 5 (size integer #t 1 25))
      (colors list #t 1 10 (color string #t 1 100)))

- A required list of 1 to 5 sizes of type integer between the values of 1 and 25
- A required list of 1 to 10 colors of type string between 1 and 100 characters long

__List validation__

    (validate-new-product-request
      (make-new-product-request
        (list 10 11 12 13 14 15)
        #f))

- sizes-too-many
- colors-missing

__Elements validation__

    (validate-new-product-request
      (make-new-product-request
        (list 10 20 30 #f)
        (list "Green" "Yellow" 1.25)))

- size2-too-high
- size3-missing
- color2-wrong-type

__Json representation__

    {
      "sizes": [10, 11, 12, 13, 14],
      "colors": ["Green", "Yellow", "Blue"]
    }

Subrequest fields
-----------------

__Definition__

    (define-request new-customer-request
      (address new-customer-address-subrequest #t))

    (define-request new-customer-address-subrequest
      (street string #t 1 100)
      (city string #t 1 100)
      (postal-code string #f 1 10))

- A required address subrequest composed of:
 - A required street of type string between 1 and 100 characters long
 - A required city of type string between 1 and 100 characters long
 - An optional postal code of type string between 1 and 10 characters long

__Request validation__

    (validate-new-customer-request
      (make-new-customer-request #f))

- address-missing

__Subrequest validation__

    (validate-new-customer-request
      (make-new-customer-request
        (make-new-customer-address-subrequest
          ""
          "Montreal"
          "H2J 4R1 A124")))

- address-street-too-short
- address-postal-code-too-long

__Json representation__

    {
      "address":
      {
        "street": "123 Sunny Street",
        "city": "Montreal",
        "postal-code": "H2J 4R1"
      }
    }

Subrequest list fields
----------------------

__Definition__

    (define-request new-product-request
      (suppliers list #t 1 3 (supplier new-product-supplier-subrequest #t)))

    (define-request new-product-supplier-subrequest
      (name string #t 1 100)
      (price number #t 0.00 100000.00))

- A required list of 1 to 3 supplier subrequests composed of:
 - A required name of type string between 1 and 100 characters long
 - A required price of type number between 0.00 and 100000.00

__List validation__

    (validate-new-product-request
      (make-new-product-request
        (list
          (make-new-product-supplier-subrequest "Supplier1" 100.00)
          (make-new-product-supplier-subrequest "Supplier2" 200.00)
          (make-new-product-supplier-subrequest "Supplier3" 300.00)
          (make-new-product-supplier-subrequest "Supplier4" 400.00))))

- suppliers-too-many

__Elements validation__

    (validate-new-product-request
      (make-new-product-request
        (list
          "Supplier1"
          (make-new-product-supplier-subrequest "" 200.00)
          (make-new-product-supplier-subrequest "Supplier3" 300000.00))))

- supplier0-wrong-type
- supplier1-name-too-short
- supplier2-price-too-high

__Json representation__

    {
      "suppliers":
      [
        {
          "name": "Supplier1",
          "price": 100.00
        },
        {
          "name": "Supplier2",
          "price": 200.00
        }
      ]
    }
