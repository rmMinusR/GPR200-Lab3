#ifndef HG_BLUR
#define HG_BLUR

/*

Blur algorithm

Written by Sean Sawyers-Abbott and Robert Christensen

*/

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

#endif