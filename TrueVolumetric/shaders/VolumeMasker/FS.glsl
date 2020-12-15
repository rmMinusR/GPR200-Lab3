#version 430

uniform mat4 mModel;
uniform mat4 mView;
uniform mat4 mViewProj;
uniform sampler2D pDepth;

uniform vec2 vpSize;

in vec4 global_pos;
out vec4 depth;

//This function is Sebastian Lague's work, ported/adapted from HLSL to GLSL.
// Returns (dstToBox, dstInsideBox). If ray misses box, dstInsideBox will be zero
vec2 rayBoxDst(vec3 boundsMin, vec3 boundsMax, vec3 rayOrigin, vec3 rayDirection) {
	//Cube = 6 planes
	//q = o + t*d
	//(q-o)/d = t
	vec3 invRaydir = 1/rayDirection;
    // Adapted from: http://jcgt.org/published/0007/03/04/
    vec3 t0 = (boundsMin - rayOrigin) * invRaydir;
    vec3 t1 = (boundsMax - rayOrigin) * invRaydir;
    vec3 tmin = min(t0, t1);
    vec3 tmax = max(t0, t1);
    
    float dstA = max(max(tmin.x, tmin.y), tmin.z);
    float dstB = min(tmax.x, min(tmax.y, tmax.z));

    // CASE 1: ray intersects box from outside (0 <= dstA <= dstB)
    // dstA is dst to nearest intersection, dstB dst to far intersection

    // CASE 2: ray intersects box from inside (dstA < 0 < dstB)
    // dstA is the dst to intersection behind the ray, dstB is dst to forward intersection

    // CASE 3: ray misses box (dstA > dstB)

    float dstToBox = max(0, dstA);
    float dstInsideBox = max(0, dstB - dstToBox);
    return vec2(dstToBox, dstInsideBox);
}

struct ray_t {
	vec4 origin;
	vec4 direction;
};

void main() {
	vec3 scale = vec3( mModel[0].x, mModel[1].y, mModel[2].z );
	
	ray_t viewray; //Global space viewing ray
	viewray.origin = inverse(mView) * vec4(0,0,0,1);
	viewray.direction.xyz = normalize(global_pos.xyz-viewray.origin.xyz);
	
	vec3 v = vec3(0.5);
	vec2 tmp = rayBoxDst((mModel*vec4(-v,1)).xyz, (mModel*vec4(v,1)).xyz, viewray.origin.xyz, viewray.direction.xyz);
	
	//Entry distance
	depth.g = tmp.x;
	
	//Exit distance
	depth.b = tmp.x+tmp.y;
}