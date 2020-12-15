#version 330

uniform vec2 viewportDims;

uniform sampler2D particleTexture;

in vec2 uv;
in float temperature;

out vec4 fragColor;
out float fragDepth;

void main() {
	//Draw textured particle to quad
	vec4 s = texture(particleTexture, uv);
	fragColor.r = s.r * temperature;
	fragColor.a = s.a;
}