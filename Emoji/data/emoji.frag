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
uniform sampler2D u_emojiTex;

uniform vec2 resolution;
uniform float u_steps;
uniform float u_emojiSize;
uniform float u_emojiTexW;
uniform float u_emojiTexH;

vec4 lookupEmoji(vec3 hsv, vec2 texSize, vec2 pixelSize){
  vec2 pos = mod(gl_FragCoord.xy,pixelSize.xy);
  float row = (floor((hsv.r)*19.999)/20 + floor((1.-hsv.g)*2.999))/3;
  float col = floor(hsv.b*19.999)/20;

  pos = pos / texSize;
  pos.x += row;
  pos.y += col;
  // pos.y -= col; // Not right, but does interesting things!
  return vec4(texture2D(u_emojiTex,pos).rgb,1.0);
}


float luma(vec3 rgb)
{
  const vec3 W = vec3(0.2125, 0.7154, 0.0721);
  return dot(rgb, W);
}

vec3 rgb2hsv(vec3 c){
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
  vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c){
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


out vec4 fragColor;

void main()
{
  vec2 st = gl_FragCoord.xy / resolution.xy;

  vec2 invViewport = vec2(1.0) / resolution;

  vec2 pixelSize = vec2(u_emojiSize, u_emojiSize);
  vec2 texSize = vec2(u_emojiTexW, u_emojiTexH);

  vec4 sum = vec4(0.0);
  vec2 uvClamped = st-mod(st, pixelSize * invViewport);

  for (float x=0.0;x<pixelSize.x;x++){
    for (float y=0.0;y<pixelSize.y;y++){
      vec2 offset = vec2(x,y);
      sum += texture2D(texture,uvClamped+(offset*invViewport));
    }
  }

  vec4 average = sum / vec4(pixelSize.x*pixelSize.y);

  float brightness = luma(average.rgb);
  vec3 hsv = rgb2hsv(average.rgb);
  vec4 clampedColor = floor(average*u_steps)/u_steps;

  fragColor = lookupEmoji(hsv, texSize, pixelSize);
}

