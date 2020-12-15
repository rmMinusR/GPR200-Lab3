#version 330

uniform mat4 mView;
uniform mat4 mModel;

uniform float time;

layout (location = 0) in vec4 local_pos;
layout (location = 1) in vec4 local_normal;

out Vertex {
	vec4 color;
	float size;
} vertex;

void main() {
	gl_Position = mModel * vec4(local_pos.xyz, 1);
	vertex.color = vec4(1);
	vertex.size = 0.07;
}