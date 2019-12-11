#lang scribble/manual
@require[@for-label[website-js]]

@title{js}
@author{thoughtstem}

@defmodule[website-js]

It's a way to author front-end web components that are:

@list{
  @item{Syntactically like HTML, but with encapsulated behavior.}
  @item{Can be defined from other components -- like building blocks.}
  @item{Can produce other component at runtime.}
  @item{Are first-class values that can be returned from functions and manipulated as data structures at Racket run-time (which, btw, is compile-time for the program that runs in the browser)}
  @item{Can be defined to receive callbacks from their parents (components that embed or produce them)}
  @item{Can define methods that other components' methods can call}
}

It's like React, but with a Lispy twist.  

The basic idea that we'll build on is that we can already (without @racket[website-js]) do the following:

@code{
  (require website/bootstrap)

  (define (my-component)
    (list
      ;The HTML
      (button-primary id: "button" on-click: @"@"js{main()}
        0)

      ;The JS
      @"@"script/inline{
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
      (button-primary id: @(ns 'button) on-click: @"@"js{@(id 'main)()}
        0)

      ;The JS
      @"@"script/inline{
        var @"@"(ns 'count) = 0
        function (ns 'main)(){
          @"@"(ns 'count) += 1
          document.getElementById("@"@"(ns 'id)").innerHTML = @"@"(ns 'count) 
        } 
      })
   )
}


But now, two instances of @(my-component) can be happy together on a page, at least.  This might even be a preferable strategy in some cases.  It is the most flexible -- i.e., you can commit whatever JavaScript attrocities you might want, including having one component mess with the other if you so desire.  

But if you're committed to syntactic simplicity and further component encapsulation, we can use the above to start building nice linguistic abstractions. 

First, I let's observe that good composable UI components have a few things in common.  In fact, they happen to be the things that React provides nice abstractions for: 

@list{
  @item{State, which values that change at runtime and are local to instances of the component.}
  @item{Props, which are values known at compile time and passed in by parent components, and which are local to instances of the component.}
  @item{A way for parents to pass in callbacks as props.}
  @item{A way to define functions that are local to the component -- with names that can be referenced within the current scope, and which can be supplied as callbacks to child components.}
 
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
           @"@"js{
             @"@"count += 1
             document.getElementById(@id).innerHTML = @"@"count
           })) 
     ))
}

The @code[@"@"js{}] abstraction tells us when we're in "Raw javascript land" -- where we may run wild with our code, unprotected by other abstractions.  It is literal code.

But within, we can demark returns to sanity with @"@"-identifiers.  Local state variable references are marked -- e.g. @code[@"@"count].  What more do we want within a function definition?   

I suppose JavaScript haters would say: A lot more.  But I would argue that you can straightforwardly lispify whatever you want:

@code{
  (define (+= var val)
    @"@"js{@"@"var += @"@"val})
}

And those who want to add forms of type safety as a language feature could also do so at this stage:

