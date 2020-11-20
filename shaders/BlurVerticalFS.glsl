/*

"Half-blur" step

Written by Sean Sawyers-Abbott and Robert Christensen

*/

#version 330

uniform sampler2D blurInput;

in vec2 screenPosUV;

out vec4 fragColor;

#extension GL_GOOGLE_include_directive : enable
#include "common/blur.glsl"

void main() {
	//Perform gaussian blur (see blur.glsl)
	fragColor = applyKernel(screenPosUV, blurKernel, vec2(0, 1)/textureSize(blurInput, 0));
}