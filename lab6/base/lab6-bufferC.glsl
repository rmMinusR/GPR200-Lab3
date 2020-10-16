/*

Code by Sean Sawyers-Abbott and Robert Christensen

*/

// blurs the image horizontally
vec4 blurX(in vec2 fragCoord)
{
    float div;
    vec2 newCoord;
    vec4 sum;
    for (int i = -size; i < size; ++i)
    {
         float k = kernel[i + size]; // finds the weight for each pixel
         newCoord = vec2(fragCoord.x + float(i), fragCoord.y)
             / iChannelResolution[0].xy; // finds the needed pixel
         sum += k * texture(iChannel0, newCoord); // weights the pixel
         div += k; // increments count for finding average
    }
    return sum / div; // returns weighted average
}

// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = blurX(fragCoord);
}