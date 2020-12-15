#version 430

uniform float lift;
uniform float drag;
uniform float speed;
uniform float thermalLoss;
uniform float burnRate;

uniform float updraftCohesion;

uniform float startingPositionRandomness;
uniform float startingVelocity;
uniform vec2 startingTemp; //Format: x = center, y = variation range
uniform vec2 startingMass; //Format: x = center, y = variation range

uniform float stopTemp;

uniform float deltaTime;
uniform float time;

layout (local_size_x = 1, local_size_y = 1) in;

#extension GL_GOOGLE_include_directive : enable
#include "common/fireparticle.glsl"

layout (std430, binding = 0) buffer particleBuffer { // inout
	FireParticle particles[];
} buf;

#include "common/noise2.glsl"
const int RAND_SEED = 0xcbc30a02;

void main() {
	uint clusterSize = gl_WorkGroupSize.x+gl_WorkGroupSize.y+gl_WorkGroupSize.z;
	uint clusterID = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y*clusterSize + gl_GlobalInvocationID.z*clusterSize*clusterSize;
	
	int srand = floatBitsToInt(gl_GlobalInvocationID.x)^floatBitsToInt(gl_GlobalInvocationID.y)<<2^floatBitsToInt(gl_GlobalInvocationID.z)<<4;
	
	//Quick alias
	//C++ equivalent: Particle& part = buf.particles[clusterID];
	#define part buf.particles[clusterID]
	
	if(part.temperature > stopTemp) {
		// Particle is alive, do normal logic
		
		//Position = velocity * time
		part.position += part.velocity * deltaTime;
		
		//Updraft cohesion: Push towards center
		float distanceToCenter = length(part.position.xz);
		part.position.xz -= part.position.xz * part.position.y * deltaTime * updraftCohesion;
		
		//Air resistance
		part.velocity *= pow(drag, deltaTime);
		//Lift effect
		part.velocity.y += lift * deltaTime * (0.7+part.temperature/startingTemp.x);
		//Random air fluctuations
		part.velocity.xz += speed * deltaTime * bellcurve(vec2(0), vec2(1), 2, part.position*vec3(5,1,5)+vec3(0, -time, 0), srand);
		
		//Lose temperature over time
		part.temperature *= pow(thermalLoss, deltaTime*(0.8+distanceToCenter));
		
		//part.mass -= startingMass.x*deltaTime*0.2;
		part.mass *= pow(burnRate, deltaTime);
		
	} else {
		// Particle is dead, reinitialize
		part.position.y = 0;
		
		//Position in circle (slightly expensive)
		float r = pow(noise(ivec3(7), srand), 0.75) * startingPositionRandomness;
		float theta = noise(ivec3(13), srand) * 6.28318;
		part.position.xz = vec2(sin(theta), cos(theta)) * r;
		
		//Position in square (disabled because it looks bad)
		//part.position.xz = bellcurve(vec2(0), vec2(startingPositionRandomness), 3, vec3(0,time,0), srand);
		
		//Velocity within squashed cube
		part.velocity.xyz = bellcurve(vec3(0), vec3(startingVelocity)*vec3(1,0.5,1), 3, vec3(0,time*0.5,0), srand+1);
		
		//Randomize mass and temperature using fractal noise
		part.mass        = bellcurve(startingMass.x, startingMass.y, 3, vec3(0,time,0), srand+2);
		part.temperature = bellcurve(startingTemp.x, startingTemp.y, 3, vec3(0,time,0), srand+3);
		
	}
}