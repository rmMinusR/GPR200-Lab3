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

uniform Light light0, light1, light2;

float sq(float v) { return v*v; }

float lambert(in vec4 lightVector, in vec4 normal, in Light light, in float d) {
	float diffuse_coeff = max(0., dot(normal, lightVector));
	float attenuated_intensity = 1./sq(d/light.intensity+1.);
	return diffuse_coeff * attenuated_intensity;
}

float phong(vec4 lightVector, vec4 viewVector, vec4 normal, in Light light) {
	vec4 reflectedLightVector = reflect(lightVector, normal);
	float ks = max(0., dot(viewVector, reflectedLightVector));
	return pow(ks, 2);
}

void main() {
	vec4 view_pos = vec4(mViewport[0].w, mViewport[1].w, mViewport[2].w, 1.);
	
	vec4 viewVector = normalize(view_pos-pos);
	vec4 lightVector0 = light0.position-pos;
	float distToLight0 = length(lightVector0);
	lightVector0 /= distToLight0;
	vec4 lightVector1 = light1.position-pos;
	float distToLight1 = length(lightVector1);
	lightVector1 /= distToLight1;
	vec4 lightVector2 = light2.position-pos;
	float distToLight2 = length(lightVector2);
	lightVector2 /= distToLight2;
	
	specIntensity     = light0.color * phong(lightVector0, viewVector, normal, light0);
	specIntensity    += light1.color * phong(lightVector1, viewVector, normal, light1);
	specIntensity    += light2.color * phong(lightVector2, viewVector, normal, light2);
	diffuseIntensity  = light0.color * lambert(lightVector0, normal, light0, distToLight0);
	diffuseIntensity += light1.color * lambert(lightVector1, normal, light1, distToLight1);
	diffuseIntensity += light2.color * lambert(lightVector2, normal, light2, distToLight2);
	
	vecUv = uv;
	
	gl_Position = mViewport * mModel * pos;
}