uniform sampler2D u_current;
uniform sampler2D u_past;

varying vec4 vertTexCoord;

void main(){
	//vec4 currentFrame = texture2D(u_current, vertTexCoord.st);
	vec4 currentFrame = texture2D(u_current, vec2(vertTexCoord.s, 1.0 - vertTexCoord.t));

	// make sure to flip the previous frame
	vec4 pastFrame = texture2D(u_past, vec2(vertTexCoord.s, 1.0 - vertTexCoord.t));
	//vec4 pastFrame = texture2D(u_past, vec2(vertTexCoord.s, vertTexCoord.t));
	
	// subtract the frames from each other
	gl_FragColor = vec4(abs(vec3(currentFrame.rgb-pastFrame.rgb )), 1.0);
}