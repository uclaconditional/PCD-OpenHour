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

// Note: rewrite this without the Array List

ArrayList frames;
int signal = 0;
int numRows = 4;

//PImage img;

String name = "Time Displacement";
String author = "Unknown Author";
String description = "Keeps a buffer of video frames in memory and displays pixel rows taken from consecutive frames distributed over the y-axis\n\nFrom the Processing Examples";

int drawSize = 1024;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  px.beginDraw();
  px.background(0);
  px.endDraw();
  frames = new ArrayList();
  //img = createImage(pg.width, pg.height, RGB);
}

void destroy() {
  println("Destroy " + name);
  frames = null;
  //img = null;
}

void newFrame() {
  // Copy the current video frame into an image, so it can be stored in the buffer
  PImage img = createImage(pg.width, pg.height, RGB);
  pg.loadPixels();
  arrayCopy(pg.pixels, img.pixels);

  frames.add(img);

  // Once there are enough frames, remove the oldest one when adding a new one
  if (frames.size() > pg.height/numRows) {
    frames.remove(0);
  }
}

void update() {
}

void draw() {
  background(0);
  update();
  newFrame();
  grabCamImage();
  
  // Set the image counter to 0
  int currentImage = 0;

  px.beginDraw();
  px.loadPixels();

  // Begin a loop for displaying pixel rows of 4 pixels height
  for (int y = 0; y < pg.height; y += numRows) {
    // Go through the frame buffer and pick an image, starting with the oldest one
    if (currentImage < frames.size()) {
      PImage img = (PImage)frames.get(currentImage);

      if (img != null) {
        img.loadPixels();

        // Note: why not use a texture do to this?
        // Put 4 rows of pixels on the screen
        for (int x = 0; x < pg.width; x++) {
          px.pixels[x + y * px.width] = img.pixels[x + y * img.width];
          px.pixels[x + (y + 1) * px.width] = img.pixels[x + (y + 1) * img.width];
          px.pixels[x + (y + 2) * px.width] = img.pixels[x + (y + 2) * img.width];
          px.pixels[x + (y + 3) * px.width] = img.pixels[x + (y + 3) * img.width];
          //px.pixels[x + (y + 4) * px.width] = img.pixels[x + (y + 4) * img.width];
          //px.pixels[x + (y + 5) * px.width] = img.pixels[x + (y + 5) * img.width];
          //px.pixels[x + (y + 6) * px.width] = img.pixels[x + (y + 6) * img.width];
          //px.pixels[x + (y + 7) * px.width] = img.pixels[x + (y + 7) * img.width];
          //px.pixels[x + (y + 8) * px.width] = img.pixels[x + (y + 8) * img.width];
          //px.pixels[x + (y + 9) * px.width] = img.pixels[x + (y + 9) * img.width];
        }
      }

      // Increase the image counter
      currentImage++;
    } else {
      break;
    }
  }

  px.updatePixels();
  px.endDraw();

  image(px, 600, 0);
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
