#version 330

uniform mat4 mViewport;

uniform sampler2D texDiff;
uniform sampler2D texSpec;

in vec4 vertPos;
in vec4 vertNormal;
in vec2 vertUV;

out vec4 fragColor;

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

float phong(in vec4 viewVector, in vec4 reflectedLightVector) {
	float ks = max(0., dot(viewVector, reflectedLightVector));
	return pow(ks, 128);
}

vec3 doLighting(vec4 view_pos, vec4 pos, vec4 normal, in vec3 diffuseColor, in vec3 specularColor, in Light light) {
	vec4 viewVector = normalize(view_pos-pos);
	vec4 lightVector = light.position-pos;
	float lightDist = length(lightVector);
	lightVector /= lightDist;
	vec4 reflectedLightVector = reflect(lightVector, normal);
	
	float diffuseIntensity = lambert(lightVector, normal, light, lightDist);
	float specularIntensity = phong(viewVector, reflectedLightVector);
	
	specularIntensity = step(0.5, specularIntensity);
	diffuseIntensity = step(0.5, diffuseIntensity) * 0.9 + 0.1;
	
	return (diffuseIntensity * diffuseColor + specularIntensity * specularColor) * light.color;
}

void main() {
	vec4 vp_pos = vec4(mViewport[0].w, mViewport[1].w, mViewport[2].w, 1.);
	
	vec3 diffuse_color = texture(texDiff, vertUV).rgb;
	vec3 spec_color =    texture(texSpec, vertUV).rgb;
	vec4 n_vertNormal = normalize(vertNormal);
	
	fragColor = vec4(doLighting(vp_pos, vertPos, n_vertNormal, diffuse_color, spec_color, light0)
					+doLighting(vp_pos, vertPos, n_vertNormal, diffuse_color, spec_color, light1)
					+doLighting(vp_pos, vertPos, n_vertNormal, diffuse_color, spec_color, light2), 1);
}