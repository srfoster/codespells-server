#lang racket

(provide set-next-lore-to-show!
         show-lore-page)

(require webapp/js
         webapp/server/util/responses
         )

(define next-lore-to-show (div "Lore!"))

(define (set-next-lore-to-show! html)
  (set! next-lore-to-show html))

(define (show-lore-page req)
  (response/html/content
   (container class: "p-5"
              next-lore-to-show)))
