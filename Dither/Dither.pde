
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

// shader-based
// Based on Dithering on GPU by Alex Charlton
// Source: http://alex-charlton.com/posts/Dithering_on_the_GPU/

import processing.video.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwBackgroundSubtraction;
import controlP5.*;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

PShader pShader;

PGraphics2D pg_src;
PGraphics2D pg_sub;

int scale = 4;

String description = "Ordered dithering algorithm demo";
String name = "Dither";
String author = "Alex Charlton, amc";

int drawSize = 1024;


void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();

  pShader = loadShader("data/dither.glsl");

  pg_src = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_src.noSmooth();

  // Disables trilinear texture filtering on px and pg_src
  // and sets filter mode to nearest.
  hint(DISABLE_TEXTURE_MIPMAPS);
  ((PGraphicsOpenGL)px).textureSampling(2);
  ((PGraphicsOpenGL)pg_src).textureSampling(2);

  createGUI();
}

void destroy() {
  println("Destroy " + name);
  px.resetShader();
  px.blendMode(BLEND);

  pg_src.resetShader();
  pg_src = null;

  pg_sub = null;
  pShader = null;

  removeGUI();

  // Re-enables trilinear texture filtering on px and pg_src.
  hint(ENABLE_TEXTURE_MIPMAPS);
  ((PGraphicsOpenGL)px).textureSampling(5);
  //((PGraphicsOpenGL)pg_src).textureSampling(5);
}

void update() {
}

void draw() {
  background(0);
  update();
  grabCamImage();
  setShaderParameters();

  PImage temp = pg.get(0,0,px.width,px.height);
  temp.resize(px.width/scale, px.height/scale);

  pg_src.beginDraw();
  pg_src.shader(pShader);
  pg_src.blendMode(REPLACE);
  pg_src.image(temp, 0, 0);
  pg_src.endDraw();

  px.beginDraw();
  px.image(pg_src, 0, 0, px.width*scale, px.height*scale);
  px.endDraw();

  image(px, 600, 0);

  // stats, to the title window
  String txt_fps = String.format(getClass().getName()+ "   [frame %d]   [fps %6.2f]", frameCount, frameRate);
  surface.setTitle(txt_fps);
  
  displayInfo();
}

void createGUI(){
}

void updateGUI(){

}

void removeGUI(){

}

void setShaderParameters() {
  //
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
