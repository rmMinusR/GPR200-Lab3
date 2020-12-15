#version 430

in vec2 uv;
in vec3 color;
out vec4 fragColor;

uniform sampler2D texture1;

void main() {
	vec4 tex = texture(texture1, uv);
	fragColor.rgb = tex.rgb * color * tex.a;
	fragColor.a = 1;
}