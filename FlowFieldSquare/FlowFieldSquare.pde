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

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwFlowField;
import com.thomasdiewald.pixelflow.java.sampling.DwSampling;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;
import com.thomasdiewald.pixelflow.java.softbodydynamics.DwPhysics;
import com.thomasdiewald.pixelflow.java.softbodydynamics.constraint.DwSpringConstraint;
import com.thomasdiewald.pixelflow.java.softbodydynamics.constraint.DwSpringConstraint2D;
import com.thomasdiewald.pixelflow.java.softbodydynamics.particle.DwParticle2D;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

int drawSize = 1024;

int blockSize = 10;
int num = 0;
int IMG_WIDTH = drawSize;
int IMG_HEIGHT = drawSize;
PImage lastFrame;
PGraphics2D pg_src;
PGraphics2D pg_render;
PGraphics2D pg_luminance;
PGraphics2D pg_bloom;
PGraphics2D pg_oflow;

DwFilter filter;
DwOpticalFlow opticalflow;
float[] flow_velocity = new float[IMG_WIDTH * IMG_WIDTH * 2];

int sample_num = 200;
Slider gridSize;

String description = "Gets the pixel velocity, that is the change in color value of the pixel and draws a rectangle with the width and height equivalent to the square of the velocity and with a fill of the color of the pixel. A pixel going from white to black would be drawn much larger, etc.";
String name = "Flow Field, Square";
String author = "eric";

int guiPositionX = 55;
int GUISliderHeight = 35;
int GUIStartHeight = 55;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  lastFrame = createImage(pg.width, pg.height, RGB);

  gridSize = cp5.addSlider("Grid Size")
     .setPosition(guiPositionX, GUIStartHeight)
     .setSize(400, GUISliderHeight)
     .setRange(5,25) // values can range from big to small as well
     .setValue(10)
     .setSliderMode(Slider.FLEXIBLE);

  println("Create " + name);
  px.beginDraw();
  px.background(0);
  px.endDraw();
  // main library context
  DwPixelFlow context = new DwPixelFlow(this);


  // PixelFlow imageprocssing
  pg_src = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_src.noSmooth();

  filter = new DwFilter(context);

  opticalflow = new DwOpticalFlow(context, px.width, px.height);
  opticalflow.param.flow_scale = 50;
  opticalflow.param.threshold = 5.0f;

  pg_oflow = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_oflow.smooth(4);

  pg_render = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_render.smooth(8);

  pg_luminance = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_luminance.smooth(8);

  pg_bloom = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_bloom.smooth(0);


}

void destroy() {
  cp5.remove("Grid Size");
  println("Destroy " + name);
}

 int getFrameDelay(color c, int max){
  int frame = floor((red(c)/255) * max) ;
  return frame;
}

void update() {
  blockSize = (int)gridSize.getValue();


  pg_src.beginDraw();
  pg_src.blendMode(REPLACE);
  //if(frames.size() > 0){
  //  pg_src.image(frames.get(frameCount % frames.size()), 0, 0);
  //} else {
  //  pg_src.image(pg, 0, 0);
  //}
  pg_src.image(pg, 0, 0);
  pg_src.endDraw();

  //if (frameCount % 3 == 0){
    opticalflow.update(pg_src);
    flow_velocity = opticalflow.getVelocity(flow_velocity);
  //}

}

void draw() {
  background(0);
  update();
  grabCamImage();

  px.beginDraw();
  pg.loadPixels();
  rectMode(CENTER);
  strokeWeight(0);
  stroke(0);
  for(int x = 0; x < IMG_WIDTH/blockSize; x++){
      for(int y = 0; y < IMG_HEIGHT/blockSize; y++){
         fill(pg.pixels[x*blockSize + y * IMG_WIDTH *blockSize]);
         float pixSize = getPixelSize(x,y);
         rect(x * blockSize, y * blockSize, pixSize, pixSize);
      }
  }
  rectMode(CORNER);
  px.endDraw();

  image(px, 600, 0);
  
  displayInfo();

}

float getPixelSize(int x, int y){
  float size = 5 + sqrt(flow_velocity[flow_velocity.length - 1 -((IMG_WIDTH -(x*blockSize) + y * IMG_WIDTH *blockSize)*2)])*40;
  return size;
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
