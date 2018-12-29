#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform vec2 resolution;
//uniform vec2 u_mouse;
uniform float time;
uniform float tileTimes = 0.3;

uniform vec2 centerPosition;

uniform sampler2D texture;  // mainImage texture
uniform sampler2D camera;  // Camera texture
uniform sampler2D currImage;

float random (vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
                 43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);
    
    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) +
    (c - a)* u.y * (1.0 - u.x) +
    (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}



void main() {
    vec2 regSt = gl_FragCoord.xy/resolution.xy;
//    vec2 tiledSt = gl_FragCoord.xy/resolution.xy
    vec2 tiledSt = fract(gl_FragCoord.xy/(resolution.xy/tileTimes));
    vec2 st = gl_FragCoord.xy/resolution.xy*3.;
    vec2 centerPos = centerPosition/resolution.xy;
    centerPos.y = 1.0 - centerPos.y;
    
    vec2 relativeToCenterPos = (regSt - centerPos) + vec2(0.5, 0.5);
    
    vec4 mainColor = texture2D(texture, regSt);
    vec4 cameraColor = texture2D(camera,  relativeToCenterPos);
    vec4 currColor = texture2D(currImage, regSt);
    
    vec2 q = vec2(0.0);
    q.x = fbm( st + 0.00*time);
    q.y = fbm( st + vec2(1.0));
    
    vec2 r = vec2(0.0);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ sin(0.3*time));
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ sin(0.3*time));
    
    float f = fbm(st+r);
    
    vec3 texColorR = texture2D(camera, r * vec2(0.3)).rgb;
    vec3 texColorT = texture2D(camera, r * vec2(0.3) + vec2(0.05, 0.05)).rgb;
    
    vec3 noiseColor = mix(texColorR,
                texColorT,
                clamp((f*f)*4.0,0.0,1.0));
    
    vec3 newColor = cameraColor.rgb * currColor.rgb;
//    vec3 newColor = currColor.rgb;
    
    gl_FragColor = vec4(newColor * currColor.a + mainColor.rgb * (1.0 - currColor.a), 1.0);
//    gl_FragColor = vec4(relativeToCenterPos, 0.0, 1.0);
//    gl_FragColor = vec4(cameraColor.rgb, 1.0);
//    gl_FragColor = vec4(vec3(currColor.a), 1.0);
//    gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
//    gl_FragColor = vec4(color.rgb, 1.0);
    
}
