// Author @patriciogv - 2015
// http://patriciogonzalezvivo.com

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform vec2 resolution;
//uniform vec2 u_mouse;
uniform float time;

uniform sampler2D texture;

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
    vec2 st = gl_FragCoord.xy/resolution.xy*3.;
//     st += st * abs(sin(time*0.1)*3.0);
    vec3 color = vec3(0.0);
    
    vec2 q = vec2(0.0);
    q.x = fbm( st + 0.00*time);
    q.y = fbm( st + vec2(1.0));
    
    vec2 r = vec2(0.0);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ sin(0.3*time) );
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ sin(0.3*time));
    
    float f = fbm(st+r);
    
    vec3 texColorR = texture2D(texture, r * vec2(0.3)).rgb;
    vec3 texColorT = texture2D(texture, r * vec2(0.3) + vec2(0.05, 0.05)).rgb;
    vec3 texColorQ = texture2D(texture, q).rgb;
    
//    color = mix(vec3(0.101961,0.619608,0.666667),
//                vec3(0.666667,0.666667,0.498039),
//                clamp((f*f)*4.0,0.0,1.0));
//    
//    color = mix(color,
//                vec3(0,0,0.164706),
//                clamp(length(q),0.0,1.0));
    
//    color = mix(color,
//                vec3(0.666667,1,1),
//                clamp(length(r.x),0.0,1.0));  // Orig
    
    
    color = mix(texColorR,
                texColorT,
                clamp((f*f)*4.0,0.0,1.0));
    
//    color = mix(color,
//                texColorR,
//                clamp(length(q),0.0,1.0));
    
//    color = mix(color,
//                texColorR,
//                clamp(length(r.x),0.0,1.0));
    
//    gl_FragColor = vec4((f*f*f+.6*f*f+.5*f)*color,1.0);
    gl_FragColor = vec4(color,1.0);
//    gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
//    gl_FragColor = vec4(resolution, 0.0, 1.0);
}





























