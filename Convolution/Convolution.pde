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

Kernel[] kernels = new Kernel[11];

int windowSize = 100;
int matrixsize = 3;

boolean bShot = false;
color [] pixelSnapshot;
color [] pixelOutput;
int __x = 1;
int __y = 1;
int __gap = 90;
int x_offset = 0; //420
int[] __c = new int [3];

boolean bDone = false;
int kernelID = 0;
boolean bToggle = true;

// controls
DropdownList listKernel;
Toggle toggle;
String [] kernelNames = new String[] {"Gaussian blur", "Sharpen", "Outline", "Laplace", "Sobel X", "Sobel Y", "Sobel TLBR", "Sobel BRTL", "Emboss", "Box Blur", "Kernel 1"};


String description = "Visualization of convolution matrix arithmetic";
String name = "Convolution";
String author = "amc";

int guiPositionX = 55;
int drawSize = 1024;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  // kernels
  //// - Gaussian blur 3x3
  float[][] blur_matrix = {  { 1.0/16, 2.0/16, 1.0/16 },
                           { 2.0/16, 4.0/16, 1.0/16 },
                           { 1.0/16, 2.0/16, 1.0/16 } };
  float[] blur_matrix_minmax = {1.0/16, 4.0/16};
  kernels[0] = new Kernel(blur_matrix, blur_matrix_minmax, "Gaussian blur");

  //// - Shapren
  float[][] sharpen_matrix = {  { 0.0, -1.0, 0.0 },
                               { -1.0, 5.0, -1.0 },
                               { 0.0, -1.0, 0.0 } };
  float[] sharpen_matrix_minmax = {-1.0, 5.0};
  kernels[1] = new Kernel(sharpen_matrix, sharpen_matrix_minmax, "Sharpen");

  //// - Outline
  float[][] outline_matrix = {  { -1.0, -1.0, -1.0 },
                             { -1.0, 8.0, -1.0 },
                             { -1.0, -1.0, -1.0 } };
  float[] outline_matrix_minmax = {-1.0, 8.0};
  kernels[2] = new Kernel(outline_matrix, outline_matrix_minmax, "Outline");

  //// - Laplace
  float[][] laplace_matrix = {  { 1.0, 2.0, 1.0 },
                               { 2.0, -12.0, 2.0 },
                               { 1.0, 2.0, 1.0 } };
  float[] laplace_matrix_minmax = {-12.0, 2.0};
  kernels[3] = new Kernel(laplace_matrix, laplace_matrix_minmax, "Laplace");

  //// - Sobel Horizontal
  float[][] sobelX_matrix = {  { -1.0, 0.0, 1.0 },
                               { -2.0, 0.0, 2.0 },
                               { -1.0, 0.0, 1.0 } };
  float[] sobelX_matrix_minmax = {-2.0, 2.0};
  kernels[4] = new Kernel(sobelX_matrix, sobelX_matrix_minmax, "Sobel X");

  //// - Sobel Verticle
  float[][] sobelY_matrix = {  { 1.0, 2.0, 1.0 },
                               { 0.0, 0.0, 0.0 },
                               { -1.0, -2.0, -1.0 } };
  float[] sobelY_matrix_minmax = {-2.0, 2.0};
  kernels[5] = new Kernel(sobelY_matrix, sobelY_matrix_minmax, "Sobel Y");

  //// - Sobel TLBR
  float[][] sobelTLBR_matrix = {  { -2.0, -1.0, 0.0 },
                               { -1.0, 0.0, 1.0 },
                               { 0.0, 1.0, 2.0 } };
  float[] sobelTLBR_matrix_minmax = {-2.0, 2.0};
  kernels[6] = new Kernel(sobelTLBR_matrix, sobelTLBR_matrix_minmax, "Sobel TLBR");

  //// - Sobel BLTR
  float[][] sobelBLTR_matrix = {  { 0.0, 1.0, 2.0 },
                               { -1.0, 0.0, 1.0 },
                               { -2.0, -1.0, 0.0 } };
  float[] sobelBLTR_matrix_minmax = {-2.0, 2.0};
  kernels[7] = new Kernel(sobelBLTR_matrix, sobelBLTR_matrix_minmax, "Sobel BLTR");

  //// - Emboss
  float[][] emboss_matrix = {  { -2.0, -1.0, 0.0 },
                               { -1.0, 1.0, 1.0 },
                               { 0.0, 1.0, 2.0 } };
  float[] emboss_matrix_minmax = {-2.0, 2.0};
  kernels[8] = new Kernel(emboss_matrix, emboss_matrix_minmax, "Emboss");

  //// - Box Blur
  float[][] boxBlur_matrix = {  { 1.0, 1.0, 1.0 },
                               { 1.0, 1.0, 1.0 },
                               { 1.0, 1.0, 1.0 } };
  float[] boxBlur_matrix_minmax = {1.0, 1.0};
  kernels[9] = new Kernel(boxBlur_matrix, boxBlur_matrix_minmax, "Box Blur");

  //// - Kernel1
  float[][] kernel1_matrix = {  { -1.0, -1.0, -1.0 },
                             { -1.0, 9.0, -1.0 },
                             { -1.0, -1.0, -1.0 } };
  float[] kernel1_matrix_minmax = {-1.0, 9.0};
  kernels[10] = new Kernel(kernel1_matrix, kernel1_matrix_minmax, "Kernel 1");

  pixelOutput = new color[px.width*px.height];

  createGUI();
}

