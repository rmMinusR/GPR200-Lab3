#ifndef HG_NOISE
#define HG_NOISE

#include "common/random.glsl"

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