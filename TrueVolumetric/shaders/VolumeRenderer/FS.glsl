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

//Solution thanks to BrunoLevy: https://stackoverflow.com/a/42634961
//Updated and adapted by me (Robert Christensen)
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
	return bellcurve(0, 1, 8, pos, 983723);
}

void volsample(in vec4 pos, out vec4 diffuse, out vec4 emission) {
	diffuse.rgb = vec3(1);
	//diffuse.rgb = vec3(bellcurve(0.8, 0.2, 6, pos.xyz, 83742));
	diffuse.a = max(density(pos.xyz*8), 0);
	emission = vec4(0);
}

const float T_STEP = 0.1;
const float MAX_STEPS = 192;
vec4 volmarch(ray_t ray, vec4 back, float entry, float exit) {
	vec4 outVal = back;
	
	int steps = 0;
	for(float t = entry; t <= exit && steps++ < MAX_STEPS; t += T_STEP) {
		vec4 diffuse, emission;
		volsample(ray_at(ray, t), diffuse, emission);
		//Contrast booster. Not recommended bc performance
		//diffuse.a = 1-pow(1-diffuse.a, T_STEP);
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