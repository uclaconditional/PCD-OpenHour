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

static final int UP = 1;
static final int DOWN = 2;
static final int LEFT = 3;
static final int RIGHT = 4;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

int direction = UP;

Toggle toggle;

Slider slitNumberSlider;

PImage srcImage;
PImage resultImage;
ArrayList<PImage> srcArray;
Gradient gradient;

RadioButton dirRadio;

boolean firstImage, showGradient;

int MAX_DELAY = 270;

int counter = 0;

String description = "Keeps a buffer of video frames in memory and displays pixel rows taken from consecutive frames distributed over different axes.";
String name = "Slit Scan";
String author = "David Muth, Casey REAS, Stalgia Grigg";

int drawSize = 1080;
int guiPositionX = 55;
int GUIStartHeight = 55;
int GUIToggleHeight = 35;
int GUISliderHeight = 35;
int GUIPadding = 80;
int GUIButtonHeight = 50;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);

  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);

  startWebCam();

  srcImage = createImage(pg.width, pg.height, RGB);
  gradient = new Gradient(0, 0, drawSize, drawSize, color(0, 0, 0, 200), color(255, 255, 255, 200), direction, MAX_DELAY);
  resultImage = createImage(drawSize, drawSize, RGB);
  srcArray = new ArrayList<PImage>(MAX_DELAY);


  firstImage = true;
  showGradient = false;

  createGUI();
}


void destroy() {
  println("Destroy " + name);
  removeGUI();
  srcArray = null;
  gradient = null;
  srcImage = null;
  resultImage = null;
}

void update() {
  updateGUI();
}


void draw() {
  background(0);
  update();
  newFrame();
  grabCamImage();
  
  image(px, 600, 0);
  displayInfo();
}

void newFrame() {
  srcImage = pg.get();
  processVideo();
  gradient.updateGradient();
}


void createGUI() {
  toggle = cp5.addToggle("show gradient")
    .setPosition(guiPositionX, GUIStartHeight)
    .setSize(100, GUIToggleHeight)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    ;

  slitNumberSlider = cp5.addSlider("slit number slider")
    .setPosition(guiPositionX, GUIStartHeight + GUIPadding)
    .setSize(400, GUISliderHeight)
    .setRange(10, 260) // values can range from big to small as well
    .setValue(270)
    ;

  dirRadio = cp5.addRadioButton("direction")
    .setPosition(guiPositionX, GUIStartHeight + 2 * GUIPadding)
    .setSize(40, GUIButtonHeight)
    .setColorForeground(color(120))
    .setColorActive(color(255))
    .setColorLabel(color(255))
    .setItemsPerRow(5)
    .setSpacingColumn(50)
    .addItem("UP", 0)
    .addItem("DOWN", 1)
    .addItem("LEFT", 2)
    .addItem("RIGHT", 3)
    ;
  dirRadio.deactivateAll();
  dirRadio.activate(0);
}

void updateGUI() {
  showGradient = !toggle.getBooleanValue();
  MAX_DELAY = (int)slitNumberSlider.getValue();

  int tempDir = (int)dirRadio.getValue() + 1;
  if (tempDir != direction) {
    direction = tempDir;
    gradient.setGradientDirection(direction);
  }
}

void removeGUI() {
  cp5.remove("show gradient");
  cp5.remove("slit number slider");
  cp5.remove("direction");
}

void processVideo() {
  if (firstImage) {
    initSrcArray(srcImage);
  }
  getImages(srcImage, srcArray);
  copyVideoGradient(srcArray, resultImage);
  px.beginDraw();
  px.image(resultImage, 0, 0);
  if (showGradient) {
    px.image(gradient.getGradient(), 0, 0);
  }
  px.endDraw();
}

void initSrcArray(PImage src) {
  for (int i=0; i<MAX_DELAY; i++) {
    srcArray.add(src);
  }
  firstImage = false;
}

void updateArray(boolean plus, int num) {
  if (MAX_DELAY != srcArray.size()) {
    if (plus) {
      for (int i = 0; i<num; i++)
      {
        srcArray.add(srcArray.get(srcArray.size() -1));
      }
    } else {
      for (int i = 0; i<num; i++)
      {
        srcArray.remove(srcArray.size() -1);
      }
    }
  }
}

