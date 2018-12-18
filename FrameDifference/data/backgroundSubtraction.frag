#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform sampler2D prevTexture;
uniform sampler2D masterTexture;

uniform vec2 resolution;
uniform float distortFactor;

uniform float lowerThreshold;
uniform float higherThreshold;

void main(void) {
    vec2 step = vec2(1.0) / resolution.xy;
    
    vec2 st = gl_FragCoord.xy / resolution.xy;
    // When pg.get() is called the texture somehow gets flipped vertically
    // This is to unfilp it
    vec2 stPrev = vec2(st.x, 1.0 - st.y);
    
    vec4 curr = texture2D(texture, st);
    vec4 prev = texture2D(prevTexture, stPrev);
    vec4 master = texture2D(masterTexture, stPrev);
    
    float grayCurr = dot(curr.rgb, vec3(0.299, 0.587, 0.114));
    float grayPrev = dot(prev.rgb, vec3(0.299, 0.587, 0.114));

    vec4 diff = curr - prev;
    float dist = distance(curr, prev);
//    float deNoised = step(0.1, dist);
//    vec4 deNoised = smoothstep(0.0, 0.1, diff);
    float deNoised = smoothstep(lowerThreshold, higherThreshold, dist);
    
//    vec4 result;
//    result = step(0.05, diff) * diff;
    
//    float diffGray = grayCurr - grayPrev;
//    vec4 resultGray = vec4(vec3(step(0.1, diffGray)), 1.0);
    
//    gl_FragColor = vec4(vec3(grayCurr), 1.0);
//    gl_FragColor = result;
    vec4 resultColor = mix(master, curr, deNoised);
    gl_FragColor = resultColor;
//    gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
//    gl_FragColor = vec4(vec3(deNoised), 1.0);
//    gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
//    gl_FragColor = master;
//    gl_FragColor = deNoised;
}
