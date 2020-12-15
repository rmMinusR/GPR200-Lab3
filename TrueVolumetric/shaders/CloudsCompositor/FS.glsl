#version 430

uniform sampler2D nonClouds;
uniform sampler2D depths;

uniform vec2 vpSize;
uniform mat4 mViewInv;

out vec4 finalFragColor;

struct ray_t {
	vec4 origin;
	vec4 direction;
};

vec4 ray_at(ray_t _this, float t) {
	return _this.origin + t*_this.direction;
}

vec4 alpha_mix(vec4 cfront, vec4 cback) {
	return vec4(cfront.rgb*cfront.a+cback.rgb*(1-cfront.a), 1-(1-cfront.a)*(1-cback.a));
}

const float T_STEP = 0.05;

void volsample(in vec4 pos, out vec4 diffuse, out vec4 emission) {
	diffuse = vec4(0.5);
	emission = vec4(0);
}

vec4 volmarch(ray_t ray, vec4 back, float entry, float exit) {
	vec4 outVal = back;
	
	for(float t = entry; t < exit; t += T_STEP) {
		vec4 diffuse, emission;
		volsample(ray_at(ray, t), diffuse, emission);
		diffuse.a *= T_STEP;
		
		outVal = alpha_mix(diffuse, outVal) + vec4(emission.rgb*emission.a, 0);
	}
	
	return outVal;
}

void main() {
	vec2 uv = gl_FragCoord.xy/vpSize;
	
	float entryDist = texture(depths, uv).g;
	float exitDist = min(texture(depths, uv).r, texture(depths, uv).b);
	
	ray_t viewray; //Global space viewing ray
	viewray.origin = mViewInv * vec4(0,0,0,1);
	viewray.direction = normalize( (mViewInv * vec4(uv,-1,1)) - viewray.origin );
	
	finalFragColor = volmarch(viewray, texture(nonClouds, uv), entryDist, exitDist);
	
	/*
	finalFragColor.rgb = mix(
		texture(nonClouds, uv).rgb,
		vec3(0.5),
		clamp(exitDist-entryDist, 0, 1)
	);
	*/
	
	finalFragColor.a = 1;
}