#version 330

layout (points) in;
layout (triangle_strip) out;
layout (max_vertices = 4) out;

uniform mat4 mView;
uniform mat4 mViewProj;
uniform mat4 mModel;

in Vertex {
	float mass;
	vec3 velocity;
	float temperature;
} vertex[];

out vec2 uv;
out float temperature;

uniform float sizePerMass;

void main() {
	float size = vertex[0].mass * sizePerMass;
	
	//Camera-relative right and up vectors
	vec4 right = vec4(mView[0][0], mView[1][0], mView[2][0], 0) * size;
	vec4 up    = vec4(mView[0][1], mView[1][1], mView[2][1], 0) * size;
	
	vec4 particle_pos = gl_in[0].gl_Position;
	
	temperature = vertex[0].temperature;
	
	//Point to screen-facing square quad
	
	gl_Position = mViewProj * (particle_pos -right+up);
	uv = vec2(0, 1);
	EmitVertex();
	
	gl_Position = mViewProj * (particle_pos -right-up);
	uv = vec2(0, 0);
	EmitVertex();
	
	gl_Position = mViewProj * (particle_pos +right+up);
	uv = vec2(1, 1);
	EmitVertex();
	
	gl_Position = mViewProj * (particle_pos +right-up);
	uv = vec2(1, 0);
	EmitVertex();
	
	EndPrimitive();
}