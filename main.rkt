#lang racket


(provide (all-from-out "./lang.rkt"))
(require "./lang.rkt")

(module+ main
	 (codespells-server-start))


