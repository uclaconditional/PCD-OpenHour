
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

PGraphics canvas;
PGraphics firstPass;

PShader firstFrag;
PShader mainFrag;

float delay;

Slider s_delay;

String description = "Each pixel receives is made up of majority percentage of the camera's past hue and a tiny percentage of the current hue. This creates a long-exposure or ghosting effect";
String name = "Long Exposure";
String author = "Stalgia Grigg";

int drawSize = 1024;
int guiPositionX = 55;
int GUIStartHeight = 55;
int GUISliderHeight = 35;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  canvas    = createGraphics(pg.width, pg.height, P2D);
  firstPass = createGraphics(pg.width, pg.height, P2D);

  firstFrag = loadShader("firstpass.frag");
  mainFrag  = loadShader("main.frag");

  mainFrag.set("uResolution", pg.width, pg.height);
  firstFrag.set("uResolution", pg.width, pg.height);
  createGUI();
}

void destroy() {
  println("Destroy " + name);
  removeGUI();
  px.resetShader();

  canvas = null;
  firstPass = null;
  firstFrag = null;
  mainFrag = null;
}

void update() {
  updateGUI();
  firstPass.beginDraw();
  firstFrag.set("firstPass", firstPass);
  firstFrag.set("uTexture", pg);
  firstFrag.set("uDelay", delay);
  firstPass.shader(firstFrag);
  firstPass.image(pg,0,0);
  firstPass.endDraw();

  canvas.beginDraw();
  mainFrag.set("firstPass", firstPass);
  canvas.shader(mainFrag);
  canvas.image(firstPass, 0,0);
  canvas.endDraw();
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  px.beginDraw();
  px.image(canvas,0,0);
  px.endDraw();
  image(px, 600, 0);
  
  displayInfo();
}

void updateGUI() {
  delay = s_delay.getValue();
}

void createGUI() {
  s_delay = cp5.addSlider("density")
   .setPosition(guiPositionX,GUIStartHeight)
   .setSize(400, GUISliderHeight)
   .setRange(0.8,0.99) // values can range from big to small as well
   .setValue(0.95);
}

void removeGUI(){
    cp5.remove("density");
}

 void displayInfo(){
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
