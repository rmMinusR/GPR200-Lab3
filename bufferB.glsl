// CAMERA PARAMETERS

const float viewportHeight = 2.0;
const float focalLength = 1.0;

#define clamp01(x) clamp(x, 0., 1.)

//Blend layers based on alpha
void alpha_blend(vec4 back, vec4 front, out vec4 result) {
    //Make params bounded
    back = clamp01(back);
    front = clamp01(front);
    
    float blend_weight = 1.-( (1.-back.a)*(1.-front.a) );
    
    result = vec4( mix(back, front, front.a).rgb, blend_weight );
}

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
    
    //Required so steps are the right distance
    ray.direction = normalize(ray.direction);
    
    March march = cam_march(ray);
    
    //fragColor.r = march.color.a;
    //fragColor.g = march.distanceMarched;
    alpha_blend(texture(iChannel1, ray.direction.xyz), clamp01(march.color), fragColor);
}