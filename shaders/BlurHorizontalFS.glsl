#version 330

uniform sampler2D blurInput;

in vec2 screenPosUV;

out vec4 fragColor;

#extension GL_GOOGLE_include_directive : enable
#include "common/blur.glsl"

void main() {
	//Perform gaussian blur (see blur.glsl)
	fragColor = applyKernel(screenPosUV, blurKernel, vec2(1, 0)/textureSize(blurInput, 0));
}