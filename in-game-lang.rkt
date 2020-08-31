#lang racket

(provide at
	 build small medium large
	 codespells-basic-lang)

(require codespells-runes
	 codespells-runes/basic-lang
	 (rename-in (only-in codespells-runes/basic-lang build) 
		    [build old-build]))

(require "./unreal-client.rkt")

(module+ test
	 (require rackunit)
	 (require (only-in website/util element?))
	 (require (only-in codespells-runes/basic-lang small))
	 )

;in-world Lang stuff



(define (build [size #f])
  (if (in-world)
      (let ()
	;Maybe one day return a fancy Rune for some struct
	;  about where the build happened, whether it succeeded, etc...
	(define radius
	  (match size
		 ['small 400]
		 ['medium 600]
		 ['large 800]
		 [else 200]))

	(unreal-call "js"
		     (hash 
		       'script (~a "buildSphere(" (at-x) "," (at-y) "," (at-z) ", 500)")))

	#;
	(unreal-call "build"
		     (xyz-hash
		       'radius
		       radius))) 
      (old-build size)))

(module+ test
	 (check-pred element?
	   (build small)
	   "Build should be an element, if not in game")

	 (check-pred (not/c element?)
		     (at [0 0 0] 
			 (build small))
		     "Build should be something else, if run in game"))

(define in-world (make-parameter #f)) ;Some things, like (build ...)?, may behave differently in the world vs. in the editor
(define at-x (make-parameter #f))
(define at-y (make-parameter #f))
(define at-z (make-parameter #f))

(define by-x (make-parameter 0))
(define by-y (make-parameter 0))
(define by-z (make-parameter 0))
(define-syntax-rule (at [x y z] code)
		    (parameterize
		      ([in-world #t]
		       [at-x x]
		       [at-y y] ;TODO: I think Unreal swaps y and z compared to Unity...
		       [at-z z])
		      code))

(module+ test
	 (check-equal?
	   (at [2 2 2]
	       (+ (at-x) (at-y)))
	   4
	   "(at [_ _ _] ...) should set (at-*) params correctly"))

(define (xyz-hash . kvs)
  (apply hash
   'x (+ (by-x) (at-x))
   'y (+ (by-y) (at-y))
   'z (+ (by-z) (at-z))
   kvs))

;Fix the Rune language (things like build need to do something special in game)

(define (codespells-basic-lang) 
  ;TODO: Change the rune-lang-name to codespells-server/in-game-lang
  ;  TODO: Patch build function.  (Rune is fine...)
  (struct-copy rune-lang
    (basic-lang)
    [name 'codespells-server/in-game-lang]))

;End in-world lang stuff
