#version 330

uniform sampler2D blurInput;

in vec2 screenPosUV;
in vec2 screenPosNDC;

out vec4 fragColor;

#extension GL_GOOGLE_include_directive : enable
#include "shaders/common.glsl"

void main() {
	fragColor = gaussianBlur(screenPosUV, kernel, vec2(0, 1)/textureSize(blurInput, 0));
}