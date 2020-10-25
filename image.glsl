void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 tmp = texelFetch(iChannel0, ivec2(fragCoord), 0);
    
    fragColor = tmp;
}