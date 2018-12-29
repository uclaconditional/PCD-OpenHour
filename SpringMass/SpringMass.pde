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

import com.thomasdiewald.pixelflow.java.DwPixelFlow;
import com.thomasdiewald.pixelflow.java.sampling.DwSampling;
import com.thomasdiewald.pixelflow.java.imageprocessing.DwOpticalFlow;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.DwFilter;
import com.thomasdiewald.pixelflow.java.softbodydynamics.DwPhysics;
import com.thomasdiewald.pixelflow.java.softbodydynamics.constraint.DwSpringConstraint;
import com.thomasdiewald.pixelflow.java.softbodydynamics.constraint.DwSpringConstraint2D;
import com.thomasdiewald.pixelflow.java.softbodydynamics.particle.DwParticle2D;
import com.thomasdiewald.pixelflow.java.softbodydynamics.softbody.DwSoftBall2D;
import com.thomasdiewald.pixelflow.java.softbodydynamics.softbody.DwSoftBody2D;

Capture cam;
ControlP5 cp5;

PGraphics px;
PGraphics pg;

int drawSize = 1024;

// From pixelFlow Library by Thomas Diewald

PGraphics2D pg_src;
PGraphics2D pg_render;
PGraphics2D pg_oflow;

DwOpticalFlow opticalflow;
float[] flow_velocity;

int sample_num = 800;

int viewport_w = drawSize;
int viewport_h = drawSize;
int viewport_x = 0;
int viewport_y = 0;

// physics parameters
DwPhysics.Param param_physics;
DwSpringConstraint.Param param_spring;

// physics simulation
DwPhysics<DwParticle2D> physics;

DwParticle2D[] particles;

ColorSchemes colorScheme;
color[] colors;

Slider sliderScale, sliderTh, sliderDampInc, sliderDampDec;

int valScale;
float valTh, valDampInc, valDampDec;


String description = "Spring-mass simulation combined with optical flow movement detection";
String name = "Spring-mass Model";
String author = "Thomas Diewald, amc";

int guiPositionX = 55;

void setup() {
  println("Create " + name);
  size(1624, 1024, P2D);
  cp5 = new ControlP5(this);
  
  px = createGraphics(drawSize, drawSize, P2D);
  pg = createGraphics(drawSize, drawSize, P2D);
  
  startWebCam();
  
  ColorSchemes.init(loadImage("colors.png"));
  
  flow_velocity = new float[(int)(px.width) * (int)(px.height) * 2];
  param_physics = new DwPhysics.Param();
  particles = new DwParticle2D[16];
  colors = new color[5];

  surface.setLocation(viewport_x, viewport_y);

  // main library context
  DwPixelFlow context = new DwPixelFlow(this);

  // physics object
  physics = new DwPhysics<DwParticle2D>(param_physics);

  // PixelFlow imageprocssing
  pg_src = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_src.noSmooth();

  opticalflow = new DwOpticalFlow(context, px.width, px.height);
  opticalflow.param.flow_scale = 24;
  opticalflow.param.threshold = 6.0f;

  pg_oflow = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_oflow.smooth(4);

  pg_render = (PGraphics2D) createGraphics(px.width, px.height, P2D);
  pg_render.smooth(8);

  // global physics parameters
  param_physics.GRAVITY = new float[]{ 0, 0 };
  param_physics.bounds  = new float[]{ 0, 0, px.width, px.height };
  param_physics.iterations_collisions = 4;  //4
  param_physics.iterations_springs    = 4;  //4

  // particle parameters
  DwParticle2D.Param param_particle = new DwParticle2D.Param();
  param_particle.DAMP_BOUNDS          = 0.40f;
  param_particle.DAMP_COLLISION       = 0.9990f;
  param_particle.DAMP_VELOCITY        = 0.994f;

  // spring parameters
  param_spring = new DwSpringConstraint.Param();
  param_spring.damp_dec = 0.899999f;
  param_spring.damp_inc = 0.899999f;

  // create particles + chain them together
  for(int i = 0; i < particles.length/2; i++){
    float radius = 50;
    float innerR = 255;
    float outerR = 260;
    float x = px.width/2 + innerR*(float)Math.cos(4*Math.PI/particles.length*i);
    float y = px.height/2 + innerR*(float)Math.sin(4*Math.PI/particles.length*i);
    float _x = px.width/2 + outerR*(float)Math.cos(4*Math.PI/particles.length*i);
    float _y = px.height/2 + outerR*(float)Math.sin(4*Math.PI/particles.length*i);

    particles[i] = new DwParticle2D(i, x, y, 1, param_particle);
    particles[i+particles.length/2] = new DwParticle2D(i+particles.length/2, _x, _y, radius, param_particle);

    particles[i].enable(false, false, false);

    DwSpringConstraint2D.addSpring(physics, particles[i], particles[i+particles.length/2], 2, param_spring);
  }

  // add all particles to the physics simulation
  physics.setParticles(particles, particles.length);

  //colorScheme = new ColorSchemes();
  //colors = colorScheme.get(ColorSchemes.NEON_FROG);
  colors = ColorSchemes.get(0);
  

  createGUI();
}

