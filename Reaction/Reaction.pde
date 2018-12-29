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

int drawSize = 1024;

Grid grid;
float time = 1000;
float seconds = 5;
int IMG_WIDTH = drawSize;
int IMG_HEIGHT = drawSize;

Slider cellSize;
Slider waitTime;
Slider diffusionA;
Slider diffusionB;
Slider killRate;
Slider eatRate;
PGraphics px_large;


String description = "An implementation of a reaction diffusion algorithm. Which simulates the concentration of two substances, in this case the white and the black substance. One molecule of a substances (A) can react with two molecules of (B) in such a way that A becomes B. Furthermore Both A and B move into and out of their given area and into adjacent areas.";
String name = "Reaction Diffusion";
String author = "eric";

int guiPositionX = 55;
int GUIStartHeight = 55;
int GUIPadding = 60;
int GUISliderHeight = 35;


void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);

  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);

  startWebCam();

  px_large = createGraphics(3240, 3240, P2D);
  //px_large.smooth();
  px_large.beginDraw();
  px_large.endDraw();

  cellSize = cp5.addSlider("Size of Cell")
    .setPosition(guiPositionX, GUIStartHeight)
    .setSize(400, GUISliderHeight)
    .setRange(4, 20) // values can range from big to small as well
    .setValue(5)
    .setNumberOfTickMarks(17)
    .setSliderMode(Slider.FLEXIBLE);

  waitTime = cp5.addSlider("Time to wait")
    .setPosition(guiPositionX, GUIStartHeight + GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(20, 1000) // values can range from big to small as well
    .setValue(200)
    .setSliderMode(Slider.FLEXIBLE);

  diffusionA = cp5.addSlider("Diffusion Substance A")
    .setPosition(guiPositionX, GUIStartHeight + 2 * GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(0, 1) // values can range from big to small as well
    .setValue(0.89)
    .setSliderMode(Slider.FLEXIBLE);

  diffusionB = cp5.addSlider("Diffusion Substance B")
    .setPosition(guiPositionX, GUIStartHeight + 3 * GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(0, 1) // values can range from big to small as well
    .setValue(0.43)
    .setSliderMode(Slider.FLEXIBLE);

  killRate = cp5.addSlider("Kill Rate")
    .setPosition(guiPositionX, GUIStartHeight + 4 * GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(0.001, 0.1) // values can range from big to small as well
    .setValue(0.062)
    .setSliderMode(Slider.FLEXIBLE);

  eatRate = cp5.addSlider("Feed Rate")
    .setPosition(guiPositionX, GUIStartHeight + 5 * GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(0.001, 0.1) // values can range from big to small as well
    .setValue(0.055)
    .setSliderMode(Slider.FLEXIBLE);
}

void update() { //<>//
  if (time > waitTime.getValue()) {
    grid  = new Grid(cellSize.getValue());
    grid.sample();
    grid.update();
    time = 0;
  }
  grid.da = diffusionA.getValue();
  grid.db = diffusionB.getValue();
  grid.k = killRate.getValue();
  grid.f = eatRate.getValue();
  time++;
}

void destroy() {
  cp5.remove("Size of Cell");
  cp5.remove("Time to wait");
  cp5.remove("Diffusion Substance A");
  cp5.remove("Diffusion Substance B");
  cp5.remove("Kill Rate");
  cp5.remove("Feed Rate");
}


void draw() {
  background(0);
  update();
  grabCamImage();
  
  px.beginDraw();
  px.background(0);
  px.noStroke();

  if (time>10) {
    grid.update();
  }
  if (time>50) {
    grid.update();
  }
  if (time>100) {
    grid.update();
  }
  grid.display();
  // px.filter(BLUR);

  px.endDraw();

  image(px, 600, 0);
  displayInfo();
}

class Grid {
  int IMG_WIDTH = pg.width;
  int IMG_HEIGHT = pg.height;

  float da = 1.0;
  float db = 0.5;
  float f = 0.055;
  float k = 0.062;
  float dt = 1;
  float lc = -1; //laplace center
  float la = 0.2; //laplace adjacent
  float ld = 0.05; //laplace diagonal

  Cell[][] grid;
  float r = 5;
  int cols;
  int rows;
  void sample() {
    pg.loadPixels();
    for (int i = 0; i < cols; i++) {
      int col = int(i*r);
      for (int j = 0; j < rows; j++) {
        int row = int(j*r);
        grid[i][j].b = brightness(pg.pixels[col + row * IMG_WIDTH])/255 + 0.05;
      }
    }
  }

  Grid(float cellSize) {
    r = cellSize;
    cols = ceil(IMG_WIDTH/r);
    rows = ceil(IMG_HEIGHT/r);
    grid = new Cell[cols][rows];
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        grid[i][j] = new Cell(new PVector(i*r, j*r), r);
        //grid[i][j].b = brightness(pg.get(floor(i*r),floor(j*r)))/255;
        //print(grid[i][j].b);
      }
    }

    for (int n = 0; n < 2; n++) {
      int x = int(random(10, cols-10));
      int y = int(random(10, rows-10));
      int w = int(random(5, 10)/2);
      int h = int(random(5, 10)/2);
      for (int i = x-w; i <= x+w; i++) {
        for (int j = y-h; j <= y+h; j++) {
          grid[i][j].b = 1;
        }
      }
    }
  }

  void display() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        grid[i][j].display();
      }
    }
  }

  void update() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        float[] lresult = laplace(i, j);
        float a = grid[i][j].a;
        float b = grid[i][j].b;
        grid[i][j].na = a+((da*lresult[0])-(a*b*b)+(f*(1-a)))*dt;
        grid[i][j].nb = b+((db*lresult[1])+(a*b*b)-((k+f)*b))*dt;
        grid[i][j].na = constrain(grid[i][j].na, 0, 1);
        grid[i][j].nb = constrain(grid[i][j].nb, 0, 1);
        grid[i][j].update();
      }
    }
  }

  float[] laplace(int i, int j) {
    float laplacea = 0;
    float laplaceb = 0;
    for (int k = -1; k <= 1; k++) {
      for (int l = -1; l <= 1; l++) {
        float neighboura = grid[(i+k+cols)%cols][(j+l+rows)%rows].a;
        float neighbourb = grid[(i+k+cols)%cols][(j+l+rows)%rows].b;
        if (((k == -1) || (k == 1)) && ((l == 1) || (l == -1))) { //corners
          laplacea += neighboura*ld;
          laplaceb += neighbourb*ld;
        } else if (((k != 0) && (l == 0)) || ((k == 0) && (l != 0))) {
          laplacea += neighboura*la;
          laplaceb += neighbourb*la;
        } else {
          laplacea += neighboura*lc;
          laplaceb += neighbourb*lc;
        }
      }
    }
    float[] result = {laplacea, laplaceb};
    return result;
  }
}

class Cell {
  float r, na, nb;
  PVector pos;
  float a, b;

  Cell(PVector tpos, float tr) {
    a = 1;
    b = 0;
    na = 1;
    nb = 0;
    pos = tpos;
    r = tr;
  }

  void display() {
    float c = (na-nb) * 255;
    c = constrain(c, 0, 255);
    px.fill(c, c, c); //color(c, 0, 100);
    px.rect(pos.x, pos.y, r, r);
  }

  void update() {
    float tempa = na;
    float tempb = nb;
    na = a;
    nb = b;
    a = tempa;
    b = tempb;
  }
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
