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

final static int MAX_ITER = 20;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

int channel = RED;
float channelOffset = 30;
int iteration = MAX_ITER;
int direction = LEFT;
float scale = 0.3;
float feedback = 0.9;

PGraphics buffer;

boolean nextImage = true;

PImage imgb;
float echoStep;

Slider scaleSlider;
Slider feedbackSlider;
Slider offsetSlider;
RadioButton dirRadio, _sort;

String description = "Description...";
String name = "Pixel Sorting (Column)";
String author = "Stalgia Grigg";

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
  
  imgb = createImage(1080, 1080, RGB);
  echoStep = 256.0 / iteration;
  createGUI();
  nextImage = true;
  buffer = createGraphics(px.width, px.height);
}

void destroy() {
  println("Destroy " + name);
  removeGUI();
  buffer = null;
  imgb = null;
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
  if (nextImage == true) {
  readyForImage();
  }else {
    if(iteration>0) {
      processImage();
      iteration--;
    } else {
      nextImage = true;
  }
  if(iteration>0) {
    processImage();
    iteration--;

  } else {
    nextImage = true;
  }
 }
}

void updateGUI() {
  channelOffset = offsetSlider.getValue();
  scale = scaleSlider.getValue();
  feedback = feedbackSlider.getValue();

  //probably is a better way to do this, cp5 is unfamiliar
  int tempDir = (int)dirRadio.getValue() + 1;
  direction = tempDir >= 0 ? tempDir : direction;

  int tempSort = (int)_sort.getValue();
  if(tempSort != channel) {
    channel = tempSort;
  }
}

void createGUI() {

  scaleSlider = cp5.addSlider("scale")
   .setPosition(guiPositionX,100)
   .setSize(400, 50)
   .setRange(0.01,0.3)
   .setValue(0.03)
   ;

  feedbackSlider = cp5.addSlider("feedback")
   .setPosition(guiPositionX,200)
   .setSize(400, 50)
   .setRange(.9,.999)
   .setValue(.9)
   ;

  offsetSlider = cp5.addSlider("offset")
   .setPosition(guiPositionX,300)
   .setSize(400, 50)
   .setRange(10,100)
   .setValue(30)
   ;

 dirRadio = cp5.addRadioButton("direction")
   .setPosition(guiPositionX,400)
   .setSize(40,20)
   .setColorForeground(color(120))
   .setColorActive(color(255))
   .setColorLabel(color(255))
   .setItemsPerRow(5)
   .setSpacingColumn(50)
   .addItem("UP",0)
   .addItem("DOWN",1)
   .addItem("LEFT",2)
   .addItem("RIGHT",3)
   ;
  dirRadio.deactivateAll();
  dirRadio.activate(1);

  _sort = cp5.addRadioButton("sort")
   .setPosition(guiPositionX,500)
   .setSize(40,20)
   .setColorForeground(color(120))
   .setColorActive(color(255))
   .setColorLabel(color(255))
   .setItemsPerRow(5)
   .setSpacingColumn(50)
   .addItem("RED",0)
   .addItem("GREEN",1)
   .addItem("BLUE",2)
   .addItem("HUE",3)
   .addItem("SATURATION",4)
   .addItem("BRIGHTNESS",5)
   ;
  _sort.activate(5);
}

void removeGUI() {
  cp5.remove("scale");
  cp5.remove("feedback");
  cp5.remove("offset");
  cp5.remove("direction");
  cp5.remove("sort");
}

void readyForImage() {
  iteration = MAX_ITER;
  imgb = pg.get();
  nextImage = false;
  px.beginDraw();
  px.image(pg,0,0);
  px.endDraw();
}

void processImage() {
  px.beginDraw();

   for(int x=0;x<1080;x++) {
    for(int y=0;y<1080;y++) {
      color c = px.get(x,y);
      color c2;
      if(direction == UP || direction == DOWN) {
        c2 = imgb.get(x,((int)(y+1080+( (channelOffset+getChannel(c,channel))%255 )*(direction==DOWN?-1.0:1.0)*scale))%1080);
      } else {
        c2 = imgb.get(((int)(x+1080+( (channelOffset+getChannel(c,channel))%255)*(direction==RIGHT?-1.0:1.0)*scale))%1080,y);
      }
      px.set(x,y,lerpColor(c,c2,feedback) );
    }
  }
  px.endDraw();
  imgb = px.get();
}


//

// ALL Channels, Nxxx stand for negative (255-value)
// channels to work with
final static int RED = 0;
final static int GREEN = 1;
final static int BLUE = 2;
final static int HUE = 3;
final static int SATURATION = 4;
final static int BRIGHTNESS = 5;
final static int NRED = 6;
final static int NGREEN = 7;
final static int NBLUE = 8;
final static int NHUE = 9;
final static int NSATURATION = 10;
final static int NBRIGHTNESS = 11;

float getChannel(color c, int channel) {
  int ch = channel>5?channel-6:channel;
  float cc;

  switch(ch) {
    case RED: cc = red(c); break;
    case GREEN: cc = green(c); break;
    case BLUE: cc = blue(c); break;
    case HUE: cc = hue(c); break;
    case SATURATION: cc = saturation(c); break;
    default: cc= brightness(c); break;
  }

  return channel>5?255-cc:cc;
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
