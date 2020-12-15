#version 430

uniform sampler2D values;
uniform sampler2D colorRamp;

uniform float range;
uniform float curving;

in vec2 uv;

out vec4 fragColor;

void main() { //Fire texture to color using colorRamp texture
	float temp = texture(values, uv).r;
	fragColor = texture(colorRamp, vec2(pow(temp/range, curving), 0));
}