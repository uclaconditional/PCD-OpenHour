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
 * Modified for PCD (26 Dec 2018)
 */

import processing.video.*;
// import codeanticode.syphon.*;
import controlP5.*;

ControlP5 cp5;
Capture cam;

PShader   edgeShader;
PShader   csbAdjustShader;

PGraphics pg;  // Stores the incoming image
PGraphics px;  // Main pixels to use for the module

PGraphics pg_curr;
PGraphics pg_prev;

int       sobelMode;
int       alphaMode;

float     intensity;
float     blackness;
float     gamma;
float     contrast;
float     contrastLfoAmp;
float     contrastLfoPeriod;
float     saturation;
float     brightness;
float     zoom;

Slider    s_sobelMode;
Slider    s_alphaMode;
Slider    s_intensity;
Slider    s_blackness;
Slider    s_gamma;
Slider    s_contrast;
Slider    s_contrastLfoAmp;
Slider    s_contrastLfoPeriod;
Slider    s_saturation;
Slider    s_brightness;
Slider    s_zoom;


String description = "Blown out sobel edge detection feeding back into itself, while shrinking.";
String name = "Cascading Edges";
String author = "L05";
Boolean titleIsBlack = true;

int drawSize = 1024;
int guiPositionX = 55;
int station = 1;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  startWebCam();
  createGUI();
  setGUI();

  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);

  px.noTint();
  px.resetShader();

  pg_curr = createGraphics(drawSize, drawSize, P2D);
  pg_prev = createGraphics(drawSize, drawSize, P2D);

  sobelMode         = 1;
  alphaMode         = 2;
  intensity         = 2.22;
  blackness         = 2.42;
  gamma             = 0.85;
  contrast          = 1.2;
  contrastLfoAmp    = 0.1;
  contrastLfoPeriod = 5;
  saturation        = 1.0;
  brightness        = 1.0;
  zoom              = 0.999;


  edgeShader = loadShader("edge.frag");
  edgeShader.set("u_mode", sobelMode);
  edgeShader.set("u_intensity", intensity);
  edgeShader.set("u_blackness", blackness);
  edgeShader.set("u_gamma", gamma);
  edgeShader.set("u_alpha", alphaMode);

  csbAdjustShader = loadShader("csb_adjust_luma.frag");
  csbAdjustShader.set("u_contrast", contrast);
  csbAdjustShader.set("u_saturation", saturation);
  csbAdjustShader.set("u_brightness", brightness);
}

void destroy() {
  println("Destroy " + name);
  removeGUI();

  px.resetShader();
  px.imageMode(CORNER);


  pg_curr         = null;
  pg_prev         = null;
  edgeShader      = null;
  csbAdjustShader = null;
}

void update() {
  updateGUI();

  edgeShader.set("u_mode", sobelMode);
  edgeShader.set("u_intensity", intensity);
  edgeShader.set("u_blackness", blackness);
  edgeShader.set("u_gamma", gamma);
  edgeShader.set("u_alpha", alphaMode);

  float contrastMod = contrastLfoAmp * ( sin(millis()/(contrastLfoPeriod*1000.f)) + sin(3*millis()/(contrastLfoPeriod*1000.f))/3 );

  csbAdjustShader.set("u_contrast", contrast + contrastMod);
  csbAdjustShader.set("u_saturation", saturation);
  csbAdjustShader.set("u_brightness", brightness);
}

void draw() {
  background(0);
  grabCamImage();
  update();
  
  
  pg_curr.beginDraw();
  pg_curr.shader(csbAdjustShader);
  pg_curr.image(pg_prev, 0, 0);
  pg_curr.shader(edgeShader);
  pg_curr.image(pg, 0, 0);
  pg_curr.endDraw();

  pg_prev.beginDraw();
  pg_prev.pushMatrix();
  pg_prev.imageMode(CENTER);
  pg_prev.translate(px.width/2, px.height/2);
  pg_prev.rotate(radians(0.02)*sin(frameCount*0.0001));
  pg_prev.image(pg_curr, 0, 0, px.width*zoom, px.height*zoom);
  pg_prev.popMatrix();
  pg_prev.endDraw();

  px.beginDraw();
  px.imageMode(CORNER);
  px.image(pg_curr, 0, 0);
  px.endDraw();

  image(px, 600, 0);
}

void createGUI() {
  s_sobelMode = cp5.addSlider("sobel_mode")
    .setPosition(guiPositionX, 100)
    .setSize(400, 30)
    .setRange(0, 4)
    ;

  s_alphaMode = cp5.addSlider("alpha_mode")
    .setPosition(guiPositionX, 150)
    .setSize(400, 30)
    .setRange(0, 2)
    ;

  s_intensity = cp5.addSlider("edge_intensity")
    .setPosition(guiPositionX, 200)
    .setSize(400, 30)
    .setRange(0, 10)
    ;

  s_blackness = cp5.addSlider("blackness")
    .setPosition(guiPositionX, 250)
    .setSize(400, 30)
    .setRange(0, 10)
    ;

  s_gamma = cp5.addSlider("gamma")
    .setPosition(guiPositionX, 300)
    .setSize(400, 30)
    .setRange(0, 5)
    ;

  s_contrast = cp5.addSlider("contrast")
    .setPosition(guiPositionX, 350)
    .setSize(400, 30)
    .setRange(0, 5)
    ;

  s_contrastLfoAmp = cp5.addSlider("contrast_LFO_amp")
    .setPosition(guiPositionX, 400)
    .setSize(400, 30)
    .setRange(0, 1)
    ;

  s_contrastLfoPeriod = cp5.addSlider("contrast_LFO_period")
    .setPosition(guiPositionX, 450)
    .setSize(400, 30)
    .setRange(0, 10)
    ;

  s_saturation = cp5.addSlider("saturation_")
    .setPosition(guiPositionX, 500)
    .setSize(400, 30)
    .setRange(0.0, 5.0)
    ;

  s_brightness = cp5.addSlider("brightness_")
    .setPosition(guiPositionX, 550)
    .setSize(400, 30)
    .setRange(0, 20)
    ;

  s_zoom = cp5.addSlider("zoom")
    .setPosition(guiPositionX, 600)
    .setSize(400, 30)
    .setRange(0, 1)
    ;
}

void setGUI() {
  if (station == 1) {
    s_sobelMode.setValue(4);
    s_alphaMode.setValue(2);
    s_intensity.setValue(2.22);
    s_blackness.setValue(2.42);
    s_gamma.setValue(0.85);
    s_contrast.setValue(1.06);
    s_contrastLfoAmp.setValue(0.14);
    s_contrastLfoPeriod.setValue(5);
    s_saturation.setValue(1.6);
    s_brightness.setValue(1);
    s_zoom.setValue(0);
  } else if (station == 2) {
    s_sobelMode.setValue(4);
    s_alphaMode.setValue(2);
    s_intensity.setValue(2.22);
    s_blackness.setValue(2.42);
    s_gamma.setValue(0.85);
    s_contrast.setValue(1.2);
    s_contrastLfoAmp.setValue(0.14);
    s_contrastLfoPeriod.setValue(5);
    s_saturation.setValue(1.6);
    s_brightness.setValue(1);
    s_zoom.setValue(0);
  }
}

void updateGUI() {
  sobelMode         = round(s_sobelMode.getValue());
  alphaMode         = round(s_alphaMode.getValue());
  intensity         = s_intensity.getValue();
  blackness         = s_blackness.getValue();
  gamma             = s_gamma.getValue();
  contrast          = s_contrast.getValue();
  contrastLfoAmp    = map(s_contrastLfoAmp.getValue(), 0, 1, 0, 0.25);
  contrastLfoPeriod = s_contrastLfoPeriod.getValue();
  saturation        = s_saturation.getValue();
  brightness        = s_brightness.getValue();
  zoom              = map(s_zoom.getValue(), 0, 1, 0.999, 0.95);
}

void removeGUI() {
  cp5.remove("sobel_mode");
  cp5.remove("alpha_mode");
  cp5.remove("edge_intensity");
  cp5.remove("blackness");
  cp5.remove("gamma");
  cp5.remove("contrast");
  cp5.remove("contrast_LFO_amp");
  cp5.remove("contrast_LFO_period");
  cp5.remove("saturation_");
  cp5.remove("brightness_");
  cp5.remove("zoom");
}

class Presets {

  // https://processing.org/reference/saveJSONObject_.html
  // https://processing.org/reference/JSONObject.html


  Presets() {

  }
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