void destroy() {
  println("Destroy " + name);
  flow_velocity = null;
  param_physics = null;
  particles = null;
  colors = null;

  px.resetShader();
  px.blendMode(BLEND);

  pg_src.resetShader();
  pg_src = null;
  pg_render.resetShader();
  pg_render = null;
  pg_oflow.resetShader();
  pg_oflow = null;

  removeGUI();
}

void update() {
  updateGUI();

  pg_src.beginDraw();
  pg_src.blendMode(REPLACE);
  pg_src.image(pg, 0, 0);
  pg_src.endDraw();

  opticalflow.update(pg_src);
  flow_velocity = opticalflow.getVelocity(flow_velocity);
  updateParticles();

  physics.update(1);
}

void draw() {
  background(0);
  update();
  grabCamImage();
  
  // render springs: access the springs and use the current force for the line-color
  pg_render.beginDraw();
  {
    pg_render.clear();
    pg_render.blendMode(BLEND); // default
    pg_render.background(colors[0]);
    pg_render.noFill();
    pg_render.strokeWeight(10);
    pg_render.beginShape(LINES);
    ArrayList<DwSpringConstraint> springs = physics.getSprings();
    int n=0;
    for(DwSpringConstraint spring : springs){
      if(spring.enabled){
        DwParticle2D pa = particles[spring.idxPa()];
        DwParticle2D pb = particles[spring.idxPb()];
        float force = Math.abs(spring.force);
        pg_render.stroke(colors[(n+1)%4]);
        pg_render.vertex(pa.cx, pa.cy);
        pg_render.vertex(pb.cx, pb.cy);
      }
      n++;
    }
    pg_render.endShape();

    // render particles
    for(int i = 0; i < particles.length; i++){
      if (i>particles.length/2-1){
        DwParticle2D particle = particles[i];
        //pg_render.noStroke();
        pg_render.strokeWeight(8);
        pg_render.stroke(colors[(i+1)%4+1]);
        pg_render.fill(colors[i%4+1]);
        pg_render.ellipse(particle.cx, particle.cy, particle.rad*2, particle.rad*2);
        pg_render.fill(colors[(i+1)%4+1]);

        float v = particle.getVelocity();

        //pg_render.strokeWeight(2);
        pg_render.noStroke();
        pg_render.ellipse(particle.cx, particle.cy+particle.rad*2*0.2, particle.rad*2*0.8, particle.rad*2*(0.02+v/160));
        pg_render.fill(10);
        pg_render.ellipse(particle.cx-particle.rad*2*0.2, particle.cy-particle.rad*2*0.1, particle.rad*2*(0.08+v/450), particle.rad*2*(0.08+v/350));
        pg_render.ellipse(particle.cx+particle.rad*2*0.2, particle.cy-particle.rad*2*0.1, particle.rad*2*(0.08+v/450), particle.rad*2*(0.08+v/350));
      }
    }
  }
  pg_render.endDraw();

  pg_oflow.beginDraw();
  pg_oflow.clear();
  pg_oflow.endDraw();

  opticalflow.param.display_mode = 0;
  opticalflow.renderVelocityStreams(pg_oflow, 20);

  px.beginDraw();
  px.blendMode(REPLACE);
  px.image(pg_render, 0, 0);
  px.blendMode(ADD);
  px.image(pg_oflow, 0, 0);
  px.endDraw();

  image(px, 600, 0);

  // stats, to the title window
  String txt_fps = String.format(getClass().getName()+ "   [particles %d]   [frame %d]   [fps %6.2f]", particles.length,frameCount, frameRate);
  surface.setTitle(txt_fps);
  
  displayInfo();

}

