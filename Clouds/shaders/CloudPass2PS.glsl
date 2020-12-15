#version 430

uniform vec2 viewPortSize;
uniform sampler2D tex;

out vec4 fragColor;

void main() {
	fragColor = texture(tex, gl_FragCoord.xy/viewPortSize);
	fragColor.rg = gl_FragCoord.xy/viewPortSize;
	fragColor.a = 1;
}