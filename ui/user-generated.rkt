#lang at-exp racket

(provide serve-html
         get-last-message
         add-message)

(require (only-in website/bootstrap element->string content)
         json
         web-server/servlet
         web-server/servlet-env
         web-server/http/request-structs)

(define (serve-html req)
  (define html-code
    (extract-binding/single
     'html
     (request-bindings req)))


  ;I cannot for the life of me figure out why this is necessary.
  ;  But for some reason the in-Unreal browser renders a black screen when
  ;  I try to render the html code stored in the ?html= parameter.
  ;It renders anything else -- even code that is ALMOST exactly the same.
  ;  But for some reason, not when it is exactly the same.
  ;Twiddling the namespaces seems to make it happy, so that's what we are doing.
  ;  I can only conclude that this is some kind of bizzare bug in the embedded browser... :(
  (define code-with-namespaces-change
    ;Just stick numbers on the beginning and end...
    (regexp-replace* #px"ns([0-9]+)_" html-code  "ns6969\\16969_"))

  (define full-code-template
    (element->string (content "@HACK")))

  (define full-code (string-replace full-code-template "@HACK"

                                    code-with-namespaces-change
                                    ))

  (response/full
    200 #"Success"
    (current-seconds) TEXT/HTML-MIME-TYPE
    '()
    (list 
      (string->bytes/utf-8 full-code)))

  )

(define messages
  (list))

(define (add-message req)
  (define raw-data (request-post-data/raw req))
  (define body-string (regexp-replace #rx"^data=" (bytes->string/utf-8 raw-data) ""))
  (define json (string->jsexpr body-string))
  (set! messages (cons json messages))
  (response/full
    200 #"Success"
    (current-seconds) APPLICATION/JSON-MIME-TYPE
    '()
    (list 
      (string->bytes/utf-8 "{message: \"hi\"}"))))

(define (get-last-message req)
  (response/full
    200 #"Success"
    (current-seconds) APPLICATION/JSON-MIME-TYPE
    '()
    (list 
      (string->bytes/utf-8 (jsexpr->string (first messages))))))