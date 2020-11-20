/*

Bright pass algorithm

Written by Sean Sawyers-Abbott and Robert Christensen

*/

#version 330

uniform sampler2D brightPassInput;

in vec2 screenPosUV;

out vec4 fragColor;

void main() {
	//Sample source texture
	vec4 colorIn = texture(brightPassInput, screenPosUV);
	
	//Perform bright pass
	vec4 colorInPow4 = colorIn * colorIn;
	colorInPow4 *= colorInPow4;
	
	fragColor = colorInPow4 * colorIn; //Equivalent to pow(colorIn, 5) but faster
}