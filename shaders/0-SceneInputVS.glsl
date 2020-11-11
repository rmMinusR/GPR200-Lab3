#version 330

uniform mat4 mModel;
uniform mat4 mView;
uniform mat4 mProj;

layout (location = 0) in vec4 pos;
layout (location = 1) in vec4 normal;

out vec4 vsPos;
out vec4 vsGlobalNormal;
out vec4 vsCamRelNormal;

void main() {
	vsCamRelNormal = mView * (vsGlobalNormal = mModel * vec4(normal.xyz, 0));
	gl_Position = mProj * mView * (vsPos = mModel * pos);
}