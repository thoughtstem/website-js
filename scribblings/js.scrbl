#lang scribble/manual
@require[@for-label[website-js]]

@title{js}
@author{thoughtstem}

@defmodule[website-js]

It's a way to author front-end web components that are:

@list{
  @list-item{Syntactically like HTML, but with encapsulated behavior.}
  @list-item{Can be defined from other components -- like building blocks.}
  @list-item{Can produce other component at runtime.}
  @list-item{Can only affect themselves and components they may have produced.}
  @list-item{Are first-class values that can be returned from functions and manipulated as data structures at Racket run-time (which, btw, is compile-time for the program that runs in the browser)}
  @list-item{Can be defined to receive callbacks from their parents (components that embed or produce them)}
}

It's like React, but with a Lispy twist.  

The basic idea that we'll build on is that we can already (without @racket[website-js]) do the following:

@code{
  (require website/bootstrap)

  (define (my-component)
    (list
      ;The HTML
      (button-primary id: "button" on-click: @js{main()}
        0)

      ;The JS
      @script/inline{
        var count = 0
        function main(){
          count += 1
          document.getElementById("button").innerHTML = count
        } 
      })
   )
}

When this goes into @racket[output-xml], the implied HTML get's popped out.  Or you can get a website with:

@code{
  (render (page index.html
                (html 
                  (body 
                    (my-component))))
     #:to "out") 
}

But the moment you try to put two @racket[(my-component)]s on a page, the two components leak into each other's functionality.  You end up generating two @tt{main()} functions definitions, two variable definitions, and you have two bootstrap buttons with the same id.  

Bugs everywhere. 

What is nice is that we can use the fact that the HTML/JS pair are so close to each other to start enforcing a kind of "scope" on the components.  

It's not pleasant, but it 's a simple idea -- namespace everything that gets used in as a form of identification -- HTML ids, JavaScript function defintions/calls, and JavaScript variable definitions/references.

@code{
  #lang racket 
  
  (require website-js)

  (define (my-component)
    (with-namespace (next-namespace) 
      ;The HTML
      (button-primary id: @(ns 'button) on-click: @js{@(id 'main)()}
        0)

      ;The JS
      @script/inline{
        var @(ns 'count) = 0
        function (ns 'main)(){
          @(ns 'count) += 1
          document.getElementById("@(ns 'id)").innerHTML = @(ns 'count) 
        } 
      })
   )
}


But now, two instances of @(my-component) can be happy together on a page, at least.  This might even be a preferable strategy in some cases.  It is the most flexible -- i.e., you can commit whatever JavaScript attrocities you might want, including having one component mess with the other if you so desire.  

But if you're committed to syntactic simplicity and further component encapsulation, we can use the above to start building nice linguistic abstractions. 

First, I let's observe that good composable UI components have a few things in common.  In fact, they happen to be the things that React provides nice abstractions for: 

@list{
  @list-item{State, which values that change at runtime and are local to instances of the component.}
  @list-item{Props, which are values known at compile time and passed in by parent components, and which are local to instances of the component.}
  @list-item{A way for parents to pass in callbacks as props.}
  @list-item{A way to define functions that are local to the component -- with names that can be referenced within the current scope, and which can be supplied as callbacks to child components.}
 
}

This allows for the kind of secure component ecosystem that React can provide.  Information flows into components via parents only.  Information flows out of components to parents only -- and only via callbacks.  

Let's consider this to be the opposite extreme of the most recent code example -- instead of being able to commit whatever JavaScript attrocities we might want, we may now only commit attrocities that follow a strict set of inter-component communication rules.  

This helps component designers trust the components they are using to build their own out of.  [I would argue that this exact restriction (and corresponding increase in code correctness) has been at the heart of React's meteoric rise to popularity.  That -- along with the JSX syntax, which allows mixing of JS code with stuff that "feels" like HTML -- which aids our minds when we reason about the structure of the DOM.]

Here's a stab at getting all of the above:

@code{
  #lang racket 
  
  (require website-js)

  (define (my-component)
    (enclose
      (define id (ns 'button))
      ;The HTML
      (button-primary id: id 
                      on-click: (call main) 
        0)

      ;The JS -- lispified
      (script ([count 0]
               [id (ns 'button)])
        (function (main)
           @js{
             @count += 1
             document.getElementById(@id).innerHTML = @count
           })) 
     ))
}

<<Short overview of above changes, to aid the reader.>>


<<Also note that the use of @racket[(call ...)] still requires a quote.  I need to convert it to a syntax rule.>>


Let's conside the abtractions above in light of what it hides and what it shows, and let us as if it is hiding and showing the right things.

The @code[@"@"js{}] abstraction tells us when we're in "Raw javascript land" -- where we may run wild with our code, unprotected by other abstractions.  It is literal code.

But within, we can demark returns to sanity with at-identifiers.  Local state variable references are marked -- e.g. @code[@"@"count].  What more do we want within a function definition?   

I suppose JavaScript haters would say: A lot more.  But I would argue that you can straightforwardly lispify whatever you want:

@code{
  (define (+= var val)
    @js{@var += @val})
}

And those who want to add forms of type safety as a language feature could also do so at this stage:

@code{
  (define/contract (+= var val)
    (-> any/c number?)
    @js{@var += @val})
}

Type safety or not, by the power of Racket, the above successfully gobbles one sort of of JavaScript line into Lisp.  Our particular program gets one line moved out of the dangerous JavaScript territory into the save embrace of its fellow s-expressions:

@code{
  #lang racket 
  
  (require website-js)

  (define (my-component)
    (enclose
      (define id (ns 'button))
      ;The HTML
      (button-primary id: id 
                      on-click: (call main) 
        0)

      ;The JS -- lispified
      (script ([count 0]
               [id (ns 'button)])
        (function (main)
           (+= count 1) ;I am safe now!  Parens are like friendly hugs! 
           @js{
             document.getElementById(@id).innerHTML = @count
           })) 
     ))
}

I'm sure the reader would believe that the same is easily accomplished for the remaining JavaScript line:

@code{
  #lang racket 
  
  (require website-js)

  (define (my-component)
    (enclose
      (define id (ns 'button))
      ;The HTML
      (button-primary id: id 
                      on-click: (call main) 
        0)

      ;The JS -- lispified
      (script ([count 0]
               [id id])
        (function (main)
           (+= count 1) ;Yay!  We are Lisp buddies now!
           (el= id.innerHTML count) ;I feel the same!)) 
     ))
}

We leave the above as exercises to the reader (which would be welcomed into the @racket[website-js] repository).  I'll likely make such abstractions for my own personal use.

Anyway, the main point is accomplished -- and indeed was accomplished even before our digression to prove that the remaining JS can be converted into a substance condusive for further language skulpting.   

More interesting to me, however, as an organizing principle for any sort of endeavor would be -- what are the minimal set of linguistic tools that the average component author needs.  Yes: There will always be odd, unique, weird needs.  And for that, the escape hatch into dangerous JS territory -- a tool always at hand.  But when we do the sorts of things that pure user interfaces most often require -- what linguistic tools most assist us?

I don't know the answer to that question, but my next steps are to try converting a standard component library -- like React's Material UI or Material Design Components.  This will illuminate the powerful abstractions that must come next.   



















