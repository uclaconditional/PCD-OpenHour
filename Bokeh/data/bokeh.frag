uniform ivec2 uResolution;
uniform float uTime;
uniform sampler2D uTexture;
uniform bool light = false;

uniform float uSize = 6.0;
uniform float uBokehs = 24.0;
uniform float uTimer = 6.28;

void main(){
    vec2 uv = gl_FragCoord.xy / uResolution.xy;
    vec4 c  = texture(uTexture,uv);
    float t = uTime/1000;
    float d = .01+sin(uSize)*.01+60/uResolution.x;
    for(float i = 0.; i<uTimer;i+=uTimer/uBokehs){
        float a = i+t;
        vec4 c2 = texture(uTexture,vec2(uv.x+cos(a)*d,uv.y+sin(a)*d));
        if(light)
            c = max(c,c2);
        else
            c = min(c,c2);
    }
    gl_FragColor = c;
}