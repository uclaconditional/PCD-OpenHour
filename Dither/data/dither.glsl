#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

varying vec4 vertTexCoord;
uniform sampler2D texture;

float Dither(float color){
  int indexMatrix4x4[16] = int[]( 0,  8,  2,  10,
                                  12, 4,  14, 6,
                                  3,  11, 1,  9,
                                  15, 7,  13, 5);
  float closestColor = (color < 0.6) ? 0 : 1;
  float secondClosestColor = 1 - closestColor;
  int x = int(mod(gl_FragCoord.x, 4));
  int y = int(mod(gl_FragCoord.y, 4));
  float d = indexMatrix4x4[ x+y*4 ] / 16.0;
  float distance = abs(closestColor - color);
  return (distance < d) ? closestColor : secondClosestColor;
}

void main(void) {	
	vec3 col = texture2D(texture, vertTexCoord.st).rgb;
	float bright = 0.33333 * (col.r + col.g + col.b);
	float c = Dither(bright);
  	gl_FragColor = vec4(c, c, c, 1.0);
}