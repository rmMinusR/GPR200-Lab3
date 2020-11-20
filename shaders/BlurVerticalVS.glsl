/*

Basic ScreenQuad passthrough

Written by Robert Christensen

*/

#version 330

layout (location = 0) in vec4 pos;
layout (location = 1) in vec2 uv;

out vec2 screenPosUV;

void main() {
	gl_Position = pos; //Assign vertex position, so it actually renders
	screenPosUV = uv;  //Pass UV to fragment shader
}