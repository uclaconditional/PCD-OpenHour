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

PShader emojiShader;
PShader csb_adjustShader;
PImage emojiTex;

int emojiSize;
int prevSize;

float contrast;
float saturation;
float brightness;

Slider s_emojiSize;
Slider s_contrast;
Slider s_saturation;
Slider s_brightness;

Toggle t_blackMode;
boolean prevMode;

String description = "Heart eyes. Laughing crying face. XD <3";
String name = "Emoji Transcoding";
String author = "L05";

int drawSize = 1024;
int guiPositionX = 55;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  px.resetShader();
  px.noTint();

  println("Create " + name);
  createGUI();

  emojiSize   = 1;
  prevSize    = 1;
  contrast    = 1.0f;
  saturation  = 1.5f;
  brightness  = 1.0f;

  prevMode    = false;

  emojiTex    = loadImage("data/hsv_emoji_inv_1.jpg");
  emojiShader = loadShader("emoji.frag");
  emojiShader.set("u_emojiTex", emojiTex);
  emojiShader.set("u_emojiTexW", float(emojiTex.width));
  emojiShader.set("u_emojiTexH", float(emojiTex.height));
  emojiShader.set("u_emojiSize", float(emojiTex.height/20));

  // Increasing the image saturation to weight image towards color emoji.
  csb_adjustShader = loadShader("csb_adjust.frag");
  csb_adjustShader.set("u_contrast", contrast);
  csb_adjustShader.set("u_saturation", saturation);
  csb_adjustShader.set("u_brightness", brightness);
}

void destroy() {
  println("Destroy " + name);
  removeGUI();

  px.resetShader();

  emojiTex          = null;
  emojiShader       = null;
  csb_adjustShader  = null;
}

void update() {
  updateGUI();

  if (emojiSize != prevSize || t_blackMode.getState() != prevMode) {
    if (t_blackMode.getState()) {
      emojiTex = loadImage("data/hsv_emoji_inv_blk_"+str(emojiSize)+".jpg");
      prevMode = t_blackMode.getState();
    } else {
      emojiTex = loadImage("data/hsv_emoji_inv_"+str(emojiSize)+".jpg");
      prevMode = t_blackMode.getState();
    }

    emojiShader.set("u_emojiTex", emojiTex);
    emojiShader.set("u_emojiTexW", float(emojiTex.width));
    emojiShader.set("u_emojiTexH", float(emojiTex.height));
    emojiShader.set("u_emojiSize", float(emojiTex.height/20));
    prevSize = emojiSize;
  }

  csb_adjustShader.set("u_contrast", contrast);
  csb_adjustShader.set("u_saturation", saturation);
  csb_adjustShader.set("u_brightness", brightness);
}

void draw() {
  background(0);
  update();
  grabCamImage();

  px.beginDraw();
  px.image(pg, 0, 0);
  px.filter(csb_adjustShader);
  px.filter(emojiShader);
  px.endDraw();

  image(px, 600, 0);
  
  displayInfo();
}

void createGUI() {
  s_emojiSize = cp5.addSlider("emoji_size")
    .setPosition(guiPositionX, 100)
    .setSize(400, 30)
    .setRange(0, 2)
    .setValue(1)
    ;

  s_contrast = cp5.addSlider("contrast")
    .setPosition(guiPositionX, 150)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_saturation = cp5.addSlider("saturation")
    .setPosition(guiPositionX, 200)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(2)
    ;

  s_brightness = cp5.addSlider("brightness")
    .setPosition(guiPositionX, 250)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1.2)
    ;

  t_blackMode = cp5.addToggle("black_mode")
    .setPosition(guiPositionX, 300)
    .setSize(60, 30)
    .setValue(false)
    .setMode(ControlP5.SWITCH)
    ;
}

void updateGUI() {
  emojiSize   = round(s_emojiSize.getValue());
  contrast    = s_contrast.getValue();
  saturation  = s_saturation.getValue();
  brightness  = s_brightness.getValue();
}

void removeGUI() {
  cp5.remove("emoji_size");
  cp5.remove("contrast");
  cp5.remove("saturation");
  cp5.remove("brightness");
  cp5.remove("black_mode");
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
