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

Slider blockSizeSlid;

String description = "Splits the image into squares and plays back pixels from previous frames. Blocks which are farther to the right will have older pixels than those farther to the left. Within the blocks however there is a similar relationship which inverts at the diagonal going from lower left to top right.";
String name = "Delay";
String author = "eric";

int drawSize = 1024;
int guiPositionX = 55;
int GUIStartHeight = 50;
int GUISliderHeight = 30;

int blockSize = 30;
ArrayList <PImage> frames;
int IMG_WIDTH = drawSize;
int IMG_HEIGHT = drawSize;
PImage lastFrame;
int MaxFrames = (drawSize/blockSize)+1;

void setup(){
  println("Create " + name);
  size(1624, 1024, P2D);
  startWebCam();
  
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  lastFrame = createImage(pg.width, pg.height, RGB);
  frames = new ArrayList<PImage>();

  blockSizeSlid = cp5.addSlider("blockSize")
   .setPosition(guiPositionX, GUIStartHeight)
   .setSize(400, GUISliderHeight)
   .setRange(20,60) // values can range from big to small as well
   .setValue(60)
   .setSliderMode(Slider.FLEXIBLE);
}

void destroy (){
  cp5.remove("blockSize");

  frames = null;
  lastFrame = null;
}

void update() {
  blockSize = floor(blockSizeSlid.getValue());
  int MaxFrames = (height/blockSize)+1;
  PImage img = createImage(pg.width, pg.height, RGB);
  pg.loadPixels();
  arrayCopy(pg.pixels, img.pixels);
  frames.add(img);
  while (frames.size() > MaxFrames) {
    frames.remove(0);
  }

}

void displayGUI() {
  //displayGUI(lastFrame);
}

void draw() {
  background(0);
  grabCamImage();
  update();
  
  int currentImage = 0;
  //PImage NewImg = createImage(pg.width, pg.height, RGB);
  lastFrame.loadPixels();
  int absSize = frames.size();

   for(int i = 0; i < frames.size(); i++){
    frames.get(i).loadPixels();
  }

  for(int y = 0 ; y < IMG_HEIGHT; y++){
   int yWithd = y * IMG_WIDTH;
   for (int x = 0; x < IMG_WIDTH; x++){
     int frame = floor((x+y%(blockSize*2))/blockSize)%absSize;
     int pixel = x+yWithd;
     if(frame < frames.size()){
       lastFrame.pixels[pixel] = frames.get(frame).pixels[pixel];
     }
   }
  }

/*    for (int y = 0; y < IMG_HEIGHT; y+=blockSize) {
    if (currentImage < frames.size()) {
      PImage img = (PImage)frames.get(currentImage);

      if (img != null) {
        img.loadPixels();

        for (int x = 0, skip = 50; x < IMG_WIDTH; x++) {
          if (x%blockSize == 0) {
            skip++;
          }
          for (int i = 0; i < blockSize; i++) {
            lastFrame.pixels[(x + (y + i + (skip*blockSize)) * IMG_WIDTH)%absSize] = img.pixels[(x + (y + i+ (skip*blockSize)) * IMG_WIDTH)%absSize];
          }
        }
      }

      currentImage++;
    } else {
      break;
    }

  }*/
  lastFrame.updatePixels();

  image(lastFrame, 600, 0);

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