@code{
  (define/contract (+= var val)
    (-> any/c number?)
    @js{@"@"var += @"@"val})
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
           @"@"js{
             document.getElementById(@"@"id).innerHTML = @count
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
@section{Client-Side Rendering}

Started to build a calendar and realized there are some problems here.  The language you use to define behaviour (JS) doesn't have a syntax for describing components (like Racket does).  So you can't, for example, say:  

When you click "New Event", add a new event component to the calendar and rerender the calendar.  

How would you even do that in the current system?    A calendar can take the id of some template to inject, and 

The callback mechanism gives children a way to communicate with parents (i.e. a way for parents to subscribe to things of interest and be notified).  But in React a parent can render out a new version of a child, with different props.  Feels like we need something like that here... 

Currently, a parent could delete a component and inject a new version of it.  But that new version would have to be described in gross JS.  Or it would have to have been known at compile time.

For the calendar, it doesn't work.  There are infinitely many ways to have events on calendars.  So whatever is adding events to the calendar needs to be able to take user input, construct new events, and rerender the calendar with those events.

Currently, we can render out components.  Can we render out component functions -- javascript functions that return either a component string, or a component dom object (wrapped in a template?).  Whatever it is, it needs to be passable into other such functions, so that on the JS side (as on the Racket side), components can be assembled in building-block fashion.


First stop on the quest: Racket script.  Does it let me compile out my Racket functions to JS in a useful way?

Hmmm.  Just looked at it.  Seems like too much complexity for what I want. Plus the playground demo seemed slow.  I'm going to try rolling my own.  My domain is smaller, so I feel I might be able to hack to gether a much simpler compiler than RacketScript.

Okay, so we want some kind of way for parents to affect the runtime state of their children.  Their children have functions.  Can parents just reach in and call those?  Or pass in the ones to be called?

Figured out that if you have a reference to some dom element with a component inside, you can extract the namespace (brittle process atm), and call whatever functions you want.  It's like having an object reference and calling the object's methods.  I THINK this is enough to start building out cool components.  Maybe it's not as slick as React, but I have a feeling its flexibilty will be its strength.

@section{Abstractions I'm Cobbling Together}

See: components/calendar.rkt

I'm trying to build a calendar that's extensible.  I want the calendar to take its controls as input (i.e. widgets to add events, etc).  I don't what the calendar to have to decide what those look like.

So the calendar's interface will take a component that it will grant addEvent access to.  This other component will call addEvent whenever it wants -- likely in response to user input, and some kind of text field (for the event name) and time picker (for the event time). 

Weird thing is, the controls way of constructing an event object is to store it in a template.  But that's not a real object.  It's more of a prototype.  Its instance methods can't be called until it is constructed.  Should we be constructing it locally?  WHat does that mean?  Inject it into the dom?  That feels dirty for some reason. 

So my workaround was to pass along a callback to be applied wherever the event object gets injected.  It's like applying a change lazily.

Anyway, it works, but it was frought with syntactic difficulties, and I don't love the story as it stands.  Feels like we should cover up as much of that channel as possible.  Or we need to figure out a different way.

On the other hand, it is kind of cool that the event's way of letting you change its name is to provide a changeName function, which is what the controls ultimately call after injection.

So far, we've managed to build everything on top of namespaced functions and an extremely tight security model.  You get to reason object-orientedly on the front end, and functionally on the back end.


@code{
(calendar "July"
           #:controls add-event-controls 

	   (hash
	      5 (event "2pm" "Test" button-danger)))
}

This makes a calendar, with controls for adding an event.  The construction of the calendar component happens at compile time.  But the event controls demonstrate the construction of components (an event, in this case) can also happen at runtime.

@code{
(define (add-event-controls cb)
  (enclose
   (span id: (ns 'eventControls)
    (button-danger on-click: (call 'addEvent)
                   "Test add event...")
    (template id: (ns 'testEvent)
              (event #:id (ns 'testEvent) "6am" "First Day of Work")))
   (script ([testEvent (ns 'testEvent)]) 

           (function (addEvent)
                     @"@"js{var e = document.getElementById(@"@"testEvent)}
                     (cb @js{Math.floor(Math.random()*30) + 1}
                         'e (window. 'fixName)))

           (function (fixName e)
                     (js-call 'e 'changeName "Yo")))))
}

We get to leverage the fact that components are such simple things -- just dom objects that obey certain rules.  They can construct other components, provided they know how (i.e. have them stored in a local template) .  A lot of that is cool.  It's just the construction story that feels like it needs some help.

Next steps: Try to formally document the runtime model, and the definition of a component.  And other key domain vocab: Component reference, component method, component injection, etc...


Update: Ignored the previous next steps and continued building calendar component.  Have a reasonable, working event time/name picker.   Some technical debt to pay off, but so far the overall framework is getting easier for me to navigate.
(TODO: Remove the material date time picker, which proved to be a misadventure.)


Extracted injectComponent into a function.  (Way less generated code.)

TODOs

Add constructor function support for scripts.
  Possibly render function support too.

Consider adding and documenting AspectJ-style cutpoints as a way of extending the compiler.  Use cases: 
  local storage? 
  ajax backend communication?
  call render after any function that updates a state var

Consider local storage support for state variables...
  > Every set-var writes to local storage...
  > Component comes online, it reads from local storage...  
  


Unity integration? (Fun flashy project...).
  Games enclosed in components...


Docs idea: Show common refactorings.  Pushing down, lifting out.

Slight visual stutter when components load.  Might be reasonable to move them to the bottom of the page during compilation.


Need to write tests.  Starting to make mistakes without knowing it...


