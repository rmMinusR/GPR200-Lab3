#version 330

uniform sampler2D tOriginal;
uniform sampler2D tBlurred;

in vec2 screenPosUV;

out vec4 fragColor;

void main() {
	//Sample source textures
	vec3 original = texture(tOriginal, screenPosUV).rgb;
	vec3 blurred = texture(tBlurred, screenPosUV).rgb;
	
	//Screen blend mode
	fragColor.rgb = 1-(1-original)*(1-blurred);
	fragColor.a = 1;
}