/*

Midterm: Fractal raymarcher
'Image' tab

Just a passthrough. Existed for testing the contents of the accumulation buffer, but
it isn't necessary anymore. Set it up for buffer B.

Channel setup:
 0: buffer B

*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
}