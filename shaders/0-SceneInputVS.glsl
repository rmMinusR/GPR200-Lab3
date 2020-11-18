#version 330

layout (location = 0) in vec4 pos;

out vec2 screenPosUV;
out vec2 screenPosNDC;

void main() {
	screenPosNDC = (gl_Position = pos).xy;
	screenPosUV = gl_Position.xy * 0.5 + 0.5;
}