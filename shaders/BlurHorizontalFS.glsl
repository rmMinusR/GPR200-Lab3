#version 330

uniform sampler2D blurInput;

in vec2 screenPosUV;
in vec2 screenPosNDC;

out vec4 fragColor;

void main() {
	fragColor = texture(blurInput, screenPosUV);
}