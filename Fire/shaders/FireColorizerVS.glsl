#version 430

uniform mat4 mModel, mViewProj;
layout (location = 0) in vec4 pos;
layout (location = 1) in vec2 _uv;

out vec2 uv;

void main() {
	gl_Position = pos; //ScreenQuad; no transformation needed
	uv = _uv;
}