#ifndef HG_RAND
#define HG_RAND

//Heavily modified Krubbles' pseudorandom, see post on GDN:
//https://discordapp.com/channels/280521930371760138/280523185819222016/756170068496220242
int random3D(in uint x, in uint y, in uint z, in uint seed) {
    //Fix white artifacting at x=0, y=0, seed=0 by wrapping a certain region
    //Terrible practice but they'll never know...
    x    = x    | uint(0xf000000);
    y    = y    | uint(0xf000000);
    z    = z    | uint(0xf000000);
    seed = seed | uint(0xf000000);
    
    uint random = x*(y^seed) + y*(z^seed) + z*(x^seed);
    random ^= seed;
    random *= x * y * z;
    random ^= random >> 11;
    random ^= random << 5;
    random ^= random >> 3;
    return int(random);
}
//Wrapper
int random3D(in int x, in int y, in int z, in int seed) {
    return random3D(uint(x), uint(y), uint(z), uint(seed));
}
//Introduce further entropy and scale it to 0..1
float noise(in ivec3 pos, in int seed) {
    float r = float(random3D(pos.x, pos.y, pos.z, seed));
    return fract(r/float(2<<12) + r/float(2<<16));
}

//Pick and choose values
ivec3 pnc(in ivec3 a, in ivec3 b, in bool x, in bool y, in bool z) { return ivec3(x?b.x:a.x, y?b.y:a.y, z?b.z:a.z); }

//Antialias of noise()
float aaNoise(in vec3 pos, in int seed) {
    //Decimal Part
    vec3 dp = fract(pos);
    
    //Lower and upper corners
    ivec3 lb = ivec3(round(pos.x-dp.x), round(pos.y-dp.y), round(pos.z-dp.z));
    ivec3 hb = lb + ivec3(1,1,1);
    
    return mix(
        mix(
            mix( noise(pnc(lb, hb, false, false, false), seed), noise(pnc(lb, hb, true, false, false), seed), dp.x ),
            mix( noise(pnc(lb, hb, false,  true, false), seed), noise(pnc(lb, hb, true,  true, false), seed), dp.x ),
            dp.y
        ),
        mix(
            mix( noise(pnc(lb, hb, false, false, true), seed), noise(pnc(lb, hb, true, false, true), seed), dp.x ),
            mix( noise(pnc(lb, hb, false,  true, true), seed), noise(pnc(lb, hb, true,  true, true), seed), dp.x ),
            dp.y
        ),
        dp.z
    );
}

#endif

#ifndef HG_NOISE
#define HG_NOISE

//Eww more loops.
//Generates a fibonacci number pair such that pair.x > pair.y > pair.z
vec3 fibonacci2(in int n) {
    vec3 val = vec3(2,1,1);
    
    for(int i = 0; i < n; i++) {
        float sum = val.x + val.y;
        val.z = val.y;
        val.y = val.x;
        val.x = sum;
    }
    
    return val;
}

//XYZ based on the fibonacci sequence.
//Used to translate noise layers and hide artifacts
vec3 fibonacci_offset(in int n) {
    vec3 v = fibonacci2(n);
    
    return vec3(
        (n&1)!=0? v.x : -v.x,
        (n&2)!=0? v.y : -v.y,
        (n&4)!=0? v.z : -v.z
    );
}

//It loops. Gross!
//Also it's artifact-prone. Oh well.
float fractalNoise(in vec3 pos, in int octaves, in float octaveScaling, in float octaveWeight, in int seed) {
    float f = 0.;
    float octavicSum = 0.;
    
    for(int i = 0; i < octaves; i++) {
        //f += aaNoise( pow(octaveScaling, float(i))*pos ) * pow(octaveWeight, float(octaves-i+1)) * (1.-octaveWeight);
        float layer = aaNoise( pow(octaveScaling, float(i))*pos + fibonacci_offset(i), seed);
        f +=  layer * pow(octaveWeight, float(i));
        octavicSum += pow(octaveWeight, float(i));
    }
    
    return f/octavicSum;
}

#endif

#ifndef HG_NOISE2
#define HG_NOISE2

const float bellcurveOctaveScaling = 1/1.61803399; // 1 over golden ratio
const float bellcurveOctaveWeight = 1.2;

float fractalGaussian(in vec3 arg0, in int arg1, in float arg2, in float arg3, in int seed) {
	return fractalNoise(arg0, arg1, arg2, arg3, seed) * 2 - 1;
}

float bellcurve(in float center, in float variation, in int sharpness, in vec3 coord, in int seed) {
	return center + variation * fractalGaussian(coord, sharpness, bellcurveOctaveScaling, bellcurveOctaveWeight, seed);
}

vec2 bellcurve(in vec2 center, in vec2 variation, in int sharpness, in vec3 coord, in int seed) {
	return vec2(
		bellcurve(center.x, variation.x, sharpness, coord, seed^0x968a94),
		bellcurve(center.y, variation.y, sharpness, coord, seed^0x448a7a)
	);
}

vec3 bellcurve(in vec3 center, in vec3 variation, in int sharpness, in vec3 coord, in int seed) {
	return vec3(
		bellcurve(center.xy, variation.xy, sharpness, coord, seed),
		bellcurve(center. z, variation. z, sharpness, coord, seed^0x3271f2)
	);
}

#endif