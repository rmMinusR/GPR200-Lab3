// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // samples the image
    sCoord uv = fragCoord / iChannelResolution[0].xy;
    vec4 newColor = texture(iChannel0, uv);
    // multiplies each rgb color by itself 5 times
    newColor = pow(newColor, vec4(5.0));
    fragColor = newColor;
}