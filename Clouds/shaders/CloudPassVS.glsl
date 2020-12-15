#version 430

// struct for outputting the necessary information
out Vertex {
	vec3 color;
	float size;
} vertex;

// gets the necessary information about the particle
layout (location = 2) in vec3  currentPos;
layout (location = 3) in float size;
layout (location = 4) in vec3  color;

uniform mat4 mModel, mViewPos;

void main() {
	vertex.color = color; // sets the color
	vertex.size = size; // sets the size
	gl_Position = mViewPos * mModel * vec4(currentPos, 1);
}