#lang at-exp racket

(provide color-picker)

(require website-js
         "./clicker.rkt")


(define (clicker-on-click kind c)
  (curry clicker 
         #:on-click c))

(define (color-picker
          #:on-change (on-change (const ""))
          #:r (r (curry clicker-on-click button-danger))
          #:g (g (curry clicker-on-click button-success))
          #:b (b (curry clicker-on-click button-primary)))
  (enclose
    (define output-id (id 'output))

    (jumbotron
      id: output-id
      style: (properties background-color: "rgb(0,0,0)")
      (row
        (col
          (r (callback 'change "red")))
        (col
          (g (callback 'change "green")))
        (col
          (b (callback 'change "blue")))))

    (list
      (script/inline
        @~a{alert("Hi")}
        )
      (script ([red 0]
               [green 0]
               [blue 0]
               [output output-id])
              (function (change color amount)
                        @js{
                        if(@color == "red"){
                        @red = @amount 
                        }
                        if(@color == "green"){
                        @green = @amount
                        }
                        if(@color == "blue"){
                        @blue = @amount
                        }

                        var newColor = "rgb(" + @red + "," + @green + "," + @blue + ")"; 

                        document.getElementById(@output).style.backgroundColor = newColor;

                        @(on-change 'newColor)
                        }
                        ))) ))

(define (picker-maker)
  (enclose
    (define to-make (color-picker))

      (card
        (card-body
          (button-primary on-click: (call 'newClicker)
                          "I make pickers")
          (hr)
          (row id: (id 'target))
          (element 'template
                   id: (id 'template)
            (color-picker))
          ))
      (list
        (script
          ([target (id 'target)]
           [template (id 'template)])
          (function (newClicker)
                    @~a{

function replaceAllText(root, find, replace) {

    var walker = document.createTreeWalker(
        root,  
        NodeFilter.SHOW_ALL,  // filtering only text nodes
        null,
        false
    );
    
    while (walker.nextNode()) {
        //if (walker.currentNode.nodeValue.trim()) 
        var c = walker.currentNode
        if(c.id){
          c.id = c.id.replace(find, replace)
        }
        console.log(c)
        if(c.getAttribute && c.getAttribute('onclick')){
          c.setAttribute('onclick', c.getAttribute('onclick').replace(find, replace))
        }
        if(c.tagName == "SCRIPT"){
          c.textContent = c.textContent.replace(find, replace)
        }
    }
}

     function newNamespaceKeeping(old){
        console.log("Keeping", old)
        var cache = {}
        return function(ns){
          if(!cache[ns]){
            //Keep a cache.  And avoid changing the oldNamespace...
	    window.namespace_num = window.namespace_num || 0
	    window.namespace_num += 1
            var freshNamespace = ns + "0000" + window.namespace_num 
            cache[ns] = freshNamespace
          }

	  return cache[ns];
        }
     }


                    var s = document.getElementById(@template).innerHTML
                    var oldNamespace = "@(namespace)"
                    //var oldNamespace = s.match(/(ns\d*)/)[0] 

                    var content = document.getElementById(@template).content
                    var clonedContent = document.importNode(content, true) 
                    replaceAllText(clonedContent, /ns\d*/g, newNamespaceKeeping(oldNamespace))

                    document.getElementById(@target).appendChild(clonedContent)


                    } 
                    )))))


(define (test)
  (bootstrap
    (page index.html
          (content
            (h1 "Color Picker Demo")
            (color-picker)

            #;
            (element 'template
                     (div "hello")
                     (script/inline
                       "alert('hi')"))

            #;
            (div id: "target1")
            #;
            (div id: "target2")

            #;
            (script/inline
              @~a{
              
                var temp = document.getElementsByTagName("template") [0];
                var clone1 = temp.content.cloneNode(true);

                document.getElementById("target1").appendChild (clone1)
                var clone2 = temp.content.cloneNode(true);

                document.getElementById("target2").appendChild (clone2)
              })
           

            (picker-maker)))))

(module+ main
  (render (test) #:to "out"))
