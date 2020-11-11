#version 330

uniform sampler2D brightPassInput;

in vec2 screenPosUV;
in vec2 screenPosNDC;

out vec4 fragColor;

void main() {
	fragColor = texture(brightPassInput, screenPosUV);
}