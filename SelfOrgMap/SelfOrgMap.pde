/**
 * Day for Night 2017
 *
 * Camera
 *
 * Works with any dimension camera and scales to fit,
 * but 1080p image signal is ideal
 *
 * Requires the following libraries (8 Nov 2017)
 * - Video (8 Nov 2017)
 * - ControlP5 (1 Dec 2017)
 *
 * Modified for PCD Open Hour (17 Dec 2018)
 */
 
// Based on Self-organizing feature maps by Jeffrey J. Guy
// Source: http://jjguy.com/som/
import com.thomasdiewald.pixelflow.java.sampling.DwSampling;

import processing.video.*;
import controlP5.*;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

PImage imgSnap;
PImage imgSnap_scaled;

SOM som;
int iter;
int maxIters = 400; // default 5000
int pixelW = 90;
int pixelH = 90;
int vecNum = 28;
int count = 0;

float learnDecay;
float radiusDecay;
boolean bShot;
String outString;
float[][] rgb2;
color [] pixelSnapshot;

Slider s_radius, s_learnrate;

String description = "Self organizing map algorithm applied for rough scene segmentation";
String name = "Self-Organizing Map";
String author = "Jeffrey J. Guy, amc";

int drawSize = 1024;
int guiPositionX = 55;


void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  rgb2 = new float[vecNum][3];

  takeSnapshot();
  createGUI();
}

void destroy() {
  println("Destroy " + name);
  rgb2 = null;
  som = null;
  px.resetShader();
  px.blendMode(BLEND);

  removeGUI();
}

void update() {
  if(!bShot){
    takeSnapshot();
  }else{
    int t = int(random(vecNum));
    if (iter < maxIters){
      som.t = t;
      som.train(iter, rgb2[t]);
      if (iter%100==0){
        //println(iter);
      }
      iter++;
    }else{
      iter = 0;
      bShot = false;
    }
  }
  updateGUI();
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  px.beginDraw();
  px.blendMode(REPLACE);
  px.background(0);
  px.endDraw();
  som.render();

  image(px, 600, 0);
  displayInfo();
}

void createGUI(){
  s_radius = cp5.addSlider("radius")
    .setPosition(guiPositionX, 100)
    .setSize(400, 30)
    .setRange(6, 400)
    .setValue((pixelH + pixelW) / 2);
    ;

  s_learnrate = cp5.addSlider("learnrate")
    .setPosition(guiPositionX, 200)
    .setSize(400, 30)
    .setRange(0.001f, 1.0f)
    .setValue(0.5f)
    ;
}

void updateGUI(){
  som.radius = s_radius.getValue();
  som.learnRate = s_learnrate.getValue();
}

void removeGUI(){
  cp5.remove("radius");
  cp5.remove("learnrate");
}

void takeSnapshot(){
  PImage temp = pg.get(0,0,px.width,px.height);
  imgSnap = pg.get(0,0,px.width,px.height);
  temp.resize(pixelW, pixelH);
  pixelSnapshot = temp.pixels;
  initSOM();
  bShot = true;
}

void initSOM(){
  som = new SOM(pixelW, pixelH, 3);
  som.initTraining(maxIters);
  iter = 1;

  textAlign(LEFT, TOP);
  learnDecay = som.learnRate;
  radiusDecay = (som.mapWidth + som.mapHeight) / 2;

  for (int n=0;n<vecNum;n++){
    float[] xy = DwSampling.sampleDisk_Halton(count*vecNum+n, 0.6);
    float radius = pixelW/4;
    float ox = pixelW/2;
    float oy = pixelH/2;
    int i = (int)(ox + xy[0] * radius);
    int j = (int)(oy + xy[1] * radius);

    rgb2[n][0] = red(pixelSnapshot[i+j*pixelW])/255.0;
    rgb2[n][1] = green(pixelSnapshot[i+j*pixelW])/255.0;
    rgb2[n][2] = blue(pixelSnapshot[i+j*pixelW])/255.0;
  }
  count++;
}

class SOM{
 int mapWidth;
 int mapHeight;
 Node[][] nodes;
 float radius;
 float timeConstant;
 float learnRate = 1.0; // default 0.05 , 0.2 worked good with r = (h+w)/6
 int inputDimension;
 int bestX;
 int bestY;
 int t;

 SOM(int h, int w, int n)
 {
   mapWidth = w;
   mapHeight = h;
   //radius = (h + w) / 2;
   radius = (h + w) / 4;
   inputDimension = n;

   nodes = new Node[h][w];
   // create nodes/initilize map
   for(int i = 0; i < h; i++){
     for(int j = 0; j < w; j++) {
       nodes[i][j] = new Node(n, h, w);
       nodes[i][j].x = i;
       nodes[i][j].y = j;

       nodes[i][j].w[0] = red(pixelSnapshot[i+j*pixelW])/255.0;
       nodes[i][j].w[1] = green(pixelSnapshot[i+j*pixelW])/255.0;
       nodes[i][j].w[2] = blue(pixelSnapshot[i+j*pixelW])/255.0;
     }//for j
   }//for i

 }

 void initTraining(int iterations){
   timeConstant = iterations/log(radius);
 }

