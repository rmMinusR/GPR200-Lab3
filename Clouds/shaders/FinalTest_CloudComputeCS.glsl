#version 430

layout (local_size_x = 1, local_size_y = 1) in;

#extension GL_GOOGLE_include_directive : enable
#include "common.glsl"

struct CloudParticle {
	vec3  startPos;
	float lifetime;
	vec3  currentPos;
	float size;
	vec3  color;
	float padding1;
	vec3 padding2;
	float padding3;
};

layout (std430, binding = 0) buffer CloudBufferType {
	CloudParticle particles[];
} CloudBuffer;

uniform float deltaTime;
uniform float time;

#define velocity 5

vec3 noise3(ivec3 sample_pos, int seed) {
    return vec3(
        noise(sample_pos, seed ^ 0x968a94),
        noise(sample_pos, seed ^ 0x448a7a),
        noise(sample_pos, seed ^ 0x3271f2)
    );
}

void main() {
	CloudParticle currentParticle = CloudBuffer.particles[gl_GlobalInvocationID.x];
	if (currentParticle.lifetime <= 0) {
		currentParticle.startPos = bellcurve(vec3(0, 0, 0), vec3(5, 2, 10), 10, vec3(0, 0, 0), int(gl_GlobalInvocationID.x));
		currentParticle.lifetime = noise(ivec3(time), int(gl_GlobalInvocationID.x)) * 11 + 20;
		currentParticle.size = noise(ivec3(time), int(gl_GlobalInvocationID.x)) * 5 + 1;
		currentParticle.currentPos = currentParticle.startPos;
		currentParticle.color = vec3(noise(ivec3(time), int(gl_GlobalInvocationID.x)) * 0.1) * 0.1;
	}
	else {
		currentParticle.currentPos += vec3(velocity, 0, 0) * deltaTime;
		currentParticle.lifetime -= deltaTime;
	}
	CloudBuffer.particles[gl_GlobalInvocationID.x] = currentParticle;
}