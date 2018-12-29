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
**  Adapted from Thomas Diewald's OpticalFlow_Movie example in
**  the PixelFlow library:
**  https://github.com/diwi/PixelFlow/tree/master/examples/OpticalFlow/OpticalFlow_MovieFluid

**  I ran into an issue adapting this. There is an extra bit of
**  code written for the example to override and extend the DwFluid2D
**  class in PixelFlow. It was written under the assumption that all
**  variables would be in the global scope and therefore accessible
**  without needing to be passed. Additionally, the main PixelFlow class
**  takes the main PApplet app as an argument in its constructor, so
**  I had to declare a global PApplet variable to reference.
**  I'm going to see if I can figure out an alternate implementation
**  of this that doesn't deviate from the self-contained nature of
**  the module system. -L05
*/

import java.util.Locale;

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.dwgl.DwGLSLProgram;
import com.thomasdiewald.pixelflow.java.fluid.DwFluid2D;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;

import processing.core.*;
import processing.opengl.PGraphics2D;
import processing.video.Movie;

import processing.video.*;
import controlP5.*;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

///////////////////////////////////
// Global variables (to be included in camera_01.pde if multiple
// modules use them?)
///////////////////////////////////

// main library context
DwPixelFlow context;

// optical flow
DwOpticalFlow opticalflow;

// render targets
PGraphics2D pg_movie;
// PApplet app = this;

private class MyFluidData implements DwFluid2D.FluidData{


    @Override
    // this is called during the fluid-simulation update step.
    public void update(DwFluid2D fluid) {

      addDensityTexture_cam(fluid, opticalflow);
      addVelocityTexture   (fluid, opticalflow);
      // addTemperatureTexture(fluid, opticalflow);
    }


    public void addDensityTexture_cam(DwFluid2D fluid, DwOpticalFlow opticalflow){
      int[] pg_tex_handle = new int[1];

      if( !pg_movie.getTexture().available() ) {
        System.out.println("no tex");
        return;
      }

      float mix = opticalflow.UPDATE_STEP > 1 ? 0.05f : 1.0f;

      context.begin();
      context.getGLTextureHandle(pg_movie, pg_tex_handle);
      context.beginDraw(fluid.tex_density.dst);
      DwGLSLProgram shader = context.createShader("data/addDensityCam.frag");
      shader.begin();
      shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);
      shader.uniform1i     ("blend_mode", 6);
      shader.uniform1f     ("mix_value" , mix);
      shader.uniform1f     ("multiplier", 1f);
      // shader.uniformTexture("tex_ext"   , opticalflow.tex_frames.src);
      shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
      shader.uniformTexture("tex_src"   , fluid.tex_density.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end("app.addDensityTexture");
      fluid.tex_density.swap();
    }


    // custom shader, to add temperature from a texture (PGraphics2D) to the fluid.
    public void addTemperatureTexture(DwFluid2D fluid, DwOpticalFlow opticalflow){
      context.begin();
      context.beginDraw(fluid.tex_temperature.dst);
      DwGLSLProgram shader = context.createShader("data/addTemperature.frag");
      shader.begin();
      shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);
      shader.uniform1i     ("blend_mode", 1);
      shader.uniform1f     ("mix_value" , 0.1f);
      shader.uniform1f     ("multiplier", 0.01f);
      shader.uniformTexture("tex_ext"   , opticalflow.frameCurr.velocity);
      shader.uniformTexture("tex_src"   , fluid.tex_temperature.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end("app.addTemperatureTexture");
      fluid.tex_temperature.swap();
    }


