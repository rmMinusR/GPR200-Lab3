#version 430

in vec2 uv;
in vec3 color;
out vec4 fragColor;

uniform sampler2D sampleTex;

void main() {
	vec4 tex = texture(sampleTex, uv); // samples the bound texture and coordinate
	fragColor.rgb = tex.rgb * color * tex.a;
}