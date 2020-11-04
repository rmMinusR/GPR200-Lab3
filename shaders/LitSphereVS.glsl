#version 330

#extension GL_GOOGLE_include_directive : enable
//#include "test.glsl"

#ifdef GL_ES
precision highp float;
#endif//GL_ES

uniform mat4 mViewport;
uniform mat4 mModel;

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 normal;

layout (location = 2) in vec2 uv;

out vec4 vertColor;

void main() {
	vertColor = vec4(0.5+0.5*normal, 1.);
	gl_Position = mViewport * mModel * vec4(pos, 1.);
}