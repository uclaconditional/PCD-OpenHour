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

PShader frag;
float t;
float a;
boolean light;

Slider s_bokehQuantity;
Slider s_timer;
Slider s_bokehSize;
Toggle t_light;

String description = "Gets the brightest or darkest regions from camera and repeats them in an animating shape around the central point of that group. This is based on the bokeh, which is an artifact of how out-of-focus regions are blurred by the aperture in traditional cameras.";
String name = "Bokeh";
String author = "Stalgia Grigg";

int guiPositionX = 55;

int drawSize = 1024;

int GUIStartHeight = 35;
int GUISliderHeight = 35;
int GUIPadding = 55;

void setup() {
  //fullScreen(P2D, SPAN);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  frag = loadShader("bokeh.frag");
  frag.set("uResolution", drawSize, drawSize);
  t = -4000;
  a = 0;
  light = false;

  createGUI();
}

void destroy() {
  println("Destroy " + name);
  px.resetShader();
  removeGUI();
  frag = null;
}


void update() {
  a = millis();
  frag.set("uTexture", pg);
  frag.set("uTime", a);
  frag.set("uBokehs", s_bokehQuantity.getValue());
  frag.set("light", t_light.getBooleanValue());
  frag.set("uTimer", s_timer.getValue());
  frag.set("uSize", s_bokehSize.getValue());
  // if (millis() > t + 6800)
  // {
  //   changeLightOrDark();
  //   t = millis();
  // }
}

void draw() {
  background(0);
  grabCamImage();
  update();
  
  px.beginDraw();
  px.shader(frag);
  px.image(pg,0,0);
  px.endDraw();

  image(px, 600, 0);
}

void changeLightOrDark() {
  light = !light;

}

void createGUI() {
  t_light= cp5.addToggle("light or dark")
   .setPosition(guiPositionX,GUIStartHeight)
   .setSize(100,GUISliderHeight)
   .setValue(true)
   .setMode(ControlP5.SWITCH)
   ;

  s_bokehSize = cp5.addSlider("bokeh size slider")
   .setPosition(guiPositionX,GUIStartHeight + GUIPadding)
   .setSize(150, GUISliderHeight)
   .setRange(5.2,8) // values can range from big to small as well
   .setValue(6)
   .setSliderMode(Slider.FLEXIBLE)
   ;

  s_bokehQuantity = cp5.addSlider("bokeh quantity slider")
   .setPosition(guiPositionX,GUIStartHeight + 2 * GUIPadding)
   .setSize(200, GUISliderHeight)
   .setRange(6,24) // values can range from big to small as well
   .setValue(60)
   .setNumberOfTickMarks(18)
   .setSliderMode(Slider.FLEXIBLE)
   ;

  s_timer = cp5.addSlider("timer slider")
   .setPosition(guiPositionX,GUIStartHeight + 3 * GUIPadding)
   .setSize(250, GUISliderHeight)
   .setRange(0.0,12.0) // values can range from big to small as well
   .setValue(6.20)
   .setSliderMode(Slider.FLEXIBLE)
   ;
}

void removeGUI() {
  cp5.remove("light or dark");
  cp5.remove("bokeh size slider");
  cp5.remove("bokeh quantity slider");
  cp5.remove("timer slider");
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
