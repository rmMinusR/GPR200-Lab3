#version 430

uniform sampler2D nonClouds;
uniform sampler2D depths;

uniform vec2 vpSize;

out vec4 finalFragColor;

void main() {
	vec2 uv = gl_FragCoord.xy/vpSize;
	
	float entryDist = texture(depths, uv).g;
	float exitDist =  min(texture(depths, uv).r, texture(depths, uv).b);
	
	finalFragColor.rgb = mix(
		texture(nonClouds, uv).rgb,
		vec3(0.5),
		clamp(exitDist-entryDist, 0, 1)
	);
	finalFragColor.a = 1;
}