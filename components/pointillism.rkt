#lang at-exp racket

(provide pointillism)

(require website-js)

(define (pointillism #:color-1 [c1 "rgba(255, 200, 0, 0.024)"]
                     #:color-2 [c2 "rgba(237, 70, 41, 0.004)"]
                     #:bg-color [bg-color "white"]
                     . content)
  (enclose
   (apply div (flatten (list id: (id 'main)
                             content
                             @style/inline{
 @(id# 'canvas) {
  @;#pointilism-sketch-container {
  position:absolute;
  top:0;
  left:0;
  width:100%;
  height:100%;
  z-index:-1;
 }
})))
   (pointillism-script c1 c2)
   ))

(define (pointillism-script c1 c2 bg)
  @script/inline{
var @(id 'sketch) = function(p){
  var img;
  var smallPoint, largePoint;

  var colors = [];
  var index = 0;

  var angle = 0;

  // function preload() {
   //   img = loadImage("../images/bg.jpg");

   // }
  var alph = 10;

  p.setup = function(){
   var parent = document.getElementById("@(id 'main)");
                                         
   //var canvas = p.createCanvas(p.windowWidth, p.windowHeight);
   var canvas = p.createCanvas(parent.offsetWidth, parent.offsetHeight);
   
   canvas.id('@(id 'canvas)');
   canvas.style('display','block');
   canvas.parent("@(id 'main)");
  
   colors.push(p.color('@c1'));
   colors.push(p.color('@c2'));
   //colors.push(p.color(123, 123, 98, alph));
   // colors.push(p.color(64, 64, 64, alph));  
   smallPoint = 20;
   largePoint = 60;
   p.imageMode(p.CENTER);
   p.noStroke();
   p.clear();
   p.angleMode(p.RADIANS);
   p.background('@bg');
   };

  p.draw = function() {

   for (var i = 0; i < 15; i++) {
    var v = p5.Vector.random2D();

    var wave = p.map(p.sin(angle), -1, 1, 0, 4);

    v.mult(p.random(1, 20*wave));
    var pointillize = p.random(smallPoint, largePoint);
    var x = p.mouseX + v.x;//floor(p.random(img.width));
    var y = p.mouseY + v.y;//floor(p.random(img.height));
    //var pix = p.img.get(x, y);
    //p.fill(pix[0],pix[1], pix[2], 52);
    p.fill(colors[index]);
    p.ellipse(x, y, pointillize, pointillize);
   }

   if (p.random(1) < 0.01) {
    index = (index + 1) % colors.length;
   }

   angle += 0.02;
   };
    
  p.windowResized = function() {
   var parent = document.getElementById("@(id 'main)");
                                         
   //p.resizeCanvas(p.windowWidth, p.windowHeight);
   p.resizeCanvas(parent.offsetWidth, parent.offsetHeight);
   
   };
};
 var myp5 = new p5(@(id 'sketch),'@(id 'canvas)');
}  )

(module+ main
  (render (list
           (bootstrap
            (page index.html
                  (content
                    (js-runtime)
                    (include-p5-js)
                    (jumbotron class: "mb-0" style: (properties height: "400"))
                    (pointillism 
                                 class: "p-5 card bg-transparent"
                                 style: (properties 'overflow: "hidden"
                                              height: "300")
                      (button-primary "HI") 
                      (button-success "HI") 
                      (button-warning "HI") 
                      (button-danger "HI") 
                      )
                    (pointillism #:color-1 "rgba(0, 255, 255, 0.024)"
                                 #:color-2 "rgba(255, 0, 255, 0.004)"
                                 class: "p-5 card bg-transparent"
                                 style: (properties 'overflow: "hidden"
                                              height: "300")
                      (button-primary "BYE") 
                      (button-success "BYE") 
                      (button-warning "BYE") 
                      (button-danger "BYE") 
                      )
                    ))))
          #:to "out"))
