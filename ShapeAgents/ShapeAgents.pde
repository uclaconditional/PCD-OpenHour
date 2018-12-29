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

import processing.video.*;
import controlP5.*;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

PShader shader;

PGraphics mainImage;
PGraphics currImage;
int superSampleRate = 2;

ShapeAgent shapeAgent;

Slider s_numAgents;
Slider s_agentStepSize;
Button b_resetShape;

String description = "Control points of the circle changes its position in a random increment or decrement every frame. The resulting shape is drawn on screen with camera input as its color.";
String name = "Shape Agents";
String author = "Hye Min Cho";

int drawSize = 1024;
int guiPositionX = 55;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();

  createGUI();

  mainImage = createGraphics(superSampleRate * px.width, superSampleRate * px.height, P2D);
  currImage = createGraphics(superSampleRate * px.width, superSampleRate * px.height, P2D);

  shader = loadShader("shapeAgents.frag");
  shader.set("resolution", px.width * superSampleRate, px.height * superSampleRate);

  shapeAgent = new ShapeAgent();
  shapeAgent.setupShape();

  mainImage.smooth(8);
  mainImage.beginDraw();
  mainImage.background(0);
  mainImage.noFill();
  mainImage.stroke(0, 0, 0, 80);
  mainImage.strokeWeight(2);
  mainImage.endDraw();

  currImage.beginDraw();
  currImage.background(255, 255, 255, 0);
  currImage.endDraw();


}

void destroy() {
  println("Destroy " + name);
  mainImage.resetShader();
  mainImage = null;
  currImage = null;
  shapeAgent = null;
  removeGUI();
}

void update() {
  updateGUI();

  shader.set("time", ((float) millis())/1000.0);
  shader.set("centerPosition", shapeAgent.centerPos.x, shapeAgent.centerPos.y);
  shapeAgent.updateShape();
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  currImage.beginDraw();
  currImage.background(255, 255, 255, 0);
  shapeAgent.drawShape(currImage);
  currImage.endDraw();

  mainImage.beginDraw();
  mainImage.image(mainImage, 0, 0);
  shader.set("camera", pg);
  shader.set("currImage", currImage);
  mainImage.filter(shader);
  mainImage.endDraw();


  px.beginDraw();
  px.tint(255);
  // shapeAgent.draw
  // px.image(pg, 0, 0);
  // px.image(mainImage, 0, 0, px.width, px.height);
  px.image(mainImage, 0, 0, px.width, px.height);
  px.endDraw();

  image(px, 600, 0);
  displayInfo();
}

void createGUI(){
  s_numAgents = cp5.addSlider("Agent_Number")
   // .setPosition(2880,800)
   .setPosition(guiPositionX,150)
   .setSize(400, 30)
   .setRange(1,300) // values can range from big to small as well
   .setValue(50);

  s_agentStepSize = cp5.addSlider("Agent_Step_Size")
   // .setPosition(2880,800)
   .setPosition(guiPositionX,200)
   .setSize(400, 30)
   .setRange(0,25) // values can range from big to small as well
   .setValue(2);

  b_resetShape = cp5.addButton("Reset_Shape")
   .setPosition(guiPositionX, 250)
   .setSize(100, 30)
   .onPress(new CallbackListener() { // a callback function that will be called onPress
    public void controlEvent(CallbackEvent theEvent) {
      shapeAgent.resetShapeToCircle();
    }
  });
}

void updateGUI(){
  shapeAgent.numAgents = int(s_numAgents.getValue());
  shapeAgent.agentMaxStepSize = int(s_agentStepSize.getValue());
}

void removeGUI(){
  cp5.remove("Agent_Number");
  cp5.remove("Agent_Step_Size");
  cp5.remove("Reset_Shape");
}


class ShapeAgent{
  PVector centerPos;
  ArrayList<PVector> relativePositions;

  int numAgents = 50;
  float radius = 150;
  float agentMaxStepSize = 2;
  // float centerMaxStepSize = 2;

  PVector targetPos;
  // float movePercent = 0.05;
  // float arrivedThreshold = 15;

  // float randTraverseLength = 2;
  // float randTraverseShortLength = 5;

  int notOnScreenFrames = 0;
  int resetCenterAfterNumFrames = 600;

  ShapeAgent(){
    centerPos = new PVector();
    centerPos.x = (px.width * superSampleRate) / 2;
    centerPos.y = (px.height * superSampleRate) / 2;

    targetPos = new PVector(random(px.width * superSampleRate), random(px.height * superSampleRate));

    relativePositions = new ArrayList<PVector>();
  }

  void setupShape(){
    // for(int i = 0; i < numAgents; i++){
    //   PVector pt = new PVector();
    //   relativePositions.add(pt);
    // }
    resetShapeToCircle();
  }

  void resetShapeToCircle(){
    float stepAngle = radians(360.0/float(numAgents));
    relativePositions = null;
    relativePositions = new ArrayList<PVector>();
    for(int i = 0; i < numAgents; i++){
      PVector currPos = new PVector();
      currPos.x = cos(stepAngle * i) * radius;
      currPos.y = sin(stepAngle * i) * radius;
      relativePositions.add(currPos);
    }

  }

  void updateShape(){
    for(int i = 0; i < relativePositions.size(); i++){
      PVector currVector = relativePositions.get(i);
      currVector.x += random(-agentMaxStepSize, agentMaxStepSize);
      currVector.y += random(-agentMaxStepSize, agentMaxStepSize);
      relativePositions.set(i, currVector);

    }

    centerPos.x += cos(millis()/1000.0) * sin(millis()/500.0) * 8 + sin(millis()/800.0) * 5;
    centerPos.y += sin(millis()/1000.0) * sin(millis()/500.0) * 8 + cos(millis()/800.0) * 5;

    if (centerIsOffScreen()){
      notOnScreenFrames++;
    }

    if (notOnScreenFrames > resetCenterAfterNumFrames){
      centerPos.x = (px.width * superSampleRate)/2.0;
      centerPos.y = (px.height * superSampleRate)/2.0;
      resetShapeToCircle();

      notOnScreenFrames = 0;
    }
  }

  boolean centerIsOffScreen(){
    if (centerPos.x < 0 || centerPos.x > px.width * superSampleRate ||
        centerPos.y < 0 || centerPos.y > px.height * superSampleRate){
          return true;
        }

    return false;
  }

  void drawShape(PGraphics layer){
    layer.beginShape();
    PVector lastPoint = relativePositions.get(relativePositions.size()-1);
    layer.curveVertex(lastPoint.x + centerPos.x, lastPoint.y + centerPos.y);

    for(int i = 0; i < relativePositions.size(); i++){
      PVector currPoint = relativePositions.get(i);
      layer.curveVertex(currPoint.x + centerPos.x, currPoint.y + centerPos.y);
    }

    PVector firstPoint = relativePositions.get(0);
    layer.curveVertex(firstPoint.x + centerPos.x, firstPoint.y + centerPos.y);

    PVector nextFirstPoint = relativePositions.get(1);
    layer.curveVertex(nextFirstPoint.x + centerPos.x, nextFirstPoint.y + centerPos.y);

    layer.endShape();
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