    // custom shader, to add density from a texture (PGraphics2D) to the fluid.
    public void addVelocityTexture(DwFluid2D fluid, DwOpticalFlow opticalflow){
      context.begin();
      context.beginDraw(fluid.tex_velocity.dst);
      DwGLSLProgram shader = context.createShader("data/addVelocity.frag");
      shader.begin();
      shader.uniform2f     ("wh"             , fluid.fluid_w, fluid.fluid_h);
      shader.uniform1i     ("blend_mode"     , 2);
      shader.uniform1f     ("multiplier"     , 0.5f);
      shader.uniform1f     ("mix_value"      , 0.1f);
      shader.uniformTexture("tex_opticalflow", opticalflow.frameCurr.velocity);
      shader.uniformTexture("tex_velocity_old", fluid.tex_velocity.src);
      shader.drawFullScreenQuad();
      shader.end();
      context.endDraw();
      context.end("app.addDensityTexture");
      fluid.tex_velocity.swap();
    }
  }

//////////////////////////////
// Optical Flow Module
//////////////////////////////

// fluid stuff
int fluidgrid_scale = 1;
DwFluid2D fluid;

// render targets
PGraphics2D pg_temp;
PGraphics2D pg_oflow;

// some state variables for the GUI/display
int     BACKGROUND_COLOR = 0;
boolean DISPLAY_SOURCE   = true;
boolean APPLY_GRAYSCALE  = false;
boolean APPLY_BILATERAL  = true;
int     VELOCITY_LINES   = 6;

boolean UPDATE_FLUID = true;

boolean DISPLAY_FLUID_TEXTURES  = true;
boolean DISPLAY_FLUID_VECTORS   = false;//!true;
boolean DISPLAY_PARTICLES       = false;//!true;

int     DISPLAY_fluid_texture_mode = 0;

Slider s_dissipation_velocity;
Slider s_dissipation_density;
Slider s_dissipation_temperature;
Slider s_vorticity;
Slider s_num_jacobi_projection;
Slider s_timestep;
Slider s_gridscale;

float dissipation_velocity;
float dissipation_density;
float dissipation_temperature;
float vorticity;
float timestep;
float gridscale;

int   num_jacobi_projection;

// CSB Adjust
PShader csb_adjustShader;

float contrast;
float saturation;
float brightness;

Slider s_contrast;
Slider s_saturation;
Slider s_brightness;

int  guiPositionX = 55;


String description = "Optical Flow example from PixelFlow library.";
String name = "Optical Flow";
String author = "Thomas Diewald, L05";

int drawSize = 1024;


void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  println("Create " + name);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  createGUI();

  px.resetShader();
  px.noTint();

  // GUI Parameters
  dissipation_velocity      = 1.0;
  dissipation_density       = 1.0;
  dissipation_temperature   = 1.0;
  vorticity                 = 0.3;
  num_jacobi_projection     = 40;
  timestep                  = 0.65;
  gridscale                 = 1;

  // main library context
  context = new DwPixelFlow(this);
  context.print();
  context.printGL();

  // optical flow object
  opticalflow = new DwOpticalFlow(context, px.width, px.height);
  opticalflow.param.display_mode = 1;

  // fluid object
  fluid = new DwFluid2D(context, px.width, px.height, fluidgrid_scale);
  // initial fluid parameters
  fluid.param.dissipation_velocity    = dissipation_velocity;
  fluid.param.dissipation_density     = dissipation_density;
  fluid.param.dissipation_temperature = dissipation_temperature;
  fluid.param.vorticity               = vorticity;
  fluid.param.num_jacobi_projection   = num_jacobi_projection;
  fluid.param.timestep                = timestep;
  fluid.param.gridscale               = gridscale;
  // callback for adding fluid data
  fluid.addCallback_FluiData(new MyFluidData());

  // init render targets
  pg_movie = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_movie.smooth(0);
  pg_movie.beginDraw();
  pg_movie.background(0);
  pg_movie.endDraw();

  pg_temp = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_temp.smooth(0);

  pg_oflow = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_oflow.smooth(0);

  // init CSB adjust shader
  contrast    = 1;
  saturation  = 1;
  brightness  = 1;

  csb_adjustShader = loadShader("data/csb_adjust.frag");
  csb_adjustShader.set("u_contrast", contrast);
  csb_adjustShader.set("u_saturation", saturation);
  csb_adjustShader.set("u_brightness", brightness);

  background(0);

  printSettings();
}

