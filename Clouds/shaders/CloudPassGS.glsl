#version 430

// struct for taking in the necessary information
in Vertex {
	vec3 color;
	float size;
} vertex[];

out vec2 uv;
out vec3 color;

layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

void main() {
	color = vertex[0].color;
	uv = vec2(0, 0);
	gl_Position = gl_in[0].gl_Position;
	EmitVertex();
	
	uv = vec2(1, 0);
	gl_Position = gl_in[0].gl_Position + vec4(vertex[0].size, 0, 0, 0);
	EmitVertex();
	
	uv = vec2(0, 1);
	gl_Position = gl_in[0].gl_Position + vec4(0, vertex[0].size, 0, 0);
	EmitVertex();
	
	uv = vec2(1, 1);
	gl_Position = gl_in[0].gl_Position + vec4(vertex[0].size, vertex[0].size, 0, 0);
	EmitVertex();
	
	EndPrimitive();
}