#version 330

uniform vec2 viewportDims;

uniform sampler2D particleTexture;

in vec2 uv;
in vec4 color;

out vec4 fragColor;

#extension GL_GOOGLE_include_directive : enable
#include "common/dither.glsl"

void main() {
	ivec2 viewportPixelCoord = ivec2(gl_FragCoord.xy);
	vec4 sampled = texture(particleTexture, uv);
	if(sampled.a > dither(viewportPixelCoord)) fragColor = sampled * color;
	else discard;
	fragColor.rg *= uv;
}