#version 460

layout (points) in;
layout (triangle_strip) out;
layout (max_vertices = 4) out;

uniform mat4 mView;
uniform mat4 mViewProj;
uniform mat4 mModel;

in Vertex {
	vec4 color;
	float size;
} vertex[];

out vec2 uv;
out vec4 color;

void main() {
	vec4 right = vec4(mView[0][0], mView[1][0], mView[2][0], 0) * vertex[0].size;
	vec4 up    = vec4(mView[0][1], mView[1][1], mView[2][1], 0) * vertex[0].size;
	
	vec4 particle_pos = gl_in[0].gl_Position;
	
	gl_Position = mViewProj * (particle_pos - right + up);
	color = vertex[0].color;
	uv = vec2(0, 1);
	EmitVertex();
	
	gl_Position = mViewProj * (particle_pos - right - up);
	color = vertex[0].color;
	uv = vec2(0, 0);
	EmitVertex();
	
	gl_Position = mViewProj * (particle_pos + right + up);
	color = vertex[0].color;
	uv = vec2(1, 1);
	EmitVertex();
	
	gl_Position = mViewProj * (particle_pos + right - up);
	color = vertex[0].color;
	uv = vec2(1, 0);
	EmitVertex();
	
	EndPrimitive();
}