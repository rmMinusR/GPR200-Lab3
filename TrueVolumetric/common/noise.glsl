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

/*
//It loops. Gross!
//Also it's artifact-prone. Oh well.
float fractalNoise(in vec3 pos, in int octaves, in float octaveScaling, in float octaveWeight, in int seed) {
    float f = 0.;
    float octavicSum = 0.;
    
    for(int i = 0; i < octaves; i++) {
        float layer = aaNoise( ipow(octaveScaling, i)*pos + fibonacci_offset(i), seed);
        f +=  layer * ipow(octaveWeight, i);
        octavicSum += ipow(octaveWeight, i);
    }
    
    return f/octavicSum;
}
*/

//It loops. Gross!
//Also it's artifact-prone. Oh well.
float fractalNoise(in vec3 pos, in int octaves, in float octaveScaling, in float octaveWeight, in int seed) {
    float f = 0.;
    float octavicSum = 0.;
    
    float _ow = 1, _os = 1;
    vec3 fib = vec3(1, 1, 2);
    for(int i = 0; i < octaves; i++) {
        float layer = aaNoise( _os*pos + vec3((i&1)!=0?-fib.x:fib.x, (i&2)!=0?-fib.y:fib.y, (i&4)!=0?-fib.z:fib.z), seed);
        f +=  layer * _ow;
        octavicSum += _ow;
        
        _ow *= octaveWeight;
        _os *= octaveScaling;
        fib.xy = fib.yz; fib.z = fib.x+fib.y;
    }
    
    return f/octavicSum;
}

#endif