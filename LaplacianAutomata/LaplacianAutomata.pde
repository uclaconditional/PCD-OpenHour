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

import java.nio.ByteBuffer;
import com.jogamp.opengl.GL2;
import com.thomasdiewald.pixelflow.java.*;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLTexture;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwShadertoy;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;


DwPixelFlow context;
DwShadertoy res, bufferA;
DwGLTexture camera;

int counter;

Slider _kRate0, _kRate1, _kRate2, _curlScale, _lapScale, _lapDivScale, _divScale, _power, _amp, _diag;
Button _reset;

PImage bufferASave;
int fadeTime = 200;


String description = "A cellular automata version of a reaction diffusion algorithm based on the laplace operator. This is based on a simulation of a chemical reaction. It can be a described as a scenario in which neighbors eat each other based on proximity and consuming a certain amount of a pixel color converts that pixel to the color of its food.";
String name = "Laplacian Automata";
String author = "Cornusamonus, Stalgia Grigg";
Boolean titleIsBlack = false;

int drawSize = 1024;

int guiPositionX = 55;
int GUIStartHeight = 55;
int GUIPadding = 60;
int GUISliderHeight = 35;
int GUIButtonHeight = 50;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
   camera = new DwGLTexture();
  context = new DwPixelFlow(this);

  bufferA = new DwShadertoy(context, "firstPass.frag");
  res  = new DwShadertoy(context, "final.frag");

  int wh = 256;
  byte[] bdata = new byte[wh * wh * 4];
  ByteBuffer bbuffer = ByteBuffer.wrap(bdata);
  for(int i = 0; i < bdata.length;){
    bdata[i++] = (byte) random(0, 255);
    bdata[i++] = (byte) random(0, 255);
    bdata[i++] = (byte) random(0, 255);
    bdata[i++] = (byte) 255;
  }
  camera.resize(context, GL2.GL_RGBA8, wh, wh, GL2.GL_RGBA, GL2.GL_UNSIGNED_BYTE, GL2.GL_LINEAR, GL2.GL_MIRRORED_REPEAT, 4, 1, bbuffer);
  createGUI();
}

void destroy() {
  println("Destroy " + name);
  px.resetShader();
  bufferA.dispose();
  res.dispose();
  camera = null;
  context = null;
  res = null;
  bufferA = null;
  bufferASave = null;
  removeGUI();
}



void newFrame() {
  DwFilter.get(context).copy.apply(pg, camera);
}

void update() {
  updateGUI();
  if(millis() - counter >= 7000) {
    counter = millis();
    bufferASave = px.copy();
    bufferA.reset();
  }
  px.beginDraw();
  bufferA.set_iChannel(0, bufferA);
  bufferA.set_iChannel(1, camera);
  bufferA.apply(px.width, px.height);
  res.set_iChannel(0, bufferA);
  res.apply(px);
  // px.stroke(255, 255, 255, 150);
  // px.image(bufferASave, 0, 0);
  px.endDraw();
}

void draw() {
  background(0);
  update();
  newFrame();
  grabCamImage();
  
  image(px, 600, 0);
  displayInfo();
}

void updateGUI() {
  //bufferA.shader.uniform1f("k0", _kRate0.getValue() * -1.0);
  //println(_curlScale.getValue());
  bufferA.shader.frag.setDefine("cs", _curlScale.getValue());
  bufferA.shader.frag.setDefine("_K0", _kRate0.getValue() * -1);
  bufferA.shader.frag.setDefine("_K1", _kRate1.getValue());
  bufferA.shader.frag.setDefine("_K2", _kRate2.getValue());
  bufferA.shader.frag.setDefine("_K2", _kRate2.getValue());
  bufferA.shader.frag.setDefine("ls", _lapScale.getValue());
  bufferA.shader.frag.setDefine("ps", _lapDivScale.getValue() *-1);
  bufferA.shader.frag.setDefine("ds", _divScale.getValue() *-1);
  bufferA.shader.frag.setDefine("amp", _amp.getValue());
  bufferA.shader.frag.setDefine("sq2", _diag.getValue());
}

void createGUI() {
  _kRate0 = cp5.addSlider("center weight")
   .setPosition(guiPositionX,GUIStartHeight)
   .setSize(400, GUISliderHeight)
   .setRange(3.1,3.6) // values can range from big to small as well
   .setValue(3.33)
   ;

  _kRate1 = cp5.addSlider("edge neighbors")
   .setPosition(guiPositionX,GUIStartHeight + GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.4,.8) // values can range from big to small as well
   .setValue(0.66)
   ;

  _kRate2 = cp5.addSlider("vertex neighbors")
   .setPosition(guiPositionX, GUIStartHeight + 2 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.06,.24) // values can range from big to small as well
   .setValue(0.166)
   ;

  _curlScale = cp5.addSlider("curl scale")
   .setPosition(guiPositionX,GUIStartHeight + 3 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.001,0.8) // values can range from big to small as well
   .setValue(0.19)
   ;

  _lapScale = cp5.addSlider("lap scale")
   .setPosition(guiPositionX,GUIStartHeight + 4 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.13,.28) // values can range from big to small as well
   .setValue(0.24)
   ;

  _lapDivScale = cp5.addSlider("lap diverge scale")
   .setPosition(guiPositionX,GUIStartHeight + 5 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.01,.28) // values can range from big to small as well
   .setValue(0.03)
   ;

  _amp = cp5.addSlider("amplitude")
   .setPosition(guiPositionX,GUIStartHeight + 6 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.92,1.2) // values can range from big to small as well
   .setValue(1.0)
   ;

  _divScale = cp5.addSlider("divergence scale")
   .setPosition(guiPositionX,GUIStartHeight + 7 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.05,.5) // values can range from big to small as well
   .setValue(.11)
   ;

  _diag = cp5.addSlider("diagonal scale")
   .setPosition(guiPositionX,GUIStartHeight + 8 * GUIPadding)
   .setSize(400, GUISliderHeight)
   .setRange(.5,2.0) // values can range from big to small as well
   .setValue(1.5)
   ;

  _reset = cp5.addButton("reset")
   .setPosition(guiPositionX, GUIStartHeight + 9 * GUIPadding)
   .setSize(100, GUIButtonHeight)
   .onPress(new CallbackListener() { // a callback function that will be called onPress
    public void controlEvent(CallbackEvent theEvent) {
      _kRate0.setValue(3.33);
      _kRate1.setValue(.66);
      _kRate2.setValue(.166);
      _curlScale.setValue(.19);
      _lapScale.setValue(.24);
      _lapDivScale.setValue(.03);
      _amp.setValue(1.0);
      _divScale.setValue(0.11);
      _diag.setValue(1.5);
    }
  });
}

void removeGUI() {
  cp5.remove("reset");
  cp5.remove("diagonal scale");
  cp5.remove("divergence scale");
  cp5.remove("amplitude");
  cp5.remove("lap diverge scale");
  cp5.remove("lap scale");
  cp5.remove("curl scale");
  cp5.remove("vertex neighbors");
  cp5.remove("edge neighbors");
  cp5.remove("center weight");
  cp5.remove("reset");
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
