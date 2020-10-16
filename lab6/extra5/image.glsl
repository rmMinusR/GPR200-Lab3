/*

Extra 5: Image tab
Simple throughput to show either the rendered cubemap,
or the accumulation buffer (channel 0)

Setup:
 - iChannel0: either accumulation buffer, or cubemap renderer

*/

void mainImage(out color4 fragColor, in sCoord fragCoord)
{
    sCoord uv = fragCoord / iChannelResolution[0].xy;
    fragColor = texture(iChannel0, uv);
}