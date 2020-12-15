#version 430

uniform sampler2D values;

in vec2 uv;

out vec4 fragColor;

//Blur kernel is the 26th row of Pascal's Triangle
const int KERN_SIZE = 26;
const float[KERN_SIZE] blurKernel = float[KERN_SIZE](1, 25, 300, 2300, 12650, 53130, 177100, 480700, 1081575, 2042975, 3268760, 4457400, 5200300, 5200300, 4457400, 3268760, 2042975, 1081575, 480700, 177100, 53130, 12650, 2300, 300, 25, 1);

//#extension GL_GOOGLE_include_directive : enable
//#include "common/blur.glsl"

vec4 applyKernel(in vec2 current_pos, in float[KERN_SIZE] kernel, in vec2 direction, in sampler2D blurInput) {
	//Weighted average
	vec3 sum;
	float weight;
	
	#pragma loop_unroll //99% sure this works
	for(int i = 0; i < KERN_SIZE; ++i) { //PATCHED: Works fine with even-sized kernels
		//Weight for this sample
		float w = kernel[i];
		
		//Sample coordinates
		vec2 sample_pos = current_pos + direction * (i-KERN_SIZE/2);
		
		//Do weighted average things
		sum += texture(blurInput, sample_pos).rgb * w; // Take advantage of texture blending hardware, plus allow non-integer directions
		weight += abs(w); //Necessary if there are any negative weights
	}
	
	return vec4(sum/weight, 1);
}

void main() {
	fragColor = applyKernel(uv, blurKernel, vec2(0, 1/textureSize(values, 0).y), values);
}