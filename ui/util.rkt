#lang at-exp racket

(provide ajax-eval
         close-button
         close-all-ui
         (all-from-out webapp/server/util/responses)
         (all-from-out codespells-server/unreal-client))

(require website-js
         webapp/server/util/responses
         codespells-server/unreal-client)

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