#lang at-exp racket

(provide current-editor-lang
         editor
         )

(require website-js
         codespells-runes
         codespells-server/ui/util
         )

(define current-editor-lang (make-parameter #f))

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
     (identity
      (rune-injector (current-editor-lang)
                     (rune-surface-component (current-editor-lang)
                                             #:restore-state (thunk* @js{})
                                             #:store-state (thunk* @js{})
                                             )
                     ))))))