void destroy() {
  println("Destroy " + name);
  removeGUI();

  px.blendMode(BLEND);
  px.resetShader();
}

void update() {
  takeSnapshot();
  updateGUI();

  if ((bToggle)&&(frameCount%7==0)){
    kernelID = (int)Math.floor(Math.random()*kernelNames.length);
  }
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  if (!bDone){
    renderConvolution();
  }else{
    bDone = false;
    bShot = false;
  }

  image(px, 600, 0);
  
  displayInfo();
}

void createGUI() {
  listKernel = cp5.addDropdownList("Select Kernel")
                  .setPosition(guiPositionX, 200)
                  .setSize(400,300)
                  .setItemHeight(40)
                  .setBarHeight(40)
                  .setValue(0)
                  .addItems(kernelNames)
                  ;

  toggle = cp5.addToggle("One Kernel Mode Toggle")
              .setPosition(guiPositionX,100)
              .setSize(50,20)
              .setValue(true)
              .setMode(ControlP5.SWITCH)
              ;
}

void updateGUI(){
  bToggle = toggle.getValue()>0?true:false;
  if(!bToggle) kernelID = (int)listKernel.getValue();
}

void removeGUI(){
  cp5.remove("Select Kernel");
  cp5.remove("One Kernel Mode Toggle");
}

void takeSnapshot(){
  pg.filter(GRAY);
  image(pg, px.width, px.height);
  loadPixels();
  pixelSnapshot = new color [(px.width+2)*(px.height+2)];

  for (int y = 0; y < px.height; y++){
    for (int x = 0; x < px.width; x++){
        pixelSnapshot[(y+1)*px.width+(x+1)] = pg.pixels[y*px.width+x];
    }
  }
}

