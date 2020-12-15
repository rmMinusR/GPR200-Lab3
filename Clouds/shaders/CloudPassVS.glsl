#version 430

uniform mat4 mModel, mViewPos;

layout (location = 0) in vec3  startPos;
layout (location = 1) in float lifetime;
layout (location = 2) in vec3  currentPos;
layout (location = 3) in float size;
layout (location = 4) in vec3  color;

out Vertex {
	vec3 color;
	float size;
} vertex;

void main() {
	vertex.color = color;
	vertex.size = size;
	gl_Position = mViewPos * mModel * vec4(currentPos, 1);
}