 void train(int i, float w[]){
   radiusDecay = radius*exp(-2*i/timeConstant);
   learnDecay = learnRate*exp(-2*i/timeConstant);

   //get best matching unit
   int ndxComposite = bestMatch(w);
   int x = ndxComposite >> 16;
   int y = ndxComposite & 0x0000FFFF;

   bestX = x;
   bestY = y;

   //if (bDebug) println("bestMatch: " + x + ", " + y + " ndx: " + ndxComposite);
   //scale best match and neighbors...
   for(int a = 0; a < mapHeight; a++) {
     for(int b = 0; b < mapWidth; b++) {

        //float d = distance(nodes[x][y], nodes[a][b]);
        float d = dist(nodes[x][y].x, nodes[x][y].y, nodes[a][b].x, nodes[a][b].y);
        float influence = exp((-1*sq(d)) / (2*radiusDecay*i));
        //println("Best Node: ("+x+", "+y+") Current Node ("+a+", "+b+") distance: "+d+" radiusDecay: "+radiusDecay);

        if (d < radiusDecay)
          for(int k = 0; k < inputDimension; k++)
            nodes[a][b].w[k] += influence*learnDecay*(w[k] - nodes[a][b].w[k]);

     } //for j
   } // for i

 } // train()

 float distance(Node node1, Node node2){
   return sqrt( sq(node1.x - node2.x) + sq(node1.y - node2.y) );
 }

 int bestMatch(float w[]){
   float minDist = sqrt(inputDimension);
   int minIndex = 0;

   for (int i = 0; i < mapHeight; i++) {
     for (int j = 0; j < mapWidth; j++) {
       float tmp = weight_distance(nodes[i][j].w, w);
       if (tmp < minDist) {
         minDist = tmp;
         minIndex = (i << 16) + j;
       }  //if
     } //for j
   } //for i

  // note this index is x << 16 + y.
  return minIndex;
 }

 float weight_distance(float x[], float y[]){
    if (x.length != y.length) {
      println ("Error in SOM::distance(): array lens don't match");
      exit();
    }
    float tmp = 0.0;
    for(int i = 0; i < x.length; i++)
       tmp += sq( (x[i] - y[i]));
    tmp = sqrt(tmp);
    return tmp;
 }

 void render(){
   int pixPerNodeW = px.width / mapWidth;
   int pixPerNodeH = px.height / mapHeight;
   px.beginDraw();

   for(int i = 0; i < mapWidth; i++) {
     for(int j = 0; j < mapHeight; j++) {
       int r = int(nodes[i][j].w[0]*255);
       int g = int(nodes[i][j].w[1]*255);
       int b = int(nodes[i][j].w[2]*255);

       px.fill(r, g, b);
       //stroke(0);
       px.noStroke();
       /*px.rectMode(CORNER);
       px.rect(i*pixPerNodeW, j*pixPerNodeH, pixPerNodeW, pixPerNodeH); */
       px.ellipseMode(CORNER);
       px.ellipse(i*pixPerNodeW+2, j*pixPerNodeH+2, pixPerNodeW-4, pixPerNodeH-4);
     }
   } // for i

   // bestNode
   px.noFill();
   px.strokeWeight(2);
   px.stroke(255,76,144);
   px.ellipse(bestX*pixPerNodeW+2, bestY*pixPerNodeH+2, pixPerNodeW-4, pixPerNodeH-4);
   px.noStroke();

   // vectors
   for(int n=0;n<vecNum;n++){
     int r = int(rgb2[n][0]*255);
     int g = int(rgb2[n][1]*255);
     int b = int(rgb2[n][2]*255);
     px.fill(r,g,b);
     px.ellipse(px.width*(n+0.5)/vecNum-8, 24, 16, 16);
   }

   // selected vector
   px.noFill();
   px.strokeWeight(4);
   px.stroke(255,76,144);
   px.ellipse(px.width*(t+0.5)/vecNum-8, 24, 16, 16);
   px.noStroke();

   px.endDraw();

 }

}

class Node {
  int x, y;
  int weightCount;
  float [] w;
  Node(int n, int X, int Y)
  {
    x = X;
    y = Y;
    weightCount = n;
    w = new float[weightCount];

    // initialize weights with zero
    for(int i = 0; i < weightCount; i++)
    {
      w[i] = 0;
    }
  }
}

 void displayInfo(){
  fill(255);
  text(name, 55, 800);
  text(author, 55, 820);
  text(description, 55, 840, 500, 900);
}

void startWebCam() {
  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, 640, 480);
  }
  else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    cam = new Capture(this, cameras[0]);

    // Or, the settings can be defined based on the text in the list
    //cam = new Capture(this, 640, 480, "Built-in iSight", 30);
    // Start capturing the images from the camera
    cam.start();
  }
}

void grabCamImage() {
  // Image is flipped around y-axis to feel like a mirror
  if (cam.available() == true) {
    cam.read();
    // Crop and resize the incoming image onto a screen-sized square
    pg.beginDraw();
    pg.noStroke();
    pg.beginShape();
    pg.texture(cam);
    pg.vertex(0, 0, cam.width/2+cam.height/2, 0);   // vertex(x, y, u, v)
    pg.vertex(1080, 0, cam.width/2-cam.height/2, 0);
    pg.vertex(1080, 1080, cam.width/2-cam.height/2, cam.height);
    pg.vertex(0, 1080, cam.width/2+cam.height/2, cam.height);
    pg.endShape();
    pg.endDraw();
  }
}