void renderConvolution() {
  // <GOAL> to go through each pixel, run convolution arithmetic

  // draw the snapshot and background
  displayResult();

  // fill out the gap
  for (int x = __x; x <= __x+__gap; x++) {
    for (int y = __y; y <= __y+__gap; y++ ) {
      if((x<px.width)&&(y<px.height)){
        color c = convolution(x, y, kernels[kernelID].matrix, matrixsize);
        pixelOutput[x+y*px.width] = c;
      }
    }
  }

  px.beginDraw();

  if((__x<px.width)&&(__y<px.height)){
    // show the selected pixel
    px.noFill();
    px.stroke(255);
    px.strokeWeight(2);
    px.rect(x_offset+__x-1, __y+1, 3, 3);

    int w = 25;
    // show source pixels (3x3, with values)
    for (int y = -1; y <= 1; y++){
      for (int x = -1; x <= 1; x++){
        int loc_x = 200+x*105-w/2+x_offset;
        int loc_y = 540+y*105-w/2;
        px.noStroke();
        int loc_val = pixelSnapshot[(__x+x+1)+px.width*(__y+y+1)];
        px.fill(loc_val);
        px.rect(loc_x, loc_y, w+5, w+5);
      }
    }

    // kernel (with values)
    for (int y = 0; y <= 2; y++){
      for (int x = 0; x <= 2; x++){
        int loc_x = 540+(x-1)*105-w/2+x_offset;
        int loc_y = 540+(y-1)*105-w/2;
        px.noStroke();
        color c = lerpColor(color(0), color(255), kernels[kernelID].matrix[x][y]/(kernels[kernelID].matrix_minmax[1] - kernels[kernelID].matrix_minmax[0]));
        px.fill(c);
        px.rect(loc_x, loc_y, w+5, w+5);
      }
    }

    color cPixel;
    // show the output pixels
    for (int y = -1; y <= 1; y++){
      for (int x = -1; x <= 1; x++){
        px.noStroke();
        int loc_x = 880+x*105-w/2+x_offset;
        int loc_y = 540+y*105-w/2;
        cPixel = convolutionPixel(__x+x,__y+y,x+1,y+1,kernels[kernelID].matrix);
        px.fill(cPixel);
        px.rect(loc_x, loc_y, w+5, w+5);

        __c[0] += red(cPixel);
        __c[1] += green(cPixel);
        __c[2] += blue(cPixel);
      }
    }

    __c[0] = constrain(__c[0], 0, 255);
    __c[1] = constrain(__c[1], 0, 255);
    __c[2] = constrain(__c[2], 0, 255);

    pixelOutput[__x + px.width*__y] = color(__c[0], __c[1], __c[2]);

    px.fill(pixelOutput[__x + px.width*__y]);

    px.endDraw();

    __c = new int [3];


    if(__x + __gap < px.width){
      __x = __x + __gap;
    }else{
      if(__y + __gap < px.height){
        __x = 0;
        __y = __y + __gap;
        __y++;
      }else{
        // state2 complete
        resetRender();
      }
    }
  }else{
    // state2 complete
    resetRender();
  }
}

void resetRender(){
  __x = 2;
  __y = 2;
  bDone = true;
  bShot = false;
}


color convolutionPixel(int x, int y, int i, int j, float[][] matrix) {
  float r= 0.0;
  float g = 0.0;
  float b = 0.0;

  int loc = (x+1) + px.width*(y+1);

  // Calculate the convolution
  r = red(pixelSnapshot[loc]) * matrix[i][j];
  g = green(pixelSnapshot[loc]) * matrix[i][j];
  b = blue(pixelSnapshot[loc]) * matrix[i][j];

  // Return the resulting color
  return color(r, g, b);
}

color convolution(int x, int y, float[][] matrix, int matrixsize) {
  float rtotal = 0.0;
  float gtotal = 0.0;
  float btotal = 0.0;
  int offset = matrixsize / 2;

  for (int i = 0; i < matrixsize; i++){
    for (int j= 0; j < matrixsize; j++){
      // What pixel are we testingc
      int xloc = x+i-offset;
      int yloc = y+j-offset;
      int loc = (xloc+1) + px.width*(yloc+1);

      // Calculate the convolution
      rtotal += (red(pixelSnapshot[loc]) * matrix[i][j]);
      gtotal += (green(pixelSnapshot[loc]) * matrix[i][j]);
      btotal += (blue(pixelSnapshot[loc]) * matrix[i][j]);
    }
  }
  // Make sure RGB is within range
  rtotal = constrain(rtotal, 0, 255);
  gtotal = constrain(gtotal, 0, 255);
  btotal = constrain(btotal, 0, 255);

  // Return the resulting color
  return color(rtotal, gtotal, btotal);
}

void displayResult(){
  // draw the result
  px.beginDraw();
  px.loadPixels();
  for (int y = 0; y < px.height; y++){
    for (int x = 0; x < px.width; x++){
      px.pixels[y*px.width+x] = pixelOutput[y*px.width+x];
      //px.pixels[y*px.width+x] = pg.pixels[y*px.width+x];
    }
  }
  px.updatePixels();
  px.endDraw();

  //noStroke();
  //fill(0);
  //rect(x_offset,350,1080,380);
}

class Kernel{
  String name;
  float[][] matrix;
  float[] matrix_minmax;
  Kernel(float[][] m, float[] m_mm, String n){
    matrix = m;
    matrix_minmax = m_mm;
    name = n;
  }
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
