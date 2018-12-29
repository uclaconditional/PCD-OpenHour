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

PShader fdiff;
PGraphics lastFrame;

String description = "Draws the changes between two adjacent video frames. Compares the most recent pixel buffer with the prior pixel buffer and only displays the difference bewtween the two. The pixel values at the same coordinates (for the entire image) are subtracted from one another.";
String name = "Frame Difference";
String author = "Casey REAS";

int drawSize = 1024;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  lastFrame = createGraphics(pg.width, pg.height, P2D);
  lastFrame.beginDraw();
  lastFrame.background(255);
  lastFrame.image(pg, 0, 0);
  lastFrame.endDraw();
  fdiff = loadShader("diff.glsl");
  px.resetShader();
  // Throws NullPointerException for some reason...
  // In theory commenting the following line out shouldn't change
  // anything since the default blendMode is BLEND.
  //px.blendMode(BLEND);
  px.fill(255);
  //newFrame();
}

void destroy() {
  println("Destroy " + name);
  lastFrame = null;
  px.resetShader();
  fdiff = null;
}

void newFrame() {
  fdiff.set("u_current", pg);
  fdiff.set("u_past", lastFrame);

  lastFrame.beginDraw();
  lastFrame.tint(255, 26);
  lastFrame.image(pg, 0, 0);
  lastFrame.endDraw();
}

void update() {
}

void draw() {
  background(0);
  update();
  newFrame();
  grabCamImage();
  
  // Draw the shader
  px.beginDraw();
  px.shader(fdiff);
  px.rect(0, 0, pg.width, pg.height);
  px.resetShader();
  px.endDraw();

  image(px, 600, 0);
  displayInfo();
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
