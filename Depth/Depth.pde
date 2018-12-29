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
 
/*
 * TODO
 *
 * - Rewrite using a Shader
 * x "Rutt-Etra" mode...
 * - Add parameter for turning on and off color channels and background color
 * - Have an RGB mode with a black background
 * x Add a "blur" buffer to get rid of some flickering (see LowRez module)
 */


import processing.video.*;
import controlP5.*;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;
PGraphics px3;

int xres = 10;
int yres = 10;
float rotate = 0;
float rotateSpeed = 0.001;
PGraphics pgBlur;

RadioButton r1;

int mode = 1;

String description = "Gets the color data from individual pixels and uses the values to displace geometry. Colors are defined as RGB values, numbers from 0 to 255. White is (255, 255, 255), black is (0, 0, 0), and the brightest red is (255, 0, 0), etc.";
String name = "Depth Map";
String author = "Casey REAS";

int guiPositionX = 55;
int drawSize = 1024;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  px3 = createGraphics(drawSize, drawSize, P3D);
  
  startWebCam();
  
  pgBlur = createGraphics(pg.width, pg.height, P2D);
  pgBlur.beginDraw();
  pgBlur.background(255);
  pgBlur.endDraw();
  createGUI();
}

void destroy() {
  println("Destroy " + name);
  pgBlur = null;
  removeGUI();
}

void createGUI() {
  r1 = cp5.addRadioButton("radioButton")
    .setPosition(guiPositionX, 120)
    .setSize(40, 20)
    .setItemsPerRow(2)
    .setSpacingColumn(50)
    .addItem("DOTS", 0)
    .addItem("RUTT-ETRA", 1)
    ;
  r1.activate(0);
}

void updateGUI() {
  mode = int(r1.getValue());
}

void removeGUI() {
  cp5.remove("radioButton");
}

void newFrame() {
  pgBlur.beginDraw();
  pgBlur.tint(255, 51);
  pgBlur.image(pg, 0, 0);
  pgBlur.endDraw();
}

void update() {
  updateGUI();
  newFrame();
}

void draw() {
  background(0);
  grabCamImage();
  update();
  
  pgBlur.loadPixels();
  px3.beginDraw();
  px3.background(0, 0, 255);
  px3.pushMatrix();
  px3.translate(px3.width/2, 0);
  px3.rotateY(rotate);
  px3.stroke(255);
  if (mode == 0) {
    xres = 8;
    yres = 8;
    px3.strokeCap(SQUARE);
    px3.strokeWeight(3);
    px3.beginShape(POINTS);
    for (int y = 1; y < px3.height; y += yres) {  // Hack for the strange top bar
      for (int x = 0; x < px3.width; x += xres) {
        //color c = pg.get(x, y);
        color c = pgBlur.pixels[x + y*pg.height];
        //color c = pg.pixels[x + y*pg.height];
        //float b = brightness(c);
        float b = c & 0xFF;
        float z = map(b, 0, 255, -256, 256);
        float mappedX = map(x, 0, px3.width, -540, 540);
        px3.vertex(mappedX, y, z);
      }
    }
    px3.endShape();
  } else if (mode == 1) {

    xres = 5;
    yres = 10;
    px3.strokeCap(SQUARE);
    px3.strokeWeight(1.5);
    px3.noFill();
    for (int y = 0; y < px3.height; y += yres) {
      px3.beginShape();
      for (int x = 0; x < px3.width; x += xres) {
        //color c = pg.get(x, y);
        color c = pgBlur.pixels[x + y*pg.height];
        //color c = pg.pixels[x + y*pg.height];
        //float b = brightness(c);
        float b = c & 0xFF;
        float z = map(b, 0, 255, -256, 256);
        float mappedX = map(x, 0, px3.width, -540, 540);
        px3.vertex(mappedX, y, z);
      }
      px3.endShape();
    }
  }


  px3.popMatrix();
  px3.endDraw();

  rotate += rotateSpeed;

  image(px3, 600, 0);
  
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
