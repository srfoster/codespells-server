#lang racket 

(provide unreal-call)

(require net/uri-codec)

(define (unreal-call verb params)
  ;TODO: Don't use curl... (Figure out how to make the rackety way faster... Debugging disabled?)
  (define curl
    (~a "curl \"http://localhost:8080/" verb (hash->params params) "\""))
  (system curl))

(define (hash->params h)
  (define ks (hash-keys h))

  (~a "?"
      (string-join
       (map (lambda (k)
              (~a k "=" (uri-encode (~a (hash-ref h k)))))
            ks)
       "&")))
