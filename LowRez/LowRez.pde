
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
 
 /*
 * TODO:
 *
 * - Add radio buttons to select between different resolutions, see the xs[] and ys[] arrays
 *
 * DONE:
 *
 * - Changed the minimum resolution from 1 to 2 to increase frame rate
 */

// Divisors for 1080
// 1, 2, 3, 4, 5, 6, 8 , 9, 10, 12, 15, 18, 20, 24, 27, 30, 36, 40, 45, 54, 60, 72, 90, 108, 120, 135, 180, 216, 270, 360, 540, 1080

import processing.video.*;
import controlP5.*;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

int[] xs = {90, 2, 20, 45, 15};
int[] ys = {2, 90, 20, 10, 60};

int xdim = xs[0];
int ydim = ys[0];
int aa = 1;

RadioButton r1;

String description = "Gets colors from the video capture buffer to recreate the video in lower resolutions. Embedded loops are used to move through the image across the x- and y-axes to get the colors from the upper-left to the lower-right corner.";
String name = "Pixel Sampling";
String author = "Casey REAS";

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
  
  // Throws NullPointerException for some reason...
  // Commenting out should not affect the result since
  // default blend Mode is BLEND
  //px.blendMode(BLEND);
  px.beginDraw();
  px.background(0);
  px.endDraw();
  createGUI();
}

void destroy() {
  println("Destroy " + name);
  px.noTint();
  removeGUI();
}

void createGUI() {
  r1 = cp5.addRadioButton("radioButton")
       .setPosition(guiPositionX, 120)
       .setSize(40,20)
       .addItem("Horizonal", 0)
       .addItem("Vertical", 1)
       .addItem("Square", 2)
       .addItem("Horizonal_alt", 3)
       .addItem("Vertical_alt", 4)
       ;
}

void removeGUI() {
  cp5.remove("radioButton");
}

void update() {
  aa = int(r1.getValue());
}

void draw() {
  background(0);
  update();
  grabCamImage();

  xdim = xs[aa];
  ydim = ys[aa];

  px.beginDraw();
  px.noStroke();
  px.tint(255, 24);
  px.beginShape(QUADS);
  px.texture(pg);
  for (int y = 0; y < height; y += ydim) {
    for (int x = 0; x < width; x += xdim) {
      px.vertex(x, y, x, y+ydim/2);
      px.vertex(x+xdim, y, x+0.1, y+ydim/2);
      px.vertex(x+xdim, y+ydim, x+0.1, y+ydim/2+0.1);
      px.vertex(x, y+ydim, x, y+ydim/2+0.1);
    }
  }
  px.endShape();
  px.endDraw();

  image(px, 600, 0);  // Draw to center of main screen
  
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
