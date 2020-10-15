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

//------------------------------------------------------------
// SHADERTOY MAIN

// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage(out color4 fragColor, in sCoord fragCoord)
{
    sCoord uv = fragCoord / iChannelResolution[0].xy;
    vec4 chan0 = texture(iChannel0, uv);
    vec4 chan1 = texture(iChannel1, uv);
    fragColor = doMix(chan0, chan1);
}