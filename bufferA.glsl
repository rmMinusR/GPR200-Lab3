// CAMERA PARAMETERS

const float viewportHeight = 2.0;
const float focalLength = 1.0;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // viewing plane (viewport) info
    vec2 viewport, px_size, ndc, uv, resolutionInv;
    float aspect;
    
    // setup
    calcViewport(viewport, px_size, ndc, uv, aspect, resolutionInv,
                 viewportHeight, fragCoord, iResolution.xy);
    
    // make ray for fragment
    Ray ray;
    calcRay(ray, viewport, focalLength,
            texelFetch(iChannel0, camRotPos, 0).xy, texelFetch(iChannel0, camPos, 0).xyz);
    
    March march = cam_march(ray);
    //fragColor.r = march.distanceMarched / 4.;
    //fragColor.g = float(march.iterations) / float(MARCH_MAX_STEPS);
    //fragColor.b = float(march.closestApproach)*5.;
    fragColor = march.color;
}