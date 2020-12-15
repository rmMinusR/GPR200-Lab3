#version 430

uniform mat4 mModel;
uniform mat4 mViewProj;

layout (triangles) in;
layout (triangle_strip, max_vertices=4) out;

in Vertex {
	vec4 local_pos;
} verts[];

out float z;

void main() {
	vec4 glp = gl_Position = mViewProj * mModel * verts[0].local_pos;
	z = glp.z;
	EmitVertex();
	
	glp = gl_Position = mViewProj * mModel * verts[1].local_pos;
	z = glp.z;
	EmitVertex();
	
	glp = gl_Position = mViewProj * mModel * verts[2].local_pos;
	z = glp.z;
	EmitVertex();
	
	EndPrimitive();
}