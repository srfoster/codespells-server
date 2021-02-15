#lang at-exp racket

(provide
 codespells-server-port
 running-as-multiplayer-server?
 run-staged
 codespells-server-start
 current-editor-lang
 (all-from-out "./unreal-js/util.rkt")
 )

;TODO: Cleanup requires
(require web-server/servlet
         web-server/servlet-env
         web-server/http/request-structs
         json
	 ;(except-in webapp/js header small)
	 (except-in website-js header small)
	 codespells-runes
	 "./unreal-js/util.rkt"
         "./spell-execution.rkt"
         "./ui/spell-editor.rkt"
         "./ui/welcome.rkt"
         "./ui/util.rkt"
         "./ui/user-generated.rkt"
         )

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
      [("messages") #:method "post"
       add-message]
      [("messages" "last")
       get-last-message]
      )
    )

(define codespells-server-port (make-parameter 8081))

(define (codespells-server-start)
  (serve/servlet start
		 #:port (codespells-server-port)
		 #:servlet-regexp #rx""
		 #:launch-browser? #f
		 #:extra-files-paths
		 (list website-bootstrap-path)
		 #:servlet-current-directory (current-directory)))

(module+ main
  (codespells-server-start))
