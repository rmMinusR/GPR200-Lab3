#version 330

uniform vec2 viewportDims;

uniform sampler2D particleTexture;

in float z;
in vec2 uv;
in float temperature;

out vec4 fragColor;
out float fragDepth;

#extension GL_GOOGLE_include_directive : enable
#include "common/dither.glsl"

void main() {
	vec2 nc = uv*2-1;
	
	vec4 s = texture(particleTexture, uv);
	
	fragColor.r = s.r * temperature;
	fragColor.a = s.a;
}