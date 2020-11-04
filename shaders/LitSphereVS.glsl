#version 330

uniform mat4 mViewport;
uniform mat4 mModel;

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 normal;

out vec4 vertColor;

void main() {
	vertColor = vec4(0.5+0.5*normal, 1.);
	gl_Position = mViewport * mModel * vec4(pos, 1.);
}