void createGUI(){
  sliderScale = cp5.addSlider("optical flow scale")
    .setPosition(guiPositionX, 100)
    .setSize(400, 30)
    .setRange(0, 100)
    .setValue(24)
    ;
  sliderTh = cp5.addSlider("optical flow threshold")
    .setPosition(guiPositionX, 200)
    .setSize(400, 30)
    .setRange(0.0f, 4.0f)
    .setValue(1.50f)
    ;
  sliderDampInc = cp5.addSlider("damping inc")
    .setPosition(guiPositionX, 300)
    .setSize(400, 30)
    .setRange(0.0f, 5.0f)
    .setValue(2.000f)
    ;
  sliderDampDec = cp5.addSlider("damping dec")
    .setPosition(guiPositionX, 400)
    .setSize(400, 30)
    .setRange(0.0f, 5.0f)
    .setValue(1.000f)
    ;
}

void updateGUI(){
  opticalflow.param.flow_scale = (int)sliderScale.getValue();
  opticalflow.param.threshold = sliderTh.getValue();
  param_spring.damp_dec = sliderDampDec.getValue();
  param_spring.damp_inc = sliderDampInc.getValue();
}

void removeGUI(){
  cp5.remove("optical flow scale");
  cp5.remove("optical flow threshold");
  cp5.remove("damping inc");
  cp5.remove("damping dec");
}

public static class ColorSchemes {

  private static ColorSchemes instance = null;

  protected static color[][] schemes;
  public static int NEON_FROG = 0;
  public static int DONT_DANCE = 1;
  public static int ODD_BODIES = 2;
  public static int MOON_EYES = 3;
  public static int BYRN = 4;
  public static int MONA = 5;
  public static int TAFFY = 6;
  public static int POOL_TOYS = 7;

  protected ColorSchemes() {}

  public static void init(PImage src) {
    int count = src.height/20;
    ColorSchemes.schemes = new color[count][5];
    for (int i=0; i<count; i++) {
      for (int j=0; j<5; j++)
        ColorSchemes.schemes[i][j] = src.get(j * 20 + 5, i * 20 + 5);
    }
  }

  public static color[] get(int i) {
    return instance.schemes[i];
  }

  public static int getSize() {
    return schemes.length;
  }
}

void updateParticles(){
  for(int i = 0; i < particles.length; i++){
    float[] of_vxy = {0,0};
    for(int n = 0; n < sample_num; n++){
      float[] xy = DwSampling.sampleDisk_Halton(n, 0.1);
      int x = (int)(particles[i].cx + xy[0] * particles[i].rad * 1.2);
      int y = (int)(px.height - 1 - particles[i].cy + xy[1] * particles[i].rad * 1.2);
      x = Math.max(0,x);
      y = Math.max(0,y);
      x = Math.min(x,px.width-1);
      y = Math.min(y,px.height-1);
      int PIDX = y * px.width + x;
      of_vxy[0] += flow_velocity[2*PIDX + 0]*1/4;
      of_vxy[1] += -flow_velocity[2*PIDX + 1]*1/4;
    }
    particles[i].addForce(of_vxy);
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
