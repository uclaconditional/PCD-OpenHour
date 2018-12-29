varying vec4 vertTexCoord;

uniform sampler2D u_current;
uniform sampler2D u_past;

uniform vec3 color1;
uniform vec3 color2;

void main(){
	vec2 uv = vertTexCoord.st;

	//get avg color of each frame
	//float currentFrame = dot(texture2D(u_current, uv).rgb, vec3(0.33333));
	float currentFrame = dot(texture2D(u_current, vec2(uv.x, 1.0 - uv.y)).rgb, vec3(0.33333));
	float pastFrame = dot(texture2D(u_past, vec2(uv.x, 1.0 - uv.y)).rgb, vec3(0.33333));
	//float pastFrame = dot(texture2D(u_past, uv).rgb, vec3(0.33333));

	//subtract them from each other
	float diff = abs(currentFrame - pastFrame);

	//mix the two colors according to the difference
	vec3 color = mix(color1, color2, diff);
	gl_FragColor = vec4(color, 1.0);
}