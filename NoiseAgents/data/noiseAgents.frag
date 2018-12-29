#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform vec2 resolution;
//uniform vec2 u_mouse;
uniform float time;

uniform sampler2D texture;  // mainImage texture
uniform sampler2D camera;  // Camera texture
uniform sampler2D currDots;


void main() {
    vec2 regSt = gl_FragCoord.xy/resolution.xy;
    vec2 st = gl_FragCoord.xy/resolution.xy*3.;
    
    vec4 mainColor = texture2D(texture, regSt);
    vec4 color = texture2D(camera, regSt);
    vec4 dots = texture2D(currDots, regSt);
    
    gl_FragColor = vec4(color.rgb * dots.a + mainColor.rgb * (1.0 - dots.a), 1.0);
//    gl_FragColor = vec4(dots.rgb, 1.0);
//    gl_FragColor = vec4(color.rgb, 1.0);
//    gl_FragColor = vec4(color.rgb * dots.a + vec3(1.0, 0.0, 1.0) * (1.0 - dots.a), 1.0);
//    gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
    
}

