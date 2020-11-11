#version 330

in vec4 vsPos;
in vec4 vsGlobalNormal;
in vec4 vsCamRelNormal;

out vec4 fragColor;

void main() {
	fragColor = vsGlobalNormal;
}