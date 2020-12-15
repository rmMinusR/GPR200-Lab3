#ifndef HG_PACKING
#define HG_PACKING

float pack(in float arg0, in float arg1) {
	return uintBitsToFloat(packHalf2x16(vec2(arg0, arg1));
}

void unpack(in float packed, out float arg0, out float arg1) {
	vec2 v = unpackHalf2x16(floatBitsToUint(packed));
	arg0 = v.x;
	arg1 = v.y;
}

vec2 pack(in vec2 arg0, in vec2 arg1) { return vec2(pack(arg0.x,  arg1.x ), pack(arg0.y , arg1.y )); }
vec3 pack(in vec3 arg0, in vec3 arg1) { return vec3(pack(arg0.xy, arg1.xy), pack(arg0.z , arg1.z )); }
vec4 pack(in vec4 arg0, in vec4 arg1) { return vec4(pack(arg0.xy, arg1.xy), pack(arg0.zw, arg1.zw)); }

void unpack(in vec2 packed, out vec2 arg0, out vec2 arg1) { unpack(packed.x,  arg0.x,  arg1.x ); unpack(packed.y,  arg0.y , arg1.y ); }
void unpack(in vec3 packed, out vec3 arg0, out vec3 arg1) { unpack(packed.xy, arg0.xy, arg1.xy); unpack(packed.z,  arg0.z , arg1.z ); }
void unpack(in vec4 packed, out vec4 arg0, out vec4 arg1) { unpack(packed.xy, arg0.xy, arg1.xy); unpack(packed.zw, arg0.zw, arg1.zw); }

#endif