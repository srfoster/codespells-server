#lang at-exp racket

(provide codespells-server-start)

;TODO: Cleanup requires
(require web-server/servlet
         web-server/servlet-env
         (only-in website/bootstrap website-bootstrap-path)
         webapp/server/util/responses
	 (except-in webapp/js header)
	 (except-in website-js header)
         http/request
         net/uri-codec
	 codespells-runes)


(define (welcome r)
  (response/html/content 
    (container 
      (jumbotron
	(img 
	  style: (properties
		   width: "100%")
	  src: "https://codespells.org/images/logo.png")
	(div "Welcome to the CodeSpells Web-Server!"
	     (ul
	       (li (a href: "/editor"
		     "Check out the editor")))
	     )))))

(define (editor r)
  (define (spell-runner editor)
    (enclose
      (div id: (id 'id)
	editor
	(button-success
	  on-click: (call 'runCode)
	  "Run")
	(div
	  style: (properties
		   padding-top: 20)
	  (code 
	    (pre id: (id 'out)
		 ))))
      (script ()
	      (function (runCode)
			@js{
			//TODO: Get code, ajax
			var container = document.querySelector(@(~j "#NAMESPACE_id .runeContainer"))

			var code = @(call-method 'container 'compile)
			var lang = @(call-method 'container 'currentLanguage)

			fetch('/eval-spell?lang=' + lang,
			      {method: 'POST',
			      body: code})
			.then(response => {
	                  return response.text()	
		        })
			.then(result => {
				     $(@(~j "#NAMESPACE_out")).html(result)

				     })
			

			}))))
  (response/html/content 
    (container 
      (jumbotron
	(img 
	  style: (properties
		   width: "100%")
	  src: "https://codespells.org/images/logo.png"))
      (spell-runner
	(rune-injector (basic-lang)
		       (demo-editor (basic-lang)))))))



(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))
(define (eval-spell r)
  (define code (bytes->string/utf-8 (request-post-data/raw r)))

  (define lang 
    (string->symbol
      (extract-binding/single
	'lang
	(request-bindings r))))

  (displayln lang)
  (displayln code)

  (dynamic-require lang #f)

  (define result
    (eval (read (open-input-string (~a "(let () " code ")")))
	  (module->namespace lang)
	  #;
	  ns))

  (displayln result)

  ;TODO: json... Or a nicely formatted success/error enclosure.  Show both in text and code...
  (response/html/content
    (card-group  style: (properties height: 500
			     width: "100%")
      (card style: (properties position: 'relative
			      width: "50%"
			      height: "100%")


	    (datum->html 
	      (basic-lang)
	      result))

      (card (card-body (card-text (~v result))))
      )))

(define-values (start url)
    (dispatch-rules
      [("")
       welcome ]
      [("editor")
       editor]

      [("eval-spell")
       #:method "post"
       eval-spell]

      #;
      [("scripts" (string-arg))
       #:method "post"
       scripts]
      #;
      [("lore")
       lore-page]
      #;
      [("lores")
       lores-page]
      #;
      [("set-last-script")
       set-last-script]
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