void getImages(PImage src, ArrayList<PImage> srcArray) {
  for ( int i = MAX_DELAY-1; i>0; i--) {
    PImage temp = srcArray.get(i-1);
    if ( temp != null) {
      srcArray.set(i, temp);
    }
  }
  srcArray.set(0, src);
}

void copyVideoGradient(ArrayList<PImage> sourceArray, PImage result) {
  int step = (int) drawSize/MAX_DELAY;
  if (direction == UP || direction == DOWN)
    for ( int y =0; y<drawSize; y+=step)
    {
      int delay =  gradient.getDelayValue(0, y, MAX_DELAY);
      arrayCopy(sourceArray.get(delay).pixels, y*drawSize, result.pixels, y*drawSize, drawSize*step);
    } else {
    for ( int x =0; x<drawSize; x++)
    {
      int delay =  gradient.getDelayValue(x, 0, MAX_DELAY);
      for (int y=0; y<drawSize; y++) {
        int pos =y*drawSize + x;
        result.pixels[pos] = sourceArray.get(delay).pixels[pos];
      }
    }
  }
  result.updatePixels();
}


public class Gradient {
  int _height;
  int _width;
  int _resolution;
  PImage _image;
  color _c1;
  color _c2;
  PGraphics _pg;
  int _xPos;
  int _yPos;
  int _direction;
  int _mode;
  boolean isDirty = false;

  public Gradient(int xPos, int yPos, int w, int h, color c1, color c2, int direction, int resolution) {
    _resolution = resolution;
    _width = w;
    _height = h;
    _c1 = c1;
    _c2 = c2;
    _pg = createGraphics(_width, _height);
    _xPos = xPos;
    _yPos = yPos;
    _direction = direction;

    drawGradient();
  }

  void drawGradient() {
    _pg.noFill();
    _pg.beginDraw();
    if (_direction == UP) {
      for (int i = _yPos; i <= _yPos+_height; i++) {
        float inter = map(i, _yPos, _yPos+_height, 0, 1);
        color c = lerpColor(_c1, _c2, inter);
        _pg.stroke(c);
        _pg.line(_xPos, i, _xPos+_width, i);
      }
    } else if (_direction == DOWN) {
      for (int i = _yPos; i <= _yPos+_height; i++) {
        float inter = map(i, _yPos, _yPos+_height, 0, 1);
        color c = lerpColor(_c2, _c1, inter);
        _pg.stroke(c);
        _pg.line(_xPos, i, _xPos+_width, i);
      }
    } else if (_direction == LEFT) {
      for (int i = _xPos; i <= _xPos+_width; i++) {
        float inter = map(i, _xPos, _xPos+_width, 0, 1);
        color c = lerpColor(_c1, _c2, inter);
        _pg.stroke(c);
        _pg.line(i, _yPos, i, _yPos+_height);
      }
    } else if (_direction == RIGHT) {
      for (int i = _xPos; i <= _xPos+_width; i++) {
        float inter = map(i, _xPos, _xPos+_width, 0, 1);
        color c = lerpColor(_c2, _c1, inter);
        _pg.stroke(c);
        _pg.line(i, _yPos, i, _yPos+_height);
      }
    }
    _pg.endDraw();
  }

  void updateGradient() {
    if (isDirty) {
      drawGradient();
    }
    isDirty = false;
  }

  void setGradientDirection(int d) {
    _direction = d;
    isDirty = true;
    updateGradient();
  }

  int getDelayValue(int x, int y, int maxDelay) {
    color c= _pg.pixels[y*_pg.width+x];
    int val = 255 -(c >> 16 &0xFF);
    int delay = (int) min(maxDelay -1, (val/255.0 * maxDelay));
    return delay;
  }


  PGraphics getGradient() {
    return _pg;
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
    pg.vertex(drawSize, 0, cam.width/2-cam.height/2, 0);
    pg.vertex(drawSize, drawSize, cam.width/2-cam.height/2, cam.height);
    pg.vertex(0, drawSize, cam.width/2+cam.height/2, cam.height);
    pg.endShape();
    pg.endDraw();
  }
}
