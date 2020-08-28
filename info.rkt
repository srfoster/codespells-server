#lang info
(define collection "codespells-server")
(define deps '("base"
	       "https://github.com/srfoster/codespells-runes.git"
	       "https://github.com/thoughtstem/website.git"
	       "https://github.com/thoughtstem/website-js.git"
	       "https://github.com/thoughtstem/webapp.git"
	       ))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/codespells-server.scrbl" ())))
(define pkg-desc "Description Here")
(define version "0.0")
(define pkg-authors '(stephen))
