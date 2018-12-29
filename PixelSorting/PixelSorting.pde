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

PGraphics firstPass;
PGraphics secondPass;
PGraphics thirdPass;

PShader firstFrag;
PShader secondFrag;
PShader thirdFrag;

String description = "Sorting pixels from bottom to top based on their brightness.";
String name = "Pixel Sorting";
String author = "Stalgia Grigg";

int drawSize = 1024;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  firstPass = createGraphics(px.width, px.height, P2D);
  secondPass = createGraphics(px.width, px.height, P2D);
  thirdPass = createGraphics(px.width, px.height, P2D);

  firstFrag = loadShader("first.glsl");
  secondFrag = loadShader("second.glsl");
  thirdFrag = loadShader("third.glsl");

  firstFrag.set("uResolution", px.width, px.height);
  secondFrag.set("uResolution", px.width, px.height);
  thirdFrag.set("uResolution", px.width, px.height);

}

void destroy() {
  println("Destroy " + name);
  px.resetShader();
  firstPass = null;
  secondPass = null;
  thirdPass = null;

  firstFrag = null;
  secondFrag = null;
  thirdFrag = null;
}

void update() {
  float num = millis();
  firstFrag.set("uTime", num);

  firstPass.beginDraw();
  firstFrag.set("uSecondPass", secondPass);
  filter(firstFrag);
  //img1.image(startImg);
  firstPass.endDraw();

  secondPass.beginDraw();
  secondFrag.set("uTexture", pg);
  filter(secondFrag);
  secondPass.endDraw();

  thirdPass.beginDraw();
  thirdFrag.set("uFirstPass", firstPass);
  thirdFrag.set("uSecondPass", secondPass);
  filter(thirdFrag);
  thirdPass.endDraw();

}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  px.beginDraw();
  px.image(thirdPass, 0, 0);
  //px.line(0, 0, px.width, px.height);
  px.endDraw();

  image(px,600,0);
  displayInfo();
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
