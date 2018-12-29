#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER
#define M_PI 3.1415926535897932384626433832795

uniform sampler2D texture;

uniform vec2 resolution;
uniform float distortFactor;

void main(void) {
    vec2 st = gl_FragCoord.xy / resolution.xy;

    float angularSpeed = M_PI * 2;
    float offset = distortFactor * (-cos(angularSpeed * st.y)+0.5);
    vec2 warpedSt = vec2(st.x, st.y + offset);
    
    gl_FragColor = texture2D(texture, warpedSt);
}
