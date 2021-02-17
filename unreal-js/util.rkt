#lang at-exp racket

(provide with-scale spawn-mod-blueprint
         at current-x current-y current-z
         current-roll current-pitch current-yaw
         up down east west north south
         rotated)

(require codespells-runes
	 codespells-runes/basic-lang
	 (rename-in (only-in codespells-runes/basic-lang build) 
		    [build old-build]))

(require "./unreal-client.rkt")

(module+ test
	 (require rackunit)
	 (require (only-in website/util element?))
	 (require (only-in codespells-runes/basic-lang small)))


(define current-scale (make-parameter 1))
(define-syntax-rule (with-scale n lines ...)
  (parameterize ([current-scale n])
    lines ...))
(define (spawn-mod-blueprint mod-folder
                             mod-name
                             blueprint-name)
  (displayln (~a "Loading BP from" mod-folder))

  ;It's an open question whether we should return a thunk here.
  ; Functions to unreal-js fragments are useful because other runes can control their
  ; behavior with parameters like with (at ...).
  
  ;  But simple runes e.g. (gnarly-rock) are usually used without parens,
  ;So they are passed as functions anyway.

  ;But what if we augment the rune with parameters? I.e. (gnarly-rock #:version 1)?
  ;  Maybe in this case, when there are parameters, it can return a thunk


  ;Does ModLoader need to be "Owned" by the player controller on the server?
  (unreal-js
   @~a{
 (function(){
  var ccs = GWorld.GetAllActorsOfClass(Root.ResolveClass('Avatar')).OutActors;
  var ret = ccs.filter((c)=>c.IsLocallyControlled())[0]
  .SpellReplicationComponent
  .ObjectFromMod(
  "@mod-name",
  "@blueprint-name", 
  {Translation: {X: @(current-x), Y: @(current-z), Z: @(current-y)},
   Scale3D: {X: @(current-scale), Y: @(current-scale), Z: @(current-scale)},
   Rotation: {Roll: 0, Pitch: 0, Yaw: 0}});

  console.log("ret", Object.keys(ret), "@blueprint-name")
  
  return ret.Object;
  })()
 })
  
  #;
  (unreal-js
   @~a{
       (function(){
       var C = functions.bpFromMod("@(string-replace (path->string mod-folder)
                                                     "\\"
                                                     "\\\\")/",
                                   "@mod-name",
                                   "@blueprint-name")

       var o = new C(GWorld,{X:@(current-x), Y:@(current-z), Z:@(current-y)},
                            {Roll:@(current-roll), Pitch:@(current-pitch), Yaw:@(current-yaw)});
      
       return o;
       })()
   }))


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
		       [at-y y] 
		       [at-z z]
                       [by-x 0]
                       [by-y 0]
                       [by-z 0])
		      code))

(define current-roll  (make-parameter 0))
(define current-pitch (make-parameter 0))
(define current-yaw   (make-parameter 0))
(define-syntax-rule (rotated [r p y] code)
		    (parameterize
		      ([in-world #t]
		       [current-roll r]
		       [current-pitch p] 
		       [current-yaw y])
		      code))

(module+ test
	 (check-equal?
	   (at [2 2 2]
	       (+ (at-x) (at-y)))
	   4
	   "(at [_ _ _] ...) should set (at-*) params correctly"))

(define (current-x)
  @~a{ (@(by-x) + @(or (at-x) 0))})

(define (current-y)
  @~a{ (@(by-y) + @(or (at-y) 0))})

(define (current-z)
  @~a{ (@(by-z) + @(or (at-z) 0))})

