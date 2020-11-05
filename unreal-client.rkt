#lang racket 

(provide
 (struct-out unreal-js-fragment)
 unreal-eval-js ;Use this from now on
 unreal-js
 
 unreal-call ;deprecating because it assumed non /js endpoints.  But things have been simplified
 )

(require net/uri-codec
         net/http-easy)

(struct unreal-js-fragment (content) #:transparent)

(define (string-or-fragment->string s)
  (if (string? s)
      s
      (unreal-js-fragment-content s)))

(define (unreal-js . ss)
  (unreal-js-fragment
   (string-join (flatten
                 (map string-or-fragment->string
                      ss))
                " ")))

(define (unreal-eval-js js-string-or-fragment)
  (define js (string-or-fragment->string js-string-or-fragment))

  (displayln "************* unreal-eval-js ******************")

  (with-handlers ([exn:fail:network:errno?
                   (lambda (e)
                     (displayln e)
                     (displayln "No World server found at 127.0.0.1:8080.  Trying again in 5 seconds...")
                     (sleep 5)
                     
                     (unreal-eval-js js))
                   ])
    
    (post "127.0.0.1:8080/js"
          #:close? #t
          #:data js)

    (displayln "Sent Magic Across to word: ")
    (displayln js))

  )

(define (unreal-call verb params)
  (displayln "Sending to Unreal...")
  
  (post "127.0.0.1:8080/js"
        #:close? #t
        #:data (hash-ref params 'script))

  (void))

