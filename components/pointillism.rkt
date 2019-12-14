#lang at-exp racket

(provide pointillism)

(require website-js)

(define (pointillism . content)
 (enclose
  (div
   @style/inline{
      #sketch-container {
        position:absolute;
        width:100%;
        height:100%;
        z-index:-1;
      }
    }
    (apply div (flatten (list id: (id 'main)
                              content))))
  (pointillism-script)
  
  ))

(define (pointillism-script)
  @script/inline{
 var img;
var smallPoint, largePoint;

var colors = [];
var index = 0;

var angle = 0;

// function preload() {
//   img = loadImage("../images/bg.jpg");

// }
var alph = 10;

function setup() {
  var parent = document.getElementById("@(id 'main)");
  var canvas = createCanvas(windowWidth, windowHeight);
  canvas.id('sketch-container');
  canvas.style('display','block');
  canvas.parent("@(id 'main)");
  
  colors.push(color(255, 200, 0, 6));
  colors.push(color(237, 70, 47, 1));
  //colors.push(color(123, 123, 98, alph));
  // colors.push(color(64, 64, 64, alph));  
  smallPoint = 20;
  largePoint = 60;
  imageMode(CENTER);
  noStroke();
  clear();
  angleMode(RADIANS);
}

function draw() {

  for (var i = 0; i < 15; i++) {
    var v = p5.Vector.random2D();

    var wave = map(sin(angle), -1, 1, 0, 4);

    v.mult(random(1, 20*wave));
    var pointillize = random(smallPoint, largePoint);
    var x = mouseX + v.x;//floor(random(img.width));
    var y = mouseY + v.y;//floor(random(img.height));
    //var pix = img.get(x, y);
    //fill(pix[0],pix[1], pix[2], 52);
    fill(colors[index]);
    ellipse(x, y, pointillize, pointillize);
  }

  if (random(1) < 0.01) {
    index = (index + 1) % colors.length;
  }

  angle += 0.02;
}
@;function windowResized() {
@;  resizeCanvas(windowWidth, windowHeight);
@;}
}
  )

(module+ main
  (render (list
           (bootstrap
            (page index.html
                  (content
                    (js-runtime)
                    (include-p5-js)
                    (pointillism class: "p-5 card bg-transparent"
                           style: (properties 'overflow: "hidden"
                                              height: "50%")
                      (button-primary "HI") 
                      (button-success "HI") 
                      (button-warning "HI") 
                      (button-danger "HI") 
                      )))))
          #:to "out"))
