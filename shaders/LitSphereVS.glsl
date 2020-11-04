#version 330

#extension GL_GOOGLE_include_directive : enable
//#include </common.glsl>

#ifdef GL_ES
precision highp float;
#endif//GL_ES

uniform mat4 mViewport;
uniform mat4 mModel;

layout (location = 0) in vec4 pos;
layout (location = 1) in vec4 normal;

layout (location = 2) in vec2 uv;

out vec4 vertColor;
out vec4 vertPos;
out vec4 vertNormal;
out vec2 vertUV;

void main() {
	vertColor = vec4(0.5+0.5*normal.xyz, 1.);
	vertPos = mModel * pos;
	vertNormal = vec4((mModel * normal).xyz, 0); //Have to ensure w=0 because SHADERed sets it to 1
	vertUV = uv;
	gl_Position = mViewport * mModel * pos;
}