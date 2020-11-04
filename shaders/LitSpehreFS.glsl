#version 330

uniform mat4 mViewport;

in vec4 vertColor;
in vec4 vertPos;
in vec4 vertNormal;

out vec4 fragColor;

struct Light {
	vec4 position;
	vec3 color;
	float intensity;
};

float sq(float v) { return v*v; }

vec3 lambert(in vec4 lightVector, in vec4 normal, in vec3 diffuse_color, in Light light, in float d) {
	float diffuse_coeff = max(0., dot(normal, lightVector));
	float attenuated_intensity = 1./sq(d/light.intensity+1.);
	float diffuse_intensity = diffuse_coeff * attenuated_intensity;
	
	return diffuse_coeff*diffuse_color*light.color;
}

vec3 phong(vec4 view_pos, vec4 pos, vec4 normal, vec3 diffuse_color, vec3 spec_color, in Light light) {
	vec4 viewVector = normalize(view_pos-pos);
	vec4 lightVector = light.position-pos;
	float lightVecLength = length(lightVector);
	lightVector /= lightVecLength;
	vec4 reflectedLightVector = reflect(-lightVector, normal);
	
	float ks = max(0., dot(viewVector, reflectedLightVector));
	
	float spec_intensity = pow(ks, 4);
	
	vec3 lambert_reflect = lambert(lightVector, normal, diffuse_color, light, lightVecLength);
	
	return vec3(0) + (lambert_reflect + spec_intensity*spec_color) * light.color;
}

void main() {
	vec4 vp_pos = vec4(mViewport[0].w, mViewport[1].w, mViewport[2].w, 1.);
	
	Light light;
	light.position = vec4(1, 2, 3, 1);
	light.color = vec3(0, 0.5, 1);
	light.intensity = 4.;
	
	vec3 diffuse_color = vec3(1);
	vec3 spec_color = vec3(1);
	
	fragColor = vec4( phong(vp_pos, vertPos, vertNormal, diffuse_color, spec_color, light), 1);
}