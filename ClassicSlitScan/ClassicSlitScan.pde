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
Capture cam;

PGraphics px;
PGraphics pg;
int x = 0;

String description = "A 'slit scan' uses only one 'slit' from a camera image. This code uses one column of pixels from the center of the incoming video frame and continuosly draws it to the right of the prior column of pixels. When it reaches the right edge, it wraps back around to the left. A version of this technique was used in the Star Gate sequence in Stanley Kubrick's 2001.";
String name = "SlitScan";
String author = "Casey REAS";

int drawSize = 1024;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  startWebCam();
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  px.beginDraw();
  px.background(0);
  px.noTint();
  px.endDraw();
  x = 0;
  
}

void destroy() {
  println("Destroy " + name);
}

void newFrame() {
  x++;
  if (x >= px.width) {
    x = 0;
  }
  px.beginDraw();
  px.noStroke();
  px.beginShape();
  px.texture(pg);
  px.vertex(x, 0, px.width/2, 0);
  px.vertex(x+1, 0, px.width/2+1, 0);
  px.vertex(x+1, px.height, px.width/2+1, px.height);
  px.vertex(x, px.height, px.width/2, px.height);
  px.endShape();
  px.endDraw();
}

void draw() {
  background(0);
  grabCamImage();
  newFrame();
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
