#lang at-exp racket

(provide at up down east west north south
	 build small medium large warp
         dig
	 codespells-basic-lang)

(require codespells-runes
	 codespells-runes/basic-lang
	 (rename-in (only-in codespells-runes/basic-lang build) 
		    [build old-build]))

(require "./unreal-client.rkt" "./lore.rkt")

(module+ test
	 (require rackunit)
	 (require (only-in website/util element?))
	 (require (only-in codespells-runes/basic-lang small)))

;in-world Lang stuff


(define (lore some-html)
  (set-next-lore-to-show! some-html)
  (unreal-call "js"
               (hash 
                'script @~a{showLore()})))


(define (warp [worldName "SeekerWorld"])
  (unreal-call "js"
               (hash 
                'script @~a{warpWorld("@worldName")})))

(define-syntax-rule (up lms lines ...)
  (let ()
    (define amount (lms->number lms))

    (parameterize ([by-y (+ (by-y) amount)] )
      lines ...)))

(define-syntax-rule (down lms lines ...)
  (let ()
    (define amount (lms->number lms))

    (parameterize ([by-y (+ (by-y)
                            (- amount))] )
      lines ...)))

(define-syntax-rule (east lms lines ...)
  (let ()
    (define amount (lms->number lms))

    (parameterize ([by-x (+ (by-x)
                            amount)] )
      lines ...)))

(define-syntax-rule (west lms lines ...)
  (let ()
    (define amount (lms->number lms))

    (parameterize ([by-x (+ (by-x)
                            (- amount))] )
      lines ...)))

(define-syntax-rule (north lms lines ...)
  (let ()
    (define amount (lms->number lms))

    (parameterize ([by-z (+ amount
                            (by-z))] )
      lines ...)))

(define-syntax-rule (south lms lines ...)
  (let ()
    (define amount (lms->number lms))

    (parameterize ([by-z (+ (- amount)
                            (by-z))] )
      lines ...)))

(define (teleport [size #f])
  (unreal-call "js"
               (hash 
                'script @~a{movePlayer(@(current-x),@(current-y),@(current-z))})))


(define (build [size #f])
  (if (in-world)
      (let ()
        (define radius
          (lms->number size))

        (unreal-call "js"
                     (hash 
                      'script @~a{buildSphere(@(current-x),@(current-y),@(current-z), @radius)}))) 
      (old-build size))
  ;Maybe one day return a fancy Rune for some struct
  ;  about where the build happened, whether it succeeded, etc...
  )

(define (dig [size #f])
  (if (in-world)
      (let ()
        (define radius
          (lms->number size))

        (unreal-call "js"
                     (hash 
                      'script @~a{digSphere(@(current-x),@(current-y),@(current-z), @radius)}))) 
      (old-build size))

  ;Maybe one day return a fancy Rune for some struct
  ;  about where the build happened, whether it succeeded, etc...
  )

(define (lms->number lms)
  (match lms
    ['small 400]
    ['medium 600]
    ['large 800]
    [else 200]))

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

(define (current-x)
  (+ (by-x) (at-x)))

(define (current-y)
  (+ (by-y) (at-y)))

(define (current-z)
  (+ (by-z) (at-z)))


(define (codespells-basic-lang) 
  (local-require 2htdp/image)

  (define (axis #:up [up-c 'green]
                #:down [down-c 'green]
                #:east [east-c 'green]
                #:west [west-c 'green]
                #:north [north-c 'green]
                #:south [south-c 'green])

    (define (line color)
      (rectangle 10 30 'solid color))

    (define space (square 10 'solid 'transparent))

    (define up (line up-c))
    (define down (line down-c))
    (define east (line east-c))
    (define west (line west-c))
    (define north (line north-c))
    (define south (line south-c))
    
    (define up/down
      (above up space down))

    (define east/west
      (rotate 90 (above east space west)))

    (define north/south
      (rotate -45 (above north space south)))
    
    (rune-image
     (overlay
      north/south
      up/down
      east/west)))

  (define extra-runes
    (rune-lang 'codespells-server/in-game-lang
                (list
                 (html-rune 'teleport 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (rune-image
                               (overlay
                                (circle 5 'solid 'green)
                                (circle 10 'solid 'black)
                                (circle 15 'solid 'green)
                                (circle 20 'solid 'black)
                                (circle 25 'solid 'green))))))
                
                 (html-rune 'up 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (axis #:up 'yellow))))
                 (html-rune 'down 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (axis #:down 'yellow))))

                 (html-rune 'north 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (axis #:north 'yellow))))
                 (html-rune 'south 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (axis #:south 'yellow))))

                 (html-rune 'east 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (axis #:east 'yellow))))
                 (html-rune 'west 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (axis #:west 'yellow))))
                 
                 (html-rune 'warp 
                            (svg-rune-description
                             (rune-background
                              #:color "green"
                              (rune-image
                               (overlay
                                (rotate 30
                                        (beside
                                         (triangle 20 'solid 'green)
                                         (triangle 30 'solid 'green)))
                                (circle 40 'solid 'darkblue))))))

                 (html-rune "\"PurpleGlassWorld\""
                            (svg-rune-description
                             (rune-background
                              #:color "blue"
                              (rune-image
                               (circle 30 'solid 'purple)))))

                 (html-rune 'lore 
                            (svg-rune-description
                             (rune-background
                              #:color "red"
                              (rune-image
                               (overlay
                                (beside
                                 (rotate -30 (triangle 20 'solid 'yellow))
                                 (rotate 30 (triangle 20 'outline 'yellow)))
                                (square 60 'solid 'darkred))))))


                 (html-rune 'dig 
                            (svg-rune-description
                             (rune-background
                              #:color "#FFA500"
                              (rune-stroke
                               #:color "#FFA500"
                               M 10 25 h 10 v 2 h -10)
                              (rune-stroke
                               #:color "#FFA500"
                               M 20 25 c 0 10 10 10 10 0)
                              (rune-stroke
                               #:color "#FFA500"
                               M 30 25 h 10 v 2 h -10))))


                 
                 )))

  (define augmented-language
    (append-rune-langs
     extra-runes
     (basic-lang)))

  ;TODO: Make append-rune-langs take the language of the first one?  #:name param??
  (struct-copy rune-lang
               augmented-language
               [name 'codespells-server/in-game-lang]))

;End in-world lang stuff
