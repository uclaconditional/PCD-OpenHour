
uniform ivec2 uResolution;
uniform sampler2D uTexture;


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{ fragColor = texture( uTexture, fragCoord / uResolution.xy ); }

void main() {
	mainImage(gl_FragColor, gl_FragCoord.xy);
}