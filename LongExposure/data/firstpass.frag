uniform sampler2D firstPass;
uniform sampler2D uTexture;

uniform ivec2 uResolution;
uniform float uDelay;


void main() {
	float newAddition = 1. - uDelay;
    vec2 tempCoord = gl_FragCoord.xy / uResolution.xy;
    gl_FragColor = texture(firstPass, tempCoord) * uDelay + texture(uTexture, tempCoord) * newAddition;
}