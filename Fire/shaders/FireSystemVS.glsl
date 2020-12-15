#version 330

#extension GL_GOOGLE_include_directive : enable
#include "common/noise2.glsl"
#include "common/fireparticle.glsl"

uniform mat4 mView;
uniform mat4 mModel;

uniform float time;

//Inputs from buffer. Will NOT correspond to the values in input layout.
layout (location = 0) in vec3 position;
layout (location = 1) in float mass;
layout (location = 2) in vec3 velocity;
layout (location = 3) in float temperature;

out Vertex {
	float mass;
	vec3 velocity;
	float temperature;
} particle;

void main() {
	//Generate noise
	vec3 sp = position.xyz*vec3(1,0.2,1)+vec3(0, -time*0.015, 0)*24; //Sample pos for noise
	vec3 n = bellcurve(vec3(0), vec3(1, 0.3, 1), 3, sp, 0xcbc30a02); //Noise
	
	//Distance to center (squared)
	float distToCenterSq = dot(position.xyz, position.xyz);
	
	//Must remain global space for now; will transform to clipspace in GS
	gl_Position = mModel * vec4(position, 1);
	gl_Position.xyz += n*(1+distToCenterSq)*0.35; // Wavering effect
	gl_Position.w = 1;
	
	//Pass through particle properties
	particle.mass        = mass;
	particle.velocity    = velocity;
	particle.temperature = temperature;
}