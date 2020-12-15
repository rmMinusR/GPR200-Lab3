#ifndef HG_NOISE2
#define HG_NOISE2

#include "common/noise.glsl"

const float bellcurveOctaveScaling = 1/1.61803399; // 1 over golden ratio
const float bellcurveOctaveWeight = 1.2;

float fractalGaussian(in vec3 arg0, in int arg1, in float arg2, in float arg3, in int seed) {
	return fractalNoise(arg0, arg1, arg2, arg3, seed) * 2 - 1;
}

float bellcurve(in float center, in float variation, in int sharpness, in vec3 coord, in int seed) {
	return center + variation * fractalGaussian(coord, sharpness, bellcurveOctaveScaling, bellcurveOctaveWeight, seed);
}

vec2 bellcurve(in vec2 center, in vec2 variation, in int sharpness, in vec3 coord, in int seed) {
	return vec2(
		bellcurve(center.x, variation.x, sharpness, coord, seed^0x968a94),
		bellcurve(center.y, variation.y, sharpness, coord, seed^0x448a7a)
	);
}

vec3 bellcurve(in vec3 center, in vec3 variation, in int sharpness, in vec3 coord, in int seed) {
	return vec3(
		bellcurve(center.xy, variation.xy, sharpness, coord, seed),
		bellcurve(center. z, variation. z, sharpness, coord, seed^0x3271f2)
	);
}

#endif