void destroy() {
  println("Destroy " + name);
  removeGUI();
  resetShader();
  px.resetShader();

  pg_temp           = null;
  pg_oflow          = null;
  pg_movie          = null;
  fluid             = null;
  csb_adjustShader  = null;
}

void update() {
  updateGUI();

  fluid.param.dissipation_velocity    = dissipation_velocity;
  fluid.param.dissipation_density     = dissipation_density;
  fluid.param.dissipation_temperature = dissipation_temperature;
  fluid.param.vorticity               = vorticity;
  fluid.param.num_jacobi_projection   = num_jacobi_projection;
  fluid.param.timestep                = timestep;
  fluid.param.gridscale               = gridscale;

  csb_adjustShader.set("u_contrast", contrast);
  csb_adjustShader.set("u_saturation", saturation);
  csb_adjustShader.set("u_brightness", brightness);
}

void draw() {
  background(0);
  update();
  grabCamImage();

  // render to offscreenbuffer
  pg_movie.beginDraw();
  pg_movie.background(0);
  pg_movie.pushMatrix();
  pg_movie.translate(0, 0);
  pg_movie.image(pg, 0, 0, pg.width, pg.height);
  pg_movie.filter(csb_adjustShader);
  pg_movie.popMatrix();
  pg_movie.endDraw();

  // apply filters (not necessary)
  if(APPLY_GRAYSCALE){
    DwFilter.get(context).luminance.apply(pg_movie, pg_movie);
  }
  if(APPLY_BILATERAL){
    DwFilter.get(context).bilateral.apply(pg_movie, pg_temp, 5, 0.10f, 4);
    swapCamBuffer();
  }

  // update Optical Flow
  opticalflow.update(pg_movie);

  if(UPDATE_FLUID){
    fluid.update();
  }

  // render Optical Flow
  pg_oflow.beginDraw();
  pg_oflow.background(BACKGROUND_COLOR);
  if(DISPLAY_SOURCE){
    pg_oflow.image(pg_movie, 0, 0);
  }
  pg_oflow.endDraw();

  // add fluid stuff to rendering
  if(DISPLAY_FLUID_TEXTURES){
    fluid.renderFluidTextures(pg_oflow, DISPLAY_fluid_texture_mode);
  }

  if(DISPLAY_FLUID_VECTORS){
    fluid.renderFluidVectors(pg_oflow, 10);
  }

  // add flow-vectors to the image
  if(opticalflow.param.display_mode == 2){
    opticalflow.renderVelocityShading(pg_oflow);
  }
  // opticalflow.renderVelocityStreams(pg_oflow, VELOCITY_LINES);

  // display result
  px.beginDraw();
  px.background(0);
  px.image(pg_oflow, 0, 0);
  px.endDraw();

  image(px, 600, 0);
  displayInfo();
}

void createGUI() {
  s_dissipation_velocity = cp5.addSlider("dissipation_velocity")
    .setPosition(guiPositionX, 100)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_dissipation_density = cp5.addSlider("dissipation_density")
    .setPosition(guiPositionX, 150)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_dissipation_temperature = cp5.addSlider("dissipation_temperature")
    .setPosition(guiPositionX, 200)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_vorticity = cp5.addSlider("vorticity")
    .setPosition(guiPositionX, 250)
    .setSize(400, 30)
    .setRange(0, 2)
    .setValue(0.3)
    ;

  s_num_jacobi_projection = cp5.addSlider("num_jacobi_projection")
    .setPosition(guiPositionX, 300)
    .setSize(400, 30)
    .setRange(0, 2)
    .setValue(0.3)
    ;

  s_timestep = cp5.addSlider("timestep")
    .setPosition(guiPositionX, 350)
    .setSize(400, 30)
    .setRange(0, 2)
    .setValue(0.3)
    ;

  s_gridscale = cp5.addSlider("gridscale")
    .setPosition(guiPositionX, 400)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_contrast = cp5.addSlider("contrast")
    .setPosition(guiPositionX, 450)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_saturation = cp5.addSlider("saturation")
    .setPosition(guiPositionX, 500)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;

  s_brightness = cp5.addSlider("brightness")
    .setPosition(guiPositionX, 550)
    .setSize(400, 30)
    .setRange(0, 5)
    .setValue(1)
    ;
}

