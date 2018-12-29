
#version 150

#define SAMPLER0 sampler2D // sampler2D, sampler3D, samplerCube

uniform SAMPLER0 iChannel0;
uniform vec3  iResolution;


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 texel = 1. / iResolution.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 components = texture(iChannel0, uv).xyz;
    vec3 norm = normalize(components);
    fragColor = vec4(0.5 + norm.z);
}