#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

uniform vec2 resolution;
uniform float amountRotation = 2.0;
uniform float sizeOfEffect = 0.3;
uniform float imageScale = 0.9;

void main(void) {
    vec2 st = gl_FragCoord.xy / resolution.xy;  // Map screen coordinate to 0.0-1.0

    vec2 originCoord = vec2(0.5, 0.5);
    
    float x = st.x - originCoord.x;
    float y = st.y - originCoord.y;
    
    // Source: https://stackoverflow.com/questions/225548/resources-for-image-distortion-algorithms
    float angle = amountRotation * exp(-(x*x+y*y)/(sizeOfEffect*sizeOfEffect));
    float u = cos(angle)*x + sin(angle)*y;
    float v = -sin(angle)*x + cos(angle)*y;
    
    vec2 texAccessCoord = vec2(u * imageScale + originCoord.x, v * imageScale + originCoord.y);
    
    gl_FragColor = texture2D(texture, texAccessCoord);
}
