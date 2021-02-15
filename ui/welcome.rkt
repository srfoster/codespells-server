#lang at-exp racket

(provide welcome
         launch-patreon)

(require website-js
         codespells-server/ui/util)

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

(define (launch-patreon)
  @unreal-eval-js{
 KismetSystemLibrary.LaunchURL("https://www.patreon.com/codespells")
 })
