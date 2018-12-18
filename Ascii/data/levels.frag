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

#define GammaCorrection(color, gamma)                           pow(color, vec3(1.0 / gamma))
#define LevelsControlInputRange(color, minInput, maxInput)      min(max(color - vec3(minInput), vec3(0.0)) / (vec3(maxInput) - vec3(minInput)), vec3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)    GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput)   mix(vec3(minOutput), vec3(maxOutput), color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput)   LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

uniform sampler2D texture;
uniform vec2 resolution;
uniform float u_inLow;
uniform float u_gamma;
uniform float u_inHigh;
uniform float u_outLow;
uniform float u_outHigh;

void main(void) 
{
    vec2 st = gl_FragCoord.xy / resolution.xy;

    vec4 color = texture2D(texture, st);

    color = vec4(LevelsControl(color.rgb, u_inLow, u_gamma, u_inHigh, u_outLow, u_outHigh), 1.);

    gl_FragColor = color;
}
