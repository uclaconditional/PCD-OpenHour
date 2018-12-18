/*
**	Adapted from Morten Nobel's ASCII art generator:
**	https://blog.nobel-joergensen.com/2011/11/12/creating-real-time-video-ascii-art-using-kickjs-and-webgl/
*/

#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform sampler2D u_asciiTex;

uniform vec2  resolution;
uniform int   u_mode;
uniform float u_steps;
uniform vec2  u_fontSize;
uniform vec3  u_fontClr;
// const vec2 fontSize = vec2(8.0,16.0);
// const vec2 fontSize = vec2(12.0,24.0);

vec4 lookupASCII(float asciiValue){
  vec2 pos = mod(gl_FragCoord.xy, u_fontSize);

  pos = pos / vec2(u_fontSize.x*94, u_fontSize.y);
  pos.x += asciiValue;
  pos.y = 1 - pos.y;
  return vec4(texture2D(u_asciiTex,pos).rgba);
}

float luma(vec3 rgb)
{
  const vec3 W = vec3(0.2125, 0.7154, 0.0721);
  return dot(rgb, W);
}

out vec4 fragColor;

void main()
{
  vec2 st = gl_FragCoord.xy / resolution.xy;

  vec2 invViewport = vec2(1.0) / resolution;
  vec2 pixelSize = u_fontSize;
  vec4 sum = vec4(0.0);
  vec2 uvClamped = st-mod(st,pixelSize * invViewport);
  for (float x=0.0;x<u_fontSize.x;x++){
    for (float y=0.0;y<u_fontSize.y;y++){
        vec2 offset = vec2(x,y);
        sum += texture2D(texture,uvClamped+(offset*invViewport));
    }
  }
  vec4 average = sum / vec4(u_fontSize.x*u_fontSize.y);
  float brightness = (average.x+average.y+average.z)*0.33333;
  vec4 clampedColor = floor(average*u_steps)/u_steps;
  float asciiChar = floor((1.0-brightness)*94.0)/94.0;

  if (u_mode == 0) {
    fragColor = clampedColor*lookupASCII(asciiChar);
  } else if (u_mode == 1) {
    clampedColor = vec4( vec3(luma(clampedColor.rgb)), clampedColor.a );
    fragColor = clampedColor*lookupASCII(asciiChar);
  } else if (u_mode == 2) {
    fragColor = lookupASCII(asciiChar)*vec4(u_fontClr, 1.);
  }
}

