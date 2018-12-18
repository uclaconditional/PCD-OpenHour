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

PShader asciiShader;
PShader levelsShader;
PShader csb_adjustShader;

PImage asciiTex;

float contrast;
float saturation;
float brightness;

Slider s_asciiMode;
Slider s_contrast;
Slider s_saturation;
Slider s_brightness;
Slider s_fontSize;
Slider s_fontClr;

int asciiMode; // 0 = rgb, 1 = grayscale, 2 = black/white

String description = "Classic ASCII filter.";
String name = "ASCII Transcoding";
String author = "Morten Nobel, L05";

int drawSize = 1024;

int guiPositionX = 55;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  startWebCam();
  createGUI();
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);

  px.resetShader();
  px.noTint();

  asciiMode   = 2;
  contrast    = 2;
  saturation  = 1;
  brightness  = 1;

  asciiTex    = loadImage("ascii_sorted_1.png");

  asciiShader = loadShader("ascii.frag");
  asciiShader.set("u_fontSize", 8.0, 16.0);
  asciiShader.set("u_fontClr", 0.0, 1.0, 0.0);
  asciiShader.set("u_asciiTex", asciiTex);
  asciiShader.set("u_mode", asciiMode);
  asciiShader.set("u_steps", 8.0);

  csb_adjustShader = loadShader("csb_adjust.frag");
  csb_adjustShader.set("u_contrast", contrast);
  csb_adjustShader.set("u_saturation", saturation);
  csb_adjustShader.set("u_brightness", brightness);

  // Temp adjust levels because my webcam lighting is terrible -L05
  levelsShader = loadShader("levels.frag");
  levelsShader.set("u_inLow", 0f);
  levelsShader.set("u_gamma", 1f);
  levelsShader.set("u_inHigh", 1f);
  levelsShader.set("u_outLow", 0f);
  levelsShader.set("u_outHigh", 1f);
}

void destroy() {
  println("Destroy " + name);
  removeGUI();

  resetShader();
  px.resetShader();
  px.noTint();

  asciiShader       = null;
  levelsShader      = null;
  csb_adjustShader  = null;
  asciiTex          = null;
}

void update() {
  updateGUI();

  asciiShader.set("u_mode", asciiMode);
  csb_adjustShader.set("u_contrast", contrast);
  csb_adjustShader.set("u_saturation", saturation);
  csb_adjustShader.set("u_brightness", brightness);
}

void draw() {
  background(0);
  grabCamImage();
  
  px.beginDraw();
  px.image(pg, 0, 0);
  px.filter(csb_adjustShader);
  px.filter(asciiShader);
  px.endDraw();

  image(px, 600, 0);
}

void createGUI() {
  s_asciiMode = cp5.addSlider("ascii_mode")
    .setPosition(guiPositionX, 100)
    .setSize(400, 30)
    .setRange(0, 2)
    .setNumberOfTickMarks(3)
    .setValue(2)
    ;

  s_fontSize = cp5.addSlider("font_size")
    .setPosition(guiPositionX, 150)
    .setSize(400, 30)
    .setRange(0, 2)
    .setNumberOfTickMarks(3)
    .setValue(0)
    .onChange(new CallbackListener() { // a callback function that will be called onPress
        public void controlEvent(CallbackEvent theEvent) {
          float fontSizeX = 8.0;
          float fontSizeY = 16.0;

          switch (int(theEvent.getController().getValue())) {
            case 0:
              asciiTex  = loadImage("ascii_sorted_0.png");
              fontSizeX = 8.0;
              fontSizeY = 16.0;
              break;
            case 1:
              asciiTex = loadImage("ascii_sorted_1.png");
              fontSizeX = 12.0;
              fontSizeY = 24.0;
              break;
            case 2:
              asciiTex = loadImage("ascii_sorted_2.png");
              fontSizeX = 16.0;
              fontSizeY = 32.0;
              break;
          }

          asciiShader.set("u_asciiTex", asciiTex);
          // asciiShader.set("u_fontSize", 0.5);
          asciiShader.set("u_fontSize", fontSizeX, fontSizeY);
        }
      });

  s_contrast = cp5.addSlider("contrast")
    .setPosition(guiPositionX, 250)
    .setSize(400, 30)
    .setRange(0.0, 5.0)
    .setValue(2.0)
    ;

  s_saturation = cp5.addSlider("saturation")
    .setPosition(guiPositionX, 300)
    .setSize(400, 30)
    .setRange(0.0, 5.0)
    .setValue(1.0)
    ;

  s_brightness = cp5.addSlider("brightness")
    .setPosition(guiPositionX, 350)
    .setSize(400, 30)
    .setRange(0.0, 5.0)
    .setValue(1.25)
    ;

  s_fontClr = cp5.addSlider("color")
    .setPosition(guiPositionX, 400)
    .setSize(400, 30)
    .setRange(0, 2)
    .setNumberOfTickMarks(3)
    .setValue(1)
    .onChange(new CallbackListener() { // a callback function that will be called onPress
        public void controlEvent(CallbackEvent theEvent) {
          switch (int(theEvent.getController().getValue())) {
            case 0:
              asciiShader.set("u_fontClr", 1.0, 1.0, 1.0);
              break;
            case 1:
              asciiShader.set("u_fontClr", 0.0, 1.0, 0.0);
              break;
            case 2:
              asciiShader.set("u_fontClr", 1.0, 0.0, 0.0);
              break;
          }
        }
      });

}

void updateGUI() {
  asciiMode   = round(s_asciiMode.getValue());
  contrast    = s_contrast.getValue();
  saturation  = s_saturation.getValue();
  brightness  = s_brightness.getValue();
}

void removeGUI() {
  cp5.remove("ascii_mode");
  cp5.remove("font_size");
  cp5.remove("steps");
  cp5.remove("contrast");
  cp5.remove("saturation");
  cp5.remove("brightness");
  cp5.remove("color");
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
