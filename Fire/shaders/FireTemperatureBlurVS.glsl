#version 430

layout (location = 0) in vec4 pos;
layout (location = 1) in vec2 _uv;

out vec2 uv;

void main() {
	gl_Position = pos; //ScreenQuad; no matrix multiplication needed
	uv = _uv;
}