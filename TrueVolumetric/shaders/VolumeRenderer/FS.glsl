#version 430

uniform sampler2D nonClouds;
uniform sampler2D depths;
uniform sampler2D cachedHits;

uniform vec2 vpSize;
uniform mat4 mViewInv;

out vec4 finalFragColor;

uniform mat4 mViewProjInv;
uniform mat4 mModelInv;

vec4 alpha_mix(vec4 cfront, vec4 cback) { return vec4(cfront.rgb*cfront.a+cback.rgb*(1-cfront.a), 1-(1-cfront.a)*(1-cback.a)); }

//IMPORTS
#extension GL_GOOGLE_include_directive : enable
#include "common/noise2.glsl"

// BEGIN RAY

struct ray_t {
	vec4 origin;
	vec4 direction;
};

vec4 ray_at(ray_t _this, float t) { return _this.origin + t*_this.direction; }

ray_t glup_primary_ray() {
	float GLUP_viewport[4] = float[4](0, 0, vpSize.x, vpSize.y);
	mat4 GLUP_inverse_modelviewprojection_matrix = mModelInv * mViewProjInv;
	
    vec4 near = vec4(
    2.0 * ( (gl_FragCoord.x - GLUP_viewport[0]) / GLUP_viewport[2] - 0.5),
    2.0 * ( (gl_FragCoord.y - GLUP_viewport[1]) / GLUP_viewport[3] - 0.5),
        0.0,
        1.0
    );
    near = GLUP_inverse_modelviewprojection_matrix * near ;
    vec4 far = near + GLUP_inverse_modelviewprojection_matrix[2] ;
    near.xyz /= near.w ;
    far.xyz /= far.w ;
    //return ray_t(near.xyz, far.xyz-near.xyz) ;
    ray_t val;
    val.origin    = vec4(near.xyz, 0);
    val.direction = vec4(far.xyz-near.xyz, 1);
    return val;
}

// END RAY

// BEGIN RAYMARCHER

float density(in vec3 pos) {
	return bellcurve(0, 1, 4, pos, 983726458);
}

void volsample(in vec4 pos, out vec4 diffuse, out vec4 emission) {
	diffuse = vec4(1,1,1,max(density(pos.xyz*8), 0));
	emission = vec4(0);
}

const float T_STEP = 0.08;
vec4 volmarch(ray_t ray, vec4 back, float entry, float exit) {
	vec4 outVal = back;
	
	for(float t = entry; t <= exit; t += T_STEP) {
		vec4 diffuse, emission;
		volsample(ray_at(ray, t), diffuse, emission);
		diffuse.a *= T_STEP;
		
		outVal = alpha_mix(diffuse, outVal) + vec4(emission.rgb*emission.a, 0);
	}
	
	return outVal;
}

// END RAYMARCHER

void main() {
	vec2 uv = gl_FragCoord.xy/vpSize;
	
	float entryDist = texture(depths, uv).g;
	float exitDist = min(texture(depths, uv).r, texture(depths, uv).b);
	
	ray_t viewray = glup_primary_ray();
	viewray.direction = normalize(viewray.direction);
	
	finalFragColor = volmarch(viewray, texture(nonClouds, uv), entryDist, exitDist);
}