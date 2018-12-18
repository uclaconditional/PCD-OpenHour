uniform ivec2 uResolution;
//uniform sampler2D uTexture;
uniform int uSeed;

uniform int uDensity;

void main() {
    
    int random = uSeed;
    int a = 1103515245;
    int c = 12345;
    int m = 2147483648;

    vec2 o;
    vec2 prevO;

    float minDist = 10000.0;
    //SLOW I SHOULD FIND A DIFFERENT WAY TO DO THIS
    for(int i = 0; i < uDensity; i++)
    {
//        vec2 prevO = o;
        
        random = a * random + c;

        o.x = (float(random) / float(m)) * uResolution.x;

        random = a * random + c;

        o.y = (float(random) / float(m)) * uResolution.y;

        
        float currDist = distance(gl_FragCoord.xy, o);
//        float isTrue = step(minDist, currDist);
        float isTrue = step(currDist, minDist);
        
        minDist = isTrue * currDist + (1.0 - isTrue) * minDist;
        vec2 uv = isTrue * (o/uResolution.xy) + (1.0 - isTrue) * (prevO/uResolution.xy);
        uv.x = 1.0 - uv.x;
//        gl_FragColor = (texture(uTexture, uv)) * (1.0 - minDist / 200.0);
        prevO = isTrue * o + (1.0 - isTrue) * prevO;
//        gl_FragColor = vec4(i, 0.0, 0.0, 1.0);
//        gl_FragColor = vec4(uv, minDist, 1.0);
        gl_FragColor = vec4(uv, minDist/200.0, 1.0);
//        gl_FragColor = vec4(1.0, 0.5, 1.0, 1.0);
        
        
//        gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
//        gl_FragColor = vec4(uv, 0.0, 1.0);
    }
}
