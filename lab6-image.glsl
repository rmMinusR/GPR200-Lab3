// GLSL STARTER CODE BY DANIEL S. BUCKSTEIN
//  -> IMAGE TAB (final)

// https://github.com/CesiumGS/cesium/blob/master/Source/Shaders/Builtin/Functions/luminance.glsl
// this function was modified from the link above
float luminance(vec3 rgb)
{
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    return dot(rgb, W);
}

// adds the two sampled textures
vec4 doAdd(in vec4 x, in vec4 y)
{
    return x + y;
}

// mixes the two sampled textures
vec4 doMix(in vec4 x, in vec4 y)
{
    return mix(x, y, 0.5);
}

// screens the two sampled textures
vec4 doScreen(in vec4 x, in vec4 y)
{
    return 1. - (1. - x) * (1. - y);
}

// overlays the two sampled textures
vec4 doOverlay(in vec4 x, in vec4 y)
{
    float lum = luminance(x.rgb);
    
    if (lum < 0.5)
    {
        return 2. * x * y;
    }
    else
    {
        return 1. - 2. * (1. - x) * (1. - y);
    }
}

// sharpens the image
vec4 sharpen(in vec2 fragCoord, sampler2D newSample)
{
    float newKern[9] = float[9](-0.5, -0.5, -0.5,
                                -0.5, 5.0, -0.5,
                                -0.5, -0.5, -0.5);
    float k;
    vec2 newCoord;
    vec4 sum;
    k = newKern[0];
    // finds each necessary pixel then weights them to sharpen the image
    newCoord = vec2(fragCoord.x - 1., fragCoord.y + 1.) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[1];
    newCoord = vec2(fragCoord.x, fragCoord.y + 1.) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[2];
    newCoord = vec2(fragCoord.x + 1., fragCoord.y + 1.) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[3];
    newCoord = vec2(fragCoord.x - 1., fragCoord.y) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[4];
    newCoord = vec2(fragCoord.x, fragCoord.y) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[5];
    newCoord = vec2(fragCoord.x + 1., fragCoord.y) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[6];
    newCoord = vec2(fragCoord.x - 1., fragCoord.y - 1.) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[7];
    newCoord = vec2(fragCoord.x, fragCoord.y - 1.) / iResolution.xy;
    sum += k * texture(newSample, newCoord);
    k = newKern[8];
    newCoord = vec2(fragCoord.x + 1., fragCoord.y - 1.) / iResolution.xy;
    return sum + k * texture(newSample, newCoord);
}

//------------------------------------------------------------
// SHADERTOY MAIN

// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage(out color4 fragColor, in sCoord fragCoord)
{
    sCoord uv = fragCoord / iChannelResolution[0].xy;
    
    // samples the textures from each of the channels
    vec4 chan0 = texture(iChannel0, uv);
    vec4 chan1 = texture(iChannel1, uv);
    
    fragColor = doMix(chan0, chan1);
    
    //fragColor = sharpen(fragCoord, iChannel1);
}