#lang at-exp racket

(provide remote)

(require website-js)

;TODO: Move to website-js
(define (remote url)
  (enclose
    (span id: (ns "target"))
    (script ([target (ns "target")]
	     [dummy (call 'construct)])
	    (function (construct)
		      @js{
                        fetch('@url')
			.then((response) => 
					 {
					 return response.text();
					 })
			.then((html) => {
				       @getEl{@target}.innerHTML = html
				       @(js-inject @target 'html)
				       }) 
			}))))


;Duplicated from webapp...  :(
(define (js-inject id stuff)
  @js{
   setTimeout(function(){
             var script_match = @stuff .match(/<script>([\s\S]*?)<\/script>?/g)
             console.log(script_match)
             if(script_match)
               for(var i = 0; i < script_match.length; i++){
                 var to_eval = script_match[i].replace("<scr"+"ipt>\n//<![CDATA[","").replace("//]]>\n</scr"+"ipt>","")
                 console.log("Evaluating:", to_eval)
                 eval(to_eval)
               }
             }, 1)

   @getEl{@id}.innerHTML = @stuff
 })

