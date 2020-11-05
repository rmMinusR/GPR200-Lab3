#version 330

#ifdef GL_ES
precision highp float;
#endif

uniform mat4 mViewport;

uniform sampler2D texDiff;
uniform sampler2D texSpec;

in vec3 specIntensity;
in vec3 diffuseIntensity;
in vec2 vecUv;

out vec4 fragColor;

void main() {
	vec3 diffuse_color = texture(texDiff, vecUv).rgb;
	vec3 spec_color = texture(texSpec, vecUv).rgb;
	fragColor = vec4(vec3(0) + ((diffuseIntensity * diffuse_color) + (specIntensity * spec_color)), 1);
}