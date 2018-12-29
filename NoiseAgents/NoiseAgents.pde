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

int drawSize = 1024;

PShader shader;

int imageInput2OutputRatio = 2;
int mainImageResolution = drawSize * imageInput2OutputRatio;
PGraphics mainImage;
PGraphics currImage;

int numWalkers = 500;
ArrayList<Walker> walkers;

float agentSpeed = 15.0;
int lineWidth = 1;

Slider s_agentSpeed;
Slider s_lineWidth;

String description = "The direction of each agent is changed according to the continuous noise value (Perlin Noise value) for that popsition. Image input color from where the each agent is at is drawn onto the screen at each frame.";
String name = "Perlin Noise Agents";
String author = "Hye Min Cho";

int guiPositionX = 55;

void setup(){
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  createGUI();

  walkers = new ArrayList<Walker>();

  mainImage = createGraphics(mainImageResolution, mainImageResolution, P2D);
  mainImage.beginDraw();
  mainImage.background(0);
  mainImage.endDraw();

  currImage = createGraphics(mainImageResolution, mainImageResolution, P2D);
  currImage.beginDraw();
  currImage.background(255, 255, 255);
  currImage.endDraw();

  shader = loadShader("noiseAgents.frag");
  shader.set("resolution", mainImageResolution, mainImageResolution);

  // Init all walkers
  for(int i = 0; i < numWalkers; i++){
   walkers.add(new Walker());
  }

}

void destroy(){
  println("Destroy " + name);
  removeGUI();

  mainImage.resetShader();
  mainImage = null;
  currImage = null;
  walkers = null;
  shader = null;

}

void update() {
  updateGUI();
  for(int i = 0; i < numWalkers; i++){
    Walker currWalker = walkers.get(i);
    currWalker.updatePos();
  }
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  currImage.beginDraw();
  currImage.background(255, 255, 255, 0);
  // currImage.
  for(int i = 0; i < numWalkers; i++){
    Walker currWalker = walkers.get(i);
    currWalker.drawPos(currImage);
  }
  currImage.endDraw();


  mainImage.beginDraw();
  mainImage.image(mainImage, 0, 0);  // switch to 2160, 1080
  shader.set("camera", pg);
  shader.set("currDots", currImage);
  mainImage.filter(shader);
  mainImage.endDraw();

  px.beginDraw();
  // px.background(0);
  px.image(mainImage, 0, 0, 1080, 1080);  // switch to 2160, 1080
  px.endDraw();

  image(px, 600, 0);
  displayInfo();
}

void createGUI(){
  s_agentSpeed = cp5.addSlider("Agent_Speed")
    .setPosition(guiPositionX, 150)
    .setSize(400, 30)
    .setRange(0.01, 30.0)
    .setValue(15.0);

  s_lineWidth = cp5.addSlider("Line_Width")
    .setPosition(guiPositionX, 200)
    .setSize(400, 30)
    .setRange(0.01, 30.0)
    .setValue(1.0);
}

void updateGUI(){
  agentSpeed = s_agentSpeed.getValue();
  lineWidth = int(s_lineWidth.getValue());

}

void removeGUI(){
  cp5.remove("Agent_Speed");
  cp5.remove("Line_Width");
}

class Walker{
PVector pos;
PVector prevPos;
float sizeDot = 2;
color col;

float noiseScale = 500;
float noiseStrength = 20.0;
 Walker(){
   pos = new PVector(random(mainImageResolution), random(mainImageResolution));
   prevPos = pos.copy();
   col = color(0, 0, 0);
 }

 void updatePos(){
   clampPos();
   prevPos = pos.copy();

   float angle = noise(pos.x/noiseScale, pos.y/noiseScale) * noiseStrength;
   pos.x += cos(angle) * agentSpeed;
   pos.y += sin(angle) * agentSpeed;
 }

 void drawPos(PGraphics layer){
   layer.pushStyle();
   layer.stroke(0);
   layer.strokeWeight(lineWidth);
   layer.line(prevPos.x, prevPos.y, pos.x, pos.y);
   layer.popStyle();
 }

 void clampPos(){
  if(pos.x < 0 || pos.x > mainImageResolution ||
     pos.y < 0 || pos.y > mainImageResolution){
       pos.x = random(mainImageResolution);
       pos.y = random(mainImageResolution);
      noiseStrength = random(20, 40);
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
