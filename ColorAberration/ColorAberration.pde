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
import com.thomasdiewald.pixelflow.java.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwBackgroundSubtraction;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

PShader pShader;
DwBackgroundSubtraction bg_sub;
PGraphics2D pg_src;
PGraphics2D pg_sub;

// control GUI elements
int radBG, radFG;
float valBias, valMult;
Slider sliderBGRadius, sliderFGRadius, sliderBias, sliderMult;
RadioButton rbFilters;

DwPixelFlow context;

/*String[] arrFilter = {"DILATE", "ERODE", "OPENING", "CLOSING"};
int idFilter = 0;*/


String description = "Background subtraction plus shader color channel manipulation.";
String name =  "Color Aberration Shader";
String author = "amc";

int drawSize = 1024;
int guiPositionX = 55;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  startWebCam();
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);

  pShader = loadShader("data/color_aberration.glsl");

  pg_src = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_src.noSmooth();

  pg_sub = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_sub.noSmooth();

  context = new DwPixelFlow(this);
  bg_sub = new DwBackgroundSubtraction(context, px.width, px.height);

  createGUI();
}

void destroy() {
  println("Destroy " + name);
  context = null;
  bg_sub = null;

  px.resetShader();
  px.blendMode(BLEND);

  pg_src.resetShader();
  pg_src = null;
  pg_sub.resetShader();
  pg_sub = null;

  bg_sub = null;

  pShader = null;

  removeGUI();
}

void update() {
  updateGUI();

  pg_src.beginDraw();
  pg_src.blendMode(REPLACE);
  pg_src.image(pg, 0, 0, px.width, px.height);
  pg_src.endDraw();

  bg_sub.param.bg_blur_radius = radBG;
  bg_sub.param.bg_blur_radius = radBG;
  bg_sub.param.fg_blur_radius = radFG;
  bg_sub.apply(pg_src, pg_sub);

  pg_sub.beginDraw();

  //pg_sub.filter(THRESHOLD);
  /*
  switch (idFilter){
    case 0:
      pg_sub.filter(DILATE);
      break;
    case 1:
      pg_sub.filter(ERODE);
      break;
    case 2:
      pg_sub.filter(ERODE);
      pg_sub.filter(DILATE);
      break;
    case 3:
      pg_sub.filter(DILATE);
      pg_sub.filter(ERODE);
      break;
    default:
      pg_sub.resetShader();
      break;
  }
  */
  pg_sub.endDraw();

  if (frameCount%8 == 0){
    bg_sub.reset();
  }
}

void draw() {
  background(0);
  update();
  grabCamImage();
  setShaderParameters();

  px.beginDraw();
  px.shader(pShader);
  px.blendMode(REPLACE);
  px.image(pg_sub, 0, 0);
  px.endDraw();
  image(px, 600, 0);

  // stats, to the title window
  String txt_fps = String.format(getClass().getName()+ "   [frame %d]   [fps %6.2f]", frameCount, frameRate);
  surface.setTitle(txt_fps);
  
  displayInfo();
}

void createGUI() {
  sliderBGRadius = cp5.addSlider("background blur radius")
    .setPosition(guiPositionX, 100)
    .setSize(350, 30)
    .setRange(1, 20)
    .setValue(8)
    .setNumberOfTickMarks(4)
    ;

  sliderFGRadius = cp5.addSlider("foreground blur radius")
    .setPosition(guiPositionX, 200)
    .setSize(350, 30)
    .setRange(1, 20)
    .setValue(8)
    .setNumberOfTickMarks(4)
    ;
  sliderBias = cp5.addSlider("red channel bias")
    .setPosition(guiPositionX, 300)
    .setSize(350, 30)
    .setRange(0.0f, 1.0f)
    .setValue(0.1)
    ;
  sliderMult = cp5.addSlider("green + blue channel multipliers")
    .setPosition(guiPositionX, 400)
    .setSize(350, 30)
    .setRange(0.001f, 0.010f)
    .setValue(0.004f)
    ;

  /*rbFilters = cp5.addRadioButton("filters")
    .setPosition(guiPositionX + 120, 600)
    .setSize(400,30)
    .addItem(arrFilter[0],0)
    .addItem(arrFilter[1],1)
    .addItem(arrFilter[2],2)
    .addItem(arrFilter[3],3)
    ;*/
}

void updateGUI() {
  radBG  = (int)sliderBGRadius.getValue();
  radFG = (int)sliderFGRadius.getValue();
  valBias = sliderBias.getValue();
  valMult = sliderMult.getValue();
  //idFilter = (int)rbFilters.getValue();
}

void removeGUI(){
  cp5.remove("background blur radius");
  cp5.remove("foreground blur radius");
  cp5.remove("red channel bias");
  cp5.remove("green + blue channel multipliers");
  //cp5.remove("filters");
}

void setShaderParameters() {
  /*pShader.set("rbias", 0.1, 0.0);
  pShader.set("gbias", 0.0, 0.0);
  pShader.set("bbias", 0.0, 0.0);
  pShader.set("rmult", 1.0, 1.0);
  pShader.set("gmult", 1.0+0.004*(frameCount%8), 1.0+0.004*(frameCount%8));
  pShader.set("bmult", 1.0+0.008*(frameCount%8), 1.0+0.008*(frameCount%8));*/
  pShader.set("rbias", valBias, 0.0);
  pShader.set("gbias", 0.0, 0.0);
  pShader.set("bbias", 0.0, 0.0);
  pShader.set("rmult", 1.0, 1.0);
  pShader.set("gmult", 1.0+valMult*(frameCount%8), 1.0+valMult*(frameCount%8));
  pShader.set("bmult", 1.0+valMult*(frameCount%8)*2, 1.0+valMult*(frameCount%8)*2);
  /*pShader.set("rbias", valBias, 0.0);
  pShader.set("gbias", 0.0, 0.0);
  pShader.set("bbias", 0.0, 0.0);
  pShader.set("rmult", 1.0, 1.0);
  pShader.set("gmult", 1.0+valMult*4, 1.0+valMult*4);
  pShader.set("bmult", 1.0+valMult*4*2, 1.0+valMult*4*2);*/
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
