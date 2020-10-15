// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float div;
    vec2 newCoord;
    vec4 sum;
    float kernel[5] = float[5](1., 4., 6., 4., 1.);
    
    for (int i = -2; i <= 2; i++)
    {
        for (int j = -2; j <= 2; j++)
        {
            float k = kernel[i + 2] * kernel[j + 2];
            newCoord = vec2(fragCoord.x + float(i), fragCoord.y + float(j))
                / iChannelResolution[0].xy;
            sum += k * texture(iChannel0, newCoord);
            div += k;
        }
    }
    
    sum /= div;
    
    fragColor = sum;
}