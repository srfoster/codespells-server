#lang racket 

(provide
 unreal-eval-js ;Use this from now on

 
 unreal-call ;deprecating because it assumed non /js endpoints.  But things have been simplified
 )

(require net/uri-codec
         net/http-easy)


(define (unreal-eval-js js)

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

