#version 430

uniform sampler2D values;

in vec2 uv;

out vec4 fragColor;

//Blur kernel is the 26th row of Pascal's Triangle
const int KERN_SIZE = 26;
const float[KERN_SIZE] blurKernel = float[KERN_SIZE](1, 25, 300, 2300, 12650, 53130, 177100, 480700, 1081575, 2042975, 3268760, 4457400, 5200300, 5200300, 4457400, 3268760, 2042975, 1081575, 480700, 177100, 53130, 12650, 2300, 300, 25, 1);

#extension GL_GOOGLE_include_directive : enable
#include "common/blur.glsl"

void main() {
	//Could be done more efficiently with an X pass and a Y pass separate, but that's another pipeline stage because I haven't figured out instancing
	fragColor = (
		applyKernel(uv, blurKernel, vec2(1/textureSize(values, 0).x, 0), values),
	  + applyKernel(uv, blurKernel, vec2(0, 1/textureSize(values, 0).y), values)
	);
}