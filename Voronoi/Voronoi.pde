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

PGraphics pg;
PGraphics px;

String description = "Voronoi is an algorithm that breaks down an image into the a series of shards or planes. Each pixel then becomes the color of the plane based on the most prominent color in that section of the video input.";
String name = "Voronoi";
String author = "Stalgia Grigg, Hye Min Cho";

PShader frag;
Button randomSeed;
Slider densitySlider;

PShader prepShader;
PGraphics prepLayer;

int density = 15000;  // Also make sure to update in shader

boolean baked = false;

int guiPositionX = 55;
int GUIStartHeight = 50;
int GUIPadding = 60;
int GUISliderHeight = 30;
int GUIButtonHeight = 30;


int drawSize = 1024;

void setup() {
  //fullScreen(P2D, SPAN);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  startWebCam();

  frag = loadShader("voronoi.frag");
  frag.set("uResolution", drawSize, drawSize);
  frag.set("uSeed", 20);

  prepShader = loadShader("voronoiPrep.frag");
  prepShader.set("uResolution", drawSize, drawSize);
  prepShader.set("uSeed", 20);
  prepShader.set("uDensity", density);     // PARAM

  prepLayer = createGraphics(drawSize, drawSize, P2D);

  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
 
  createGUI();
}

void destroy() {
  baked = false;
  px.resetShader();
  removeGUI();
  prepLayer = null;
  frag = null;
  prepShader = null;
}


void update() {
  updateGUI();
}

void draw() {
  background(0);
  grabCamImage();
  
  if (!baked){
    prepShader.set("uSeed", 20);
    prepShader.set("uDensity", density);     // PARAM
    prepLayer.beginDraw();
    prepLayer.filter(prepShader);
    prepLayer.endDraw();
    baked = true;
  }

  frag.set("uTexture", pg);
  frag.set("prepTexture", prepLayer);

  px.beginDraw();
  px.filter(frag);
  px.endDraw();

  image(px, 600, 0);
}

void updateGUI() {
  density = (int) densitySlider.getValue();
}

void createGUI() {
densitySlider= cp5.addSlider("density")
 // .setPosition(2880,800)
 .setPosition(guiPositionX, GUIStartHeight)
 .setSize(400, GUISliderHeight)
 .setRange(200,25000) // values can range from big to small as well
 .setValue(15000)
 .setNumberOfTickMarks(10)
;

randomSeed = cp5.addButton("randomizeSeed")
   .setPosition(guiPositionX, GUIStartHeight + GUIPadding)
   .setSize(100, GUIButtonHeight)
   .onPress(new CallbackListener() { // a callback function that will be called onPress
    public void controlEvent(CallbackEvent theEvent) {
      frag.set("uSeed", frameCount);
      prepShader.set("uSeed", frameCount);
      baked = false;
    }
  });
}

void removeGUI() {
  cp5.remove("randomizeSeed");
  cp5.remove("density");
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
