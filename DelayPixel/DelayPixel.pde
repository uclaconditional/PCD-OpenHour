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

Slider s_bufferSize;
RadioButton r_colorName;
RadioButton r_sampleImage;

String description = "Keeps a buffer of frames of the last few seconds. It decides which pixel corresponding to the same pixel's position in the stack of frames by comparing the value of a pixel in a specific image. The higher the value the older the frame which will be chosen. We can determine what image to compare: the first the last or the last image it produced.";
String name = "DelayPixel";
String author = "eric";

int guiPositionX = 55;
int GUISliderHeight = 35;
int drawSize = 1024;

int blockSize = 10;
ArrayList <PImage> frames;
int IMG_WIDTH = drawSize;
int IMG_HEIGHT = drawSize;
int myBufferSize = 60;
PImage lastFrame;

void setup() {
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  createGUI();
  startWebCam();

  frames = new ArrayList<PImage>();
  lastFrame = createImage(pg.width, pg.height, RGB);

}
void destroy (){
  println("Destroy " + name);
  removeGUI();

  frames = null;
  lastFrame = null;

}

void update() {

  if(frameCount % 2 == 0 || frames.size() < 1){
    PImage img = createImage(pg.width, pg.height, RGB);
    pg.loadPixels();
    arrayCopy(pg.pixels, img.pixels);
    frames.add(img);
    while (frames.size() > myBufferSize) {
      frames.remove(0);
    }
  }
}

int getFrameDelayR(color c, int max){
  int frame = floor((brightness(c)/255) * max) ;
  return frame;
}
int getFrameDelayG(color c, int max){
  int frame = floor((brightness(c)/255) * max) ;
  return frame;
}
int getFrameDelayB(color c, int max){
  int frame = floor((brightness(c)/255) * max) ;
  return frame;
}
int getFrameDelayA(color c, int max){
  int frame = floor((brightness(c)/255) * max) ;
  return frame;
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  int numberOfFrames = frames.size()-1;
  lastFrame.loadPixels();
  for(int i = 0; i < frames.size(); i++){
    frames.get(i).loadPixels();
  }
  PImage sampleFrame;
  if(r_sampleImage.getArrayValue()[0] == 1){
    sampleFrame = lastFrame;
  } else if(r_sampleImage.getArrayValue()[1] == 1){
    sampleFrame = frames.get(frames.size()-1);
  } else {
    sampleFrame = frames.get(0);
  }

  sampleFrame.loadPixels();
  //for(int y = 0; y < IMG_HEIGHT; y++){
  //  for(int x = 0; x < IMG_WIDTH; x++ ){
  //    lastFrame.pixels[x+y*IMG_WIDTH] = frames.get(getFrameDelayR(lastFrame.pixels[x+y*IMG_WIDTH], numberOfFrames)).pixels[x+y*IMG_WIDTH];
  //  }
  //}
  int size = frames.size();
  if(size == 0){
  } else if(r_colorName.getArrayValue()[0] == 1){
    for(int y = 0; y < IMG_HEIGHT; y++){
      for(int x = 0; x < IMG_WIDTH; x++ ){
        lastFrame.pixels[x+y*IMG_WIDTH] = frames.get(getFrameDelayR(sampleFrame.pixels[x+y*IMG_WIDTH], numberOfFrames)).pixels[x+y*IMG_WIDTH];
      }
    }
  } else if(r_colorName.getArrayValue()[1] == 1){
    for(int y = 0; y < IMG_HEIGHT; y++){
      for(int x = 0; x < IMG_WIDTH; x++ ){
        lastFrame.pixels[x+y*IMG_WIDTH] = frames.get(getFrameDelayG(sampleFrame.pixels[x+y*IMG_WIDTH], numberOfFrames)).pixels[x+y*IMG_WIDTH];
      }
    }
  }else if(r_colorName.getArrayValue()[2] == 1){
    for(int y = 0; y < IMG_HEIGHT; y++){
      for(int x = 0; x < IMG_WIDTH; x++ ){
        lastFrame.pixels[x+y*IMG_WIDTH] = frames.get(getFrameDelayB(sampleFrame.pixels[x+y*IMG_WIDTH], numberOfFrames)).pixels[x+y*IMG_WIDTH];
      }
    }
  }else if(r_colorName.getArrayValue()[3] == 1){
     for(int y = 0; y < IMG_HEIGHT; y++){
      for(int x = 0; x < IMG_WIDTH; x++ ){
        lastFrame.pixels[x+y*IMG_WIDTH] = frames.get(getFrameDelayA(sampleFrame.pixels[x+y*IMG_WIDTH], numberOfFrames)).pixels[x+y*IMG_WIDTH];
      }
    }
  }else if(r_colorName.getArrayValue()[4] == 1){
     for(int y = 0; y < IMG_HEIGHT; y++){
      for(int x = 0; x < IMG_WIDTH; x++ ){
        lastFrame.pixels[x+y*IMG_WIDTH] = frames.get(floor(random(size-1))).pixels[x+y*IMG_WIDTH];
      }
    }
  }

  lastFrame.updatePixels();

  px.beginDraw();
  px.image(lastFrame, 0, 0);
  px.endDraw();

  image(px, 600, 0);
  // image(lastFrame, 420, 0);
  displayInfo();
}

void createGUI(){
  r_sampleImage = cp5.addRadioButton("Sample_Image")
     .setPosition(guiPositionX, 100)
     .setSize(50, 50)
     .addItem("Current Image", 0.0)
     .addItem("Last in buffer", 2.0)
     .addItem("First in buffer", 3.0)
     .setValue(0.0)
     .activate("Last in buffer");

  r_colorName = cp5.addRadioButton("Color_to_Sample")
     .setPosition(guiPositionX, 300)
     .setSize(50, 50)
     .addItem("Red", 0.0)
     .addItem("Green", 2.0)
     .addItem("Blue", 3.0)
     .addItem("Brightness", 3.0)
     .addItem("Random", 4.0)
     .setValue(0.0)
     .activate("Brightness");

  s_bufferSize = cp5.addSlider("Buffer_Size")
     .setPosition(guiPositionX, 600)
     .setSize(400, GUISliderHeight)
     .setRange(5,60) // values can range from big to small as well
     .setValue(20)
     .setSliderMode(Slider.FLEXIBLE);

}

void updateGUI(){
  myBufferSize = int(s_bufferSize.getValue());

}

void removeGUI(){
  cp5.remove("Sample_Image");
  cp5.remove("Color_to_Sample");
  cp5.remove("Buffer_Size");

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
