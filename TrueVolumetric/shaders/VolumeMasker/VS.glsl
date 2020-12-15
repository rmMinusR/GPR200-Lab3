#version 430

uniform mat4 mModel;
uniform mat4 mViewProj;

layout (location = 0) in vec3 pos;

out vec4 global_pos;

void main() {
	gl_Position = mViewProj * (global_pos = mModel * vec4(pos, 1));
}