void updateGUI() {
  dissipation_velocity      = s_dissipation_velocity.getValue();
  dissipation_density       = s_dissipation_density.getValue();
  dissipation_temperature   = s_dissipation_temperature.getValue();
  vorticity                 = s_vorticity.getValue();
  num_jacobi_projection     = round(s_num_jacobi_projection.getValue());
  timestep                  = s_timestep.getValue();
  gridscale                 = s_gridscale.getValue();
  contrast                  = s_contrast.getValue();
  saturation                = s_saturation.getValue();
  brightness                = s_brightness.getValue();
}

void removeGUI() {
  cp5.remove("dissipation_velocity");
  cp5.remove("dissipation_density");
  cp5.remove("dissipation_temperature");
  cp5.remove("vorticity");
  cp5.remove("num_jacobi_projection");
  cp5.remove("timestep");
  cp5.remove("gridscale");
  cp5.remove("contrast");
  cp5.remove("saturation");
  cp5.remove("brightness");
}

//////////////////////////////
// Helper Functions
//////////////////////////////

void printSettings() {
  println("fluid.param.dissipation_velocity:\t" + str(fluid.param.dissipation_velocity));
  println("fluid.param.dissipation_density:\t" + str(fluid.param.dissipation_density));
  println("fluid.param.dissipation_temperature:\t" + str(fluid.param.dissipation_temperature));
  println("fluid.param.vorticity:\t\t" + str(fluid.param.vorticity));
  println("fluid.param.num_jacobi_projection:\t" + str(fluid.param.num_jacobi_projection));
  println("fluid.param.timestep:\t\t" + str(fluid.param.timestep));
  println("fluid.param.gridscale:\t\t" + str(fluid.param.gridscale));
  println("opticalflow.param.blur_input:\t\t" + str(opticalflow.param.blur_input));
  println("opticalflow.param.blur_flow:\t\t" + str(opticalflow.param.blur_flow));
  println("opticalflow.param.temporal_smoothing:\t" + str(opticalflow.param.temporal_smoothing));
  println("opticalflow.param.flow_scale:\t\t" + str(opticalflow.param.flow_scale));
  println("opticalflow.param.threshold:\t\t" + str(opticalflow.param.threshold));
}

void swapCamBuffer(){
  PGraphics2D tmp = pg_movie;
  pg_movie = pg_temp;
  pg_temp = tmp;
}

public void fluid_resizeUp(){
  fluid.resize(px.width, px.height, fluidgrid_scale = max(1, --fluidgrid_scale));
}
public void fluid_resizeDown(){
  fluid.resize(px.width, px.height, ++fluidgrid_scale);
}
public void fluid_reset(){
  fluid.reset();
  opticalflow.reset();
}
public void fluid_togglePause(){
  UPDATE_FLUID = !UPDATE_FLUID;
}
public void fluid_displayMode(int val){
  DISPLAY_fluid_texture_mode = val;
  DISPLAY_FLUID_TEXTURES = DISPLAY_fluid_texture_mode != -1;
}
public void fluid_displayVelocityVectors(int val){
  DISPLAY_FLUID_VECTORS = val != -1;
}
public void fluid_displayParticles(int val){
  DISPLAY_PARTICLES = val != -1;
}
public void opticalFlow_setDisplayMode(int val){
  opticalflow.param.display_mode = val;
}
public void activeFilters(float[] val){
  APPLY_GRAYSCALE = (val[0] > 0);
  APPLY_BILATERAL = (val[1] > 0);
}
public void setOptionsGeneral(float[] val){
  DISPLAY_SOURCE = (val[0] > 0);
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
