#version 430

layout (local_size_x = 1, local_size_y = 1) in;

#extension GL_GOOGLE_include_directive : enable
#include "common.glsl"

// creates the particle structure with the necessary
// variables for creating and rendering it
struct CloudParticle {
	vec3  startPos;
	float lifetime;
	vec3  currentPos;
	float size;
	vec3  color;
	float padding1; // these three padding variables serve to pad
	vec3 padding2;  // the space used in the buffer so that the row size
	float padding3; // is a power of space and no misalignments occur
};

layout (std430, binding = 0) buffer CloudBufferType {
	CloudParticle particles[];
} CloudBuffer;

// two variables for using time
uniform float deltaTime;
uniform float time;

// speed of each particle
#define velocity 5

void main() {
	CloudParticle currentParticle = CloudBuffer.particles[gl_GlobalInvocationID.x]; // gets the current particle
	if (currentParticle.lifetime <= 0) { // checks if the lifetime has been depleted
		currentParticle.startPos = bellcurve(vec3(0, 0, 0), vec3(5, 5, 10), 10, vec3(0, 0, 0), int(gl_GlobalInvocationID.x)) - vec3(75, 0, 0); // sets the new position of the particle randomly on a bell curve
		currentParticle.lifetime = noise(ivec3(time), int(gl_GlobalInvocationID.x)) * 11 + 20; // sets the new lifetime of the particle between 20-30 seconds
		currentParticle.size = noise(ivec3(time), int(gl_GlobalInvocationID.x)) * 5 + 1; // sets the new size of the particle between 5-6
		currentParticle.currentPos = currentParticle.startPos; // sets the current position of the particle to the new starting position
		currentParticle.color = vec3(noise(ivec3(time), int(gl_GlobalInvocationID.x)) * 0.05) * 0.1; // sets the particle color to a random gray
	}
	else {
		currentParticle.currentPos += vec3(velocity, 0, 0) * deltaTime; // moves the particle based on its velocity
		currentParticle.lifetime -= deltaTime; // decrements the lifetime
	}
	CloudBuffer.particles[gl_GlobalInvocationID.x] = currentParticle; // writes the changed values to the current particle
}