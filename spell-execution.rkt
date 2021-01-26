#lang at-exp racket

(provide eval-spell
         stage-spell
         running-as-multiplayer-server?
         run-staged)

(require codespells-runes
         (except-in website-js header)
         web-server/servlet
         web-server/servlet-env
         web-server/http/request-structs
         webapp/server/util/responses
         codespells-server/in-game-lang
         codespells-server/unreal-client)

(define (request->code r)
  (string->symbol
    (extract-binding/single
      'spell
      (request-bindings r))))

(define (request->lang r)
  (define lang-string
    (extract-binding/single
     'lang
     (request-bindings r)))

  ;Check if file: So we can dynamic require raw rkt files without needing them to be installed packages
  (if (file-exists? lang-string) 
      (string->path lang-string)
      (string->symbol
       lang-string)))

(define last-lang #f)
(define last-spell #f)

(define (stage-spell r)
  (define code (request->code r))

  (define lang 
    (request->lang r))

  (set! last-lang lang)
  (set! last-spell
    (read (open-input-string (~a "(let () " (substring (~v code) 1) ")"))))
  
  (response/html/content
    (div "Staged spell")))

(define (eval-spell r)
  (define code (request->code r))

  (define lang 
    (request->lang r))

  (define result (run-code lang code))

  (response/html/content
    (card-group  style: (properties height: 250
				    width: "100%")
		 (card style: (properties position: 'relative
					  height: "100%")


                       (with-handlers ([exn:fail? (lambda (e)
                                                    (displayln (~a "No way to turn result into a Rune: "))
                                                    (displayln result)
                                                    (div "error"))])
                           (datum->html 
                            (codespells-basic-lang)
                            result)))

		 (card (card-body (card-text (~v result)))))))


(define running-as-multiplayer-server? (make-parameter #f))

(define (run-staged)
  (if (running-as-multiplayer-server?)
      (run-code #:side-effects? #f last-lang last-spell)
      (unreal-eval-js
       @unreal-js{
 var ccs = GWorld.GetAllActorsOfClass(Root.ResolveClass('Avatar')).OutActors;
 ccs.filter((c)=>c.IsLocallyControlled())[0]
 .SpellReplicationComponent
 .RequestRunSpellOnServer(@(~s (path->string last-lang)),
 "(let () (define x @(regexp-replace* #px"\\s+" (~a last-spell) " ")) (if (procedure? x) (x) x))",
 @(current-x),
 @(current-z),
 @(current-y));
}
       )))

(define (run-code #:side-effects? (side-effects? #t) lang code)
  ;This is such a confusing function, given that it gets called twice.
  ;Unreal's sends (at [x y z] (run-staged)) to eval-spell, which calls it with side effects (the main call).
  ;  Note that in the main call, there are no current-x/y/z parameters set (they are all 0)
  ;Then there is a recursive call, because (run-staged) calls it -- but with no side effects.
  ;  Note that this is when current-x/y/z are set
  ;The top call then sends side effects to Unreal if the result was an unreal-js-fragment
  ;

  
  (displayln (~a "Running in lang: " lang))
  (displayln code)

  (dynamic-require lang #f)

  (define initial-result
    (eval (read (open-input-string (~a "(let () " code ")")))
          (module->namespace lang)))

  ;; Sometimes runes return procedures that return unreal-js-fragments
  ;; This is convenient to allow other runes to control their position with (at ...)
  ;; But if  those runes are used at the top-level of a spell,
  ;; we want to call the procedure in order to send the js-fragments over to Unreal
  (define result (if (procedure? initial-result)
                     (initial-result)
                     initial-result
                     ))
  
  (when (and side-effects?
             (unreal-js-fragment? result))
    (unreal-eval-js result)

    )

  (displayln (~a "Result: " result))


  result)