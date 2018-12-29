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

PGraphics2D pg_src;
PGraphics2D pg_render;
PGraphics2D pg_luminance;
PGraphics2D pg_bloom;
PGraphics2D pg_oflow;

DwFilter filter;
DwOpticalFlow opticalflow;
float[] flow_velocity = new float[(int)(width) * (int)(height) * 2];

int sample_num = 200;

int viewport_w = 1080;
int viewport_h = 1080;
int viewport_x = 230;
int viewport_y = 0;

int drawSize = 1024;

int blockSize = 10;
int num = 0;
ArrayList <PImage> frames;
int IMG_WIDTH = drawSize;
int IMG_HEIGHT = drawSize;
PImage lastFrame;

String description = "Keeps a buffer of frames of the last few seconds and loops through that while comparing the value of the pixels to that of the current frame. The overlaying colors come from the value difference.";
String name = "Flow Field";
String author = "eric";

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  frames = new ArrayList<PImage>();
  lastFrame = createImage(pg.width, pg.height, RGB);

  surface.setLocation(viewport_x, viewport_y);

  // main library context
  DwPixelFlow context = new DwPixelFlow(this);

  // physics object
  //physics = new DwPhysics<DwParticle2D>(param_physics);

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
  println("Destroy " + name);
  blendMode(BLEND);   // Default
   pg_src = null;
   pg_render = null;
   pg_luminance = null;
   pg_bloom = null;
   pg_oflow = null;
   filter = null;
   opticalflow = null;
}

 int getFrameDelay(color c, int max){
  int frame = floor((red(c)/255) * max) ;
  return frame;
}

void update() {

  PImage img = createImage(pg.width, pg.height, RGB);
  pg.loadPixels();
  arrayCopy(pg.pixels, img.pixels);
  frames.add(img);
  if (frames.size() > height/blockSize) {
    frames.remove(0);
  }


  pg_src.beginDraw();
  pg_src.blendMode(REPLACE);
  if(frames.size() > 0){
    pg_src.image(frames.get(frameCount % frames.size()), 0, 0);
  } else {
    pg_src.image(pg, 0, 0);
  }

  pg_src.endDraw();

  //if (frameCount % 3 == 0){
    opticalflow.update(pg_src);
    //flow_velocity = opticalflow.getVelocity(flow_velocity);
  //}

}

void draw() {
  background(0);
  update();
  grabCamImage();


    pg_oflow.beginDraw();
    pg_oflow.clear();
    // background(0);
    pg_oflow.endDraw();

    opticalflow.param.display_mode = 0;
    opticalflow.renderVelocityShading(pg_oflow);


  filter.bloom.param.mult   = 0.8;
  filter.bloom.param.radius = 0.4;
  filter.bloom.apply(pg_oflow, pg_bloom, pg_oflow);
  px.beginDraw();


    px.image(pg, 0, 0);
    px.blendMode(LIGHTEST);
    if(frames.size() > 0){
      px.image(frames.get(frameCount % frames.size()), 0, 0);
    };
    px.blendMode(ADD);
    px.image(pg_oflow, 0, 0);
    px.blendMode(REPLACE);
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
