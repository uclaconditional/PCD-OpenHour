uniform sampler2D firstPass;
uniform ivec2 uResolution;

void main() {

	vec2 tempCoord = gl_FragCoord.xy / uResolution.xy;
	gl_FragColor = texture(firstPass, tempCoord);
}