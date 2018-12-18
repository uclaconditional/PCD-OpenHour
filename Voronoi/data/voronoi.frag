uniform ivec2 uResolution;
uniform sampler2D uTexture;
uniform int uSeed;

uniform sampler2D prepTexture;

#define PROCESSING_TEXTURE_SHADER

void main() {
   
    int random = uSeed;
    int a = 1103515245;
    int c = 12345;
    int m = 2147483648;

    vec2 o;
    vec2 prevO;

    vec4 prepValue = texture2D(prepTexture, gl_FragCoord.xy/uResolution.xy);
    vec2 uv = prepValue.xy;
    float minDist = prepValue.b;
    uv.x = 1.0 - uv.x;
    gl_FragColor = (texture(uTexture, uv)) * (1.0 - minDist);
    
    
}
