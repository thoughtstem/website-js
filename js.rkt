#lang at-exp racket

(provide js-runtime)

(require website)

(define (js-runtime)
  (script/inline
    @~a{
        function replaceAllText(root, find, replace) {

            var walker = document.createTreeWalker(
                root,  
                NodeFilter.SHOW_ALL,  // filtering only text nodes
                null,
                false
            );
            
            while (walker.nextNode()) {
                var c = walker.currentNode
                if(c.id){
                  c.id = c.id.replace(find, replace)
                }
                if(c.getAttribute && c.getAttribute('onclick')){
                  c.setAttribute('onclick', c.getAttribute('onclick').replace(find, replace))
                }
                if(c.tagName == "SCRIPT"){
                  c.textContent = c.textContent.replace(find, replace)
                }

                if(c.tagName == "TEMPLATE"){
                  var content = c.content
                  console.log(content)
                  replaceAllText(content, find, replace)
                }
            }
        }

     function newNamespaceKeeping(old){
        var cache = {}
        return function(ns){
          if(!cache[ns] && ns != old){
            //Keep a cache.  And avoid changing the oldNamespace...
	    window.namespace_num = window.namespace_num || 0
	    window.namespace_num += 1
            var freshNamespace = ns + "0000" + window.namespace_num 
            cache[ns] = freshNamespace
          }

	  return cache[ns] || ns;
        }
     }

     function getNamespace(component){
       console.log(component)
       return component.innerHTML.match(/ns\d+/)[0]  
     }
     }))



