#version 330

#extension GL_GOOGLE_include_directive : enable
//#include </common.glsl>

#ifdef GL_ES
precision highp float;
#endif//GL_ES

uniform mat4 mViewport;
uniform mat4 mModel;

layout (location = 0) in vec4 pos;
layout (location = 1) in vec4 normal;

layout (location = 2) in vec2 uv;

out vec3 specIntensity;
out vec3 diffuseIntensity;
out vec2 vecUv;

struct Light {
	vec4 position;
	vec3 color;
	float intensity;
};

float sq(float v) { return v*v; }

float lambert(in vec4 lightVector, in vec4 normal, in Light light, in float d) {
	float diffuse_coeff = max(0., dot(normal, lightVector));
	float attenuated_intensity = 1./sq(d/light.intensity+1.);
	return diffuse_coeff * attenuated_intensity;
}

float phong(vec4 lightVector, vec4 viewVector, vec4 normal, in Light light) {
	vec4 reflectedLightVector = reflect(lightVector, normal);
	float ks = max(0., dot(viewVector, reflectedLightVector));
	return pow(ks, 4);
}

void main() {
	vec4 view_pos = vec4(mViewport[0].w, mViewport[1].w, mViewport[2].w, 1.);
	
	Light light;
	light.position = vec4(1, 2, 3, 1);
	light.color = vec3(1, 1, 1);
	light.intensity = 4.;
	
	vec4 viewVector = normalize(view_pos-pos);
	vec4 lightVector = light.position-pos;
	float distToLight = length(lightVector);
	lightVector /= distToLight;
	
	specIntensity    = light.color * phong(lightVector, viewVector, normal, light);
	diffuseIntensity = light.color * lambert(lightVector, normal, light, distToLight);
	
	vecUv = uv;
	
	gl_Position = mViewport * mModel * pos;
}