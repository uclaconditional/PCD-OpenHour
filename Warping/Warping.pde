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

PShader warpShader;
PShader swirlWarpShader;

int shaderInterval = 10 * 1000; // Time a shader stays on in miliseconds
float shaderAnimPerc = 0.2;
float maxDistortFactor = 0.08;
float maxRotation = 2.0;

boolean isSwirlShader = false;
int nextSetTime;

boolean isSwirlModeOn = false;
boolean isGridModeOn = true;

int gridDensity = 10;

Slider s_shaderInterval;
Slider s_maxDistortFactor;
Slider s_maxRotation;
Toggle t_swirlModeOn;
Toggle t_gridLineOn;
Slider s_gridDensity;

String description = "Image warping aims to remap the input camera image to a distorted space. This is achieved by working backwards and applying the reverse of this transformation to each output pixel and using it to interpolate color value from the input image.";
String name = "Matrix Warping";
String author = "Hye Min Cho";

int drawSize = 1024;
int guiPositionX = 55;
int GUIStartHeight = 55;
int GUIPadding = 60;
int GUIToggleHeight = 35;
int GUISliderHeight = 35;

void setup(){
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  createGUI();
  // Shader Init
  warpShader = loadShader("warping.glsl");
  warpShader.set("resolution", float(px.width), float(px.height));
  warpShader.set("distortFactor", 0.08);

  swirlWarpShader = loadShader("swirlWarping.glsl");
  swirlWarpShader.set("resolution", float(px.width), float(px.height));

  nextSetTime = millis() + shaderInterval;
}

void destroy(){
  println("Destroy " + name);
  removeGUI();

  px.resetShader();
  warpShader = null;
  swirlWarpShader = null;

}

void update() {
  updateGUI();

  float shaderAmt = 0;
  if(millis() < nextSetTime){
   float curr = currPhase();
   if(curr < shaderAnimPerc){         // If Fade In
     shaderAmt = 0.5 * sin((curr / shaderAnimPerc)*PI-0.5*PI) + 0.5;

   } else if (curr < 1.0 - shaderAnimPerc){  // If Middle
     shaderAmt = 1.0;

   } else {                                  // If Fade Out
     float fadeTime = 1.0 - ((curr - (1.0 - shaderAnimPerc)) / shaderAnimPerc);
     shaderAmt = 0.5 * sin(fadeTime*PI-0.5*PI) + 0.5;
   }
  } else {  // Switch shader
    isSwirlShader = !isSwirlShader;
    if (!isSwirlModeOn){
      isSwirlShader = false;
    }
    shaderAmt = 0;
    nextSetTime = millis() + shaderInterval;
  }

  setShaderAnim(shaderAmt);
}

void draw() {
  background(0);
  update();
  grabCamImage();

  if(isGridModeOn){
    drawGrid(pg);
  }

  px.beginDraw();
  px.tint(255);
  px.image(pg, 0, 0);
  if(isSwirlShader){
    px.shader(swirlWarpShader);
  } else {
    px.shader(warpShader);
  }
  px.endDraw();

  image(px, 600, 0);
  displayInfo();
}

void drawGrid(PGraphics layer){
  int step = px.width / (gridDensity + 1);
  layer.beginDraw();
  layer.stroke(0);
  layer.strokeWeight(1);
  for (int i = 0; i < gridDensity; i++){
    // Vertical lines
    layer.line(step * (i+1), -5, step * (i+1), px.height + 5);
    layer.line(-5, step * (i+1), px.height+5, step * (i+1));
  }
  layer.endDraw();

}

float currPhase(){  // Return how far we are along a phase (0.0 - 1.0)
  float result = 1.0 - (float(nextSetTime - millis()) / float(shaderInterval));
  return result;
}

void setShaderAnim(float effectStrength){
  if(!isSwirlShader || !isSwirlModeOn){
    float distort = lerp(0.0, maxDistortFactor, effectStrength);
    warpShader.set("distortFactor", distort);

  } else {
    float rot = lerp(0.0, maxRotation, effectStrength);
    float scale = lerp(1.0, 0.9, effectStrength);
    swirlWarpShader.set("amountRotation", rot);
    swirlWarpShader.set("imageScale", scale);
  }
}

void createGUI(){
  s_shaderInterval = cp5.addSlider("Shader_Switch_Interval")
    .setPosition(guiPositionX, GUIStartHeight)
    .setSize(400, GUISliderHeight)
    .setRange(1, 60)
    .setValue(10)
    ;

  s_maxRotation = cp5.addSlider("Swirl_Max_Rotation")
    .setPosition(guiPositionX, GUIStartHeight + GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(0.01, 10.0)
    .setValue(2.0)
    ;

  s_maxDistortFactor = cp5.addSlider("Elongate_Max_Distort")
    .setPosition(guiPositionX, GUIStartHeight + 2 * GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(0.08, 3.0)
    .setValue(0.08)
    ;

t_swirlModeOn = cp5.addToggle("Swirl_Mode")
   .setPosition(guiPositionX, GUIStartHeight + 3 * GUIPadding)
   .setSize(50,GUISliderHeight)
   .setValue(false)
   .setMode(ControlP5.SWITCH)
   ;

t_gridLineOn = cp5.addToggle("Grid_Line_Mode")
   .setPosition(guiPositionX,GUIStartHeight + 4 * GUIPadding)
   .setSize(50,GUIToggleHeight)
   .setValue(true)
   .setMode(ControlP5.SWITCH)
   ;

  s_gridDensity = cp5.addSlider("Grid_Density")
    .setPosition(guiPositionX, GUIStartHeight + 5 * GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(1, 150)
    .setValue(30)
    ;
 }

void updateGUI(){
  shaderInterval = floor(s_shaderInterval.getValue() * 1000.0);
  maxRotation = s_maxRotation.getValue();
  maxDistortFactor = s_maxDistortFactor.getValue();
  gridDensity = floor(s_gridDensity.getValue());
  isGridModeOn = t_gridLineOn.getBooleanValue();
  isSwirlModeOn = t_swirlModeOn.getBooleanValue();
}

void removeGUI(){
  cp5.remove("Shader_Switch_Interval");
  cp5.remove("Swirl_Max_Rotation");
  cp5.remove("Elongate_Max_Distort");
  cp5.remove("Swirl_Mode");
  cp5.remove("Grid_Density");
  cp5.remove("Grid_Line_Mode");
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
