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

boolean cameraInited = false;

PShader shader;
PImage prevFrame;
PImage masterCanvas;

PGraphics px;
PGraphics pg;

boolean shouldResetBackground = true;
int prevResetTime = 0;

float lowerThreshold = 0.15;
float higherThreshold = 0.2;

int resetInterval = 80 * 1000;
boolean isResetAtRegularInterval = true;

Slider s_lowerThreshold;
Slider s_higherThreshold;
Button b_resetBackground;
Toggle t_isResetAtRegularInterval;
Slider s_resetInterval;

String description = "Subtracts current pixel value from the background pixel. If the difference is big enough, keep the current pixel value on screen.";
String name = "Background Subtraction";
String author = "Hye Min Cho";

int guiPositionX = 55;

int drawSize = 1024;

void setup(){
  //fullScreen(P2D, SPAN);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  startWebCam();
  
  createGUI();

  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  shader = loadShader("backgroundSubtraction.frag");
  shader.set("resolution", float(drawSize), float(drawSize));

  // Init masterCanvas
  masterCanvas = createImage(drawSize, drawSize, RGB);
  masterCanvas = pg.get();

  prevFrame = pg.get();
}

void destroy(){
  println("Destroy " + name);
  removeGUI();

  px.resetShader();
  shader = null;
  prevFrame = null;
  masterCanvas = null;

}

void update() {
  updateGUI();
  if (shouldResetBackground && cameraInited){
    masterCanvas = pg.get();
    prevFrame = pg.get();
    shouldResetBackground = false;
  }

  if(((millis() - prevResetTime) > resetInterval) && isResetAtRegularInterval){
    prevResetTime = millis();
    shouldResetBackground = true;
  }
}

void draw() {
  background(0);
  grabCamImage();
  
  update();
  
  px.beginDraw();
  px.tint(255);
  px.image(pg, 0, 0);
  shader.set("prevTexture", prevFrame);
  shader.set("masterTexture", masterCanvas);
  shader.set("lowerThreshold", lowerThreshold);
  shader.set("higherThreshold", higherThreshold);
  px.filter(shader);
  //px.background(150);
  px.endDraw();
  
  masterCanvas = px.get();

  image(px, 600, 0);
}

void createGUI(){
  print(cp5);
  s_lowerThreshold = cp5.addSlider("Lower_Treshold")
    .setPosition(guiPositionX, 150)
    .setSize(400, 30)
    .setRange(0.00, 0.5)
    .setValue(0.15);

  s_higherThreshold = cp5.addSlider("Higher_Threshold")
    .setPosition(guiPositionX, 250)
    .setSize(400, 30)
    .setRange(0.00, 0.7)
    .setValue(0.25);

  b_resetBackground = cp5.addButton("Reset_Background")
   .setPosition(guiPositionX, 300)
   .setSize(100, 30)
   .onPress(new CallbackListener() { // a callback function that will be called onPress
    public void controlEvent(CallbackEvent theEvent) {
      shouldResetBackground = true;
    }
  });

  t_isResetAtRegularInterval = cp5.addToggle("Is_Reset_At_Regular_Interval")
   .setPosition(guiPositionX,350)
   .setSize(50,20)
   .setValue(true)
   .setMode(ControlP5.SWITCH)
   ;

   s_resetInterval = cp5.addSlider("Reset_Interval")
    .setPosition(guiPositionX, 400)
    .setSize(400, 30)
    .setRange(1, 300)
    .setValue(80);
}

void updateGUI(){
  lowerThreshold = s_lowerThreshold.getValue();
  higherThreshold = s_higherThreshold.getValue();
  resetInterval = floor(s_resetInterval.getValue() * 1000);

}

void removeGUI(){
  cp5.remove("Lower_Treshold");
  cp5.remove("Higher_Threshold");
  cp5.remove("Reset_Background");
  cp5.remove("Is_Reset_At_Regular_Interval");
  cp5.remove("Reset_Interval");
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
    cameraInited = true;
  }
}
