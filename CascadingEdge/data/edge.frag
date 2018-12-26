
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

/*
** Levels/Gamma control adapted from Romain Dura.
** 
** Copyright (c) 2012, Romain Dura romain@shazbits.com
** 
** Permission to use, copy, modify, and/or distribute this software for any 
** purpose with or without fee is hereby granted, provided that the above 
** copyright notice and this permission notice appear in all copies.
**
** Gamma correction
** Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
**
** Levels control (input (+gamma), output)
** Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
*/

#define GammaCorrection(color, gamma)							pow(color, vec3(1.0 / gamma))
#define LevelsControlInputRange(color, minInput, maxInput)		min(max(color - vec3(minInput), vec3(0.0)) / (vec3(maxInput) - vec3(minInput)), vec3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)	GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput) 	mix(vec3(minOutput), vec3(maxOutput), color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput) 	LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

// Sobel Edge Detection Filter
// https://en.wikipedia.org/wiki/Sobel_operator

uniform int u_mode;		// 0 = luma, 1 = r, 2 = g, 3 = b, 4 = rgb
uniform float u_intensity;
uniform float u_blackness;
uniform float u_gamma;
uniform int u_alpha;

uniform sampler2D texture;
uniform vec2 resolution;

float luma(vec3 rgb)
{
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    return dot(rgb, W);
}

void make_kernel(inout vec4 n[9], sampler2D tex, vec2 coord, float width, float height)
{
	float w = 1.0 / width;
	float h = 1.0 / height;

	n[0] = texture2D(tex, coord + vec2( -w, -h));
	n[1] = texture2D(tex, coord + vec2(0.0, -h));
	n[2] = texture2D(tex, coord + vec2(  w, -h));
	n[3] = texture2D(tex, coord + vec2( -w, 0.0));
	n[4] = texture2D(tex, coord);
	n[5] = texture2D(tex, coord + vec2(  w, 0.0));
	n[6] = texture2D(tex, coord + vec2( -w, h));
	n[7] = texture2D(tex, coord + vec2(0.0, h));
	n[8] = texture2D(tex, coord + vec2(  w, h));
}

void main(void) 
{
	vec2 st = gl_FragCoord.xy / resolution.xy;
	// st.y = 1. - st.y;

	vec4 n[9];
	make_kernel( n, texture, st, resolution.x, resolution.y );

	vec4 sobel_edge_h = n[2] + (u_intensity*n[5]) + n[8] - (n[0] + (u_intensity*n[3]) + n[6]);
  	vec4 sobel_edge_v = n[0] + (u_intensity*n[1]) + n[2] - (n[6] + (u_intensity*n[7]) + n[8]);
	vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));

	vec4 color = texture(texture, st);
	vec3 rgb = vec3(0., 0., 0.);

	switch (u_mode) {
		case 0:
			rgb = vec3( luma(sobel.rgb) );
			break;
		case 1:
			rgb = vec3( sobel.r );
			break;
		case 2:
			rgb = vec3( sobel.g );
			break;
		case 3:
			rgb = vec3( sobel.b );
			break;
		case 4:
			rgb = sobel.rgb;
			break;
	}

	switch (u_alpha) {
		case 0:
			color = vec4(LevelsControlOutputRange(rgb.rgb, 0., 1./u_blackness), 1);
			break;
		case 1:
			color += vec4(LevelsControl(rgb.rgb, 0., u_gamma, u_blackness, 0., 1.), luma(rgb.rgb)*2.);
			break;
		case 2:
			color = vec4(LevelsControl(rgb.rgb, 0., u_gamma, u_blackness, 0., 1.), luma(rgb.rgb)*1.);
			break;
	}
	

	gl_FragColor = color;
}
