#lang racket 

(provide
 (struct-out unreal-js-fragment)
 unreal-eval-js ;Use this from now on
 unreal-js
 unreal-server-port
 unreal-call ;deprecating because it assumed non /js endpoints.  But things have been simplified
 )

(require net/uri-codec
         net/http-easy)

(define unreal-server-port (make-parameter 8080))

(struct unreal-js-fragment (content) #:transparent)

(define (string-or-fragment->string s)
  (cond [(string? s) s]
        [(unreal-js-fragment? s) (unreal-js-fragment-content s)]
        [(procedure? s) (string-or-fragment->string (s))]
        [else (error "You passed something that wasn't a string, js-fragment, or procedure into unreal-js")]))

(define (unreal-js . ss)
  (unreal-js-fragment
   (string-join (flatten
                 (map string-or-fragment->string
                      ss))
                "")))

(define (unreal-eval-js . js-strings-or-fragments)
  (define js (string-join (map string-or-fragment->string js-strings-or-fragments) ""))

  (displayln "************* unreal-eval-js ******************")

  (with-handlers ([exn:fail:network:errno?
                   (lambda (e)
                     (displayln e)
                     (displayln (~a "No World server found at 127.0.0.1:" (unreal-server-port) ".  Trying again in 5 seconds..."))
                     (sleep 5)
                     
                     (unreal-eval-js js))
                   ])
    
    (post (~a "127.0.0.1:" (unreal-server-port) "/js")
          #:close? #t
          #:data js)

    (displayln "Sent Magic Across to word: ")
    (displayln js))

  )

(define (unreal-call verb params)
  (displayln "Sending to Unreal...")
  
  (post (~a "127.0.0.1:" (unreal-server-port) "/js")
        #:close? #t
        #:data (hash-ref params 'script))

  (void))

