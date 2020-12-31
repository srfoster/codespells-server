#lang at-exp racket

(provide 
  run-staged
  codespells-server-start
  current-editor-lang
  (all-from-out "./in-game-lang.rkt"))

;TODO: Cleanup requires
(require web-server/servlet
         web-server/servlet-env
         web-server/http/request-structs
         json
         (only-in website/bootstrap website-bootstrap-path)
         webapp/server/util/responses
	 (except-in webapp/js header small)
	 (except-in website-js header small)
         http/request
         net/uri-codec
	 codespells-runes
	 "./in-game-lang.rkt"
         "./lore.rkt"
         "./unreal-client.rkt")

(define (ajax-eval str)
  @js{
 var fd = new FormData()
 fd.append("spell", "@str")

 fetch('/eval-spell?lang=codespells-server/lang',
 {method: 'POST',
  body: fd})
 .then(response => {
  return response.text()	
  })}
  )

(define (close-button)
  (enclose
   (button-danger
    on-click: (call 'close)
    "Close")
   (script ()
           (function (close)
                     (ajax-eval "(close-all-ui)")
                     ))))

(define (launch-patreon-button)
  (enclose
   (button-success
    on-click: (call 'launch)
    "Support Us on Patreon")
   (script ()
           (function (launch)
                 (ajax-eval "(launch-patreon)")    
                     ))))




(define (welcome r)
  (response/html/content 
   (enclose
    (container
     @style/inline{
 body{
  background-color: rgba(0,0,0,0);}}
     (launch-patreon-button)
     (close-button)
     (iframe src: (~a "https://www.codespells.org/in-game.html?no-cache=" (random 1000000))
             style: (properties
                     width: "100%"
                     height: "80%"
                     border: "none")))
    (script ()
             
            ))))


;TODO: Move to codespells-runes
; * Should maybe take a value to namespace the localStorage.  NAMESPACE changes on refresh; can't use.
; * On reload, need to do an injection.  Something like html->js-injector, but with just a string.
(define (rune-saver child-with-surface)
  (enclose
      (div id: (id 'id)
	   'onmouseup: (call 'save)
	child-with-surface)
      (script ([construct (call 'constructor)])
              (function (constructor)
                        (call 'load))
	      (function (save)
			@js{
                        var toSave = $(@(~j "#NAMESPACE_id .runeSurface")).html()
			window.localStorage.setItem(@(~j "rune_storage"), toSave)
			})
	      (function (load)
			@js{
                        var toLoad = window.localStorage.getItem(@(~j "rune_storage"))
                        console.log("toLoad", toLoad)
                        if(toLoad && toLoad != ""){
                          $(@(~j "#NAMESPACE_id .runeSurface")).html(toLoad)
                        }
			})
	      
              )))


(define current-editor-lang (make-parameter (codespells-basic-lang)))

(define (close-all-ui)
  ; If we want a close button to close a particular widget,
  ; that widget's initial URL will need to encode the widget ID
  ; Example: localhost:8081/widget_id=welcome
  ; And the widget will need to have been stored into globals with that ID
  ; Example: globals.widgets = global.widgets || {};
  ;          global.widgets.welcome = widget;
  ; Then the page can construct a close button that will close itself
  ; based on the widget ID
  ; BUT FOR NOW - this works by just closing all widgets
  @unreal-eval-js{
 var list = GWorld.GetAllWidgetsOfClass([], WB_TextSpellcrafting_C);
 var widgets = list.FoundWidgets;
 widgets.map(function(widget){
  widget.SetVisibility(ESlateVisibility.Hidden);
  });
}
  
  @unreal-eval-js{
 var control = GWorld.GetPlayerController(0);
 control.SetInputMode_GameOnly();
 control.bShowMouseCursor = false;
 })

(define (launch-patreon)
  @unreal-eval-js{
 KismetSystemLibrary.LaunchURL("https://www.patreon.com/codespells")
 })

(define (editor r)
  (define (spell-runner editor)
    (enclose
     
      (div id: (id 'id)
	   'onmouseleave: (call 'stageSpell @js{()=>null})
	editor
        (close-button)
	(div
	  style: (properties
		   padding-top: 20)
	  (code 
	    (pre id: (id 'out)))))
      (script ()
	      (function (stageSpell cb)
			@js{
			var container = document.querySelector(@(~j "#NAMESPACE_id .runeContainer"))

			var code = @(call-method 'container 'compile)
			var lang = @(call-method 'container 'currentLanguage)

                        

			if(code != ""){
			var fd = new FormData()
			fd.append("spell", code)

			fetch('/stage-spell?lang=' + lang,
			      {method: 'POST',
			      body: fd})
			.then((r)=>cb())
			}
			})
	      (function (runStagedSpell)
			@(call 'runSpell "codespells-server" "(run-staged)"))

	      (function (stageAndRun)
			@js{
                          @(call 'stageSpell
				 @js{()=>@(call 'runStagedSpell)})
			})
	      (function (runSpell lang code)
			@js{
			var fd = new FormData()
			fd.append("spell", code)

			fetch('/eval-spell?lang=' + lang,
			      {method: 'POST',
			      body: fd})
			.then(response => {
	                  return response.text()	
		        })
			.then(result => {
				     $(@(~j "#NAMESPACE_out")).html(result)

				     })
			}
			)
              )))
  (response/html/content 
   (container 
    @style/inline{
 body{
  background-color: rgba(0,0,0,0);
 }
}
    (rune-surface-height 750)
    (spell-runner
     (identity ;rune-saver
      (rune-injector (current-editor-lang)
                     ;(demo-editor (codespells-basic-lang))
                     (rune-surface-component (current-editor-lang)
                                             #:restore-state (thunk* @js{})
                                             #:store-state (thunk* @js{})
                                             )
                     ))))))





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

(define (run-staged)
  (run-code #:side-effects? #f last-lang last-spell))

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

  result )

(define (serve-html req)
  (define html-code
    (extract-binding/single
     'html
     (request-bindings req)))


  ;I cannot for the life of me figure out why this is necessary.
  ;  But for some reason the in-Unreal browser renders a black screen when
  ;  I try to render the html code stored in the ?html= parameter.
  ;It renders anything else -- even code that is ALMOST exactly the same.
  ;  But for some reason, not when it is exactly the same.
  ;Twiddling the namespaces seems to make it happy, so that's what we are doing.
  ;  I can only conclude that this is some kind of bizzare bug in the embedded browser... :(
  (define code-with-namespaces-change
    ;Just stick numbers on the beginning and end...
    (regexp-replace* #px"ns([0-9]+)_" html-code  "ns6969\\16969_"))

  (define full-code-template
    (element->string (content "@HACK")))

  (define full-code (string-replace full-code-template "@HACK"

                                    code-with-namespaces-change
                                    ))

  (response/full
    200 #"Success"
    (current-seconds) TEXT/HTML-MIME-TYPE
    '()
    (list 
      (string->bytes/utf-8 full-code)))

  )

(define messages
  (list))

(define (add-message req)
  (define raw-data (request-post-data/raw req))
  (define body-string (regexp-replace #rx"^data=" (bytes->string/utf-8 raw-data) ""))
  (define json (string->jsexpr body-string))
  (set! messages (cons json messages))
  (response/full
    200 #"Success"
    (current-seconds) APPLICATION/JSON-MIME-TYPE
    '()
    (list 
      (string->bytes/utf-8 "{message: \"hi\"}"))))

(define (get-last-message req)
  (response/full
    200 #"Success"
    (current-seconds) APPLICATION/JSON-MIME-TYPE
    '()
    (list 
      (string->bytes/utf-8 (jsexpr->string (first messages))))))

(define-values (start url)
    (dispatch-rules
      [("")
       welcome]
      [("editor")
       editor]
      [("stage-spell")
       #:method "post"
       stage-spell]
      [("eval-spell")
       #:method "post"
       eval-spell]

      [("serve-html")
       serve-html]
     
      [("lore")
       show-lore-page]

      [("messages") #:method "post"
       add-message]
      [("messages" "last")
       get-last-message]
      )
    )

(define (codespells-server-start)
  (serve/servlet start
		 #:port 8081
		 #:servlet-regexp #rx""
		 #:launch-browser? #f
		 #:extra-files-paths
		 (list website-bootstrap-path)
		 #:servlet-current-directory (current-directory)))

(module+ main
  (codespells-server-start))