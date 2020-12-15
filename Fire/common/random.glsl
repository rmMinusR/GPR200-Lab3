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