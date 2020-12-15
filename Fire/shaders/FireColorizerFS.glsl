#version 430

uniform sampler2D values;
uniform sampler2D colorRamp;

uniform float range;
uniform float curving;

in vec2 uv;

out vec4 fragColor;

void main() {
	vec4 s = texture(values, uv);
	fragColor = texture(colorRamp, vec2(pow(s.r/range, curving), 0));
	gl_FragDepth = s.g;
}