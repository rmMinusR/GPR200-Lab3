/*

Midterm: Fractal raymarcher
'Buffer B' tab by Robert Christensen

This shader is responsible for rendering the scene.

Channel setup:
 0: buffer B
 1: any cubemap for a background

*/

// CAMERA SETTINGS

const float viewportHeight = 2.0;
const float focalLength = 1.0;

// BEGIN RAYMARCHER

// March constructor
March mk_March(in Ray ray) { March val; val.position = ray; val.closestApproach = MARCH_MAX_DIST; return val; }

// Execute a single step of raymarching
float march_step(inout March march) {
    float d = signedDistance(march.position.origin);
    march.position.origin += d*march.position.direction;
    march.distanceMarched += d;
    march.closestApproach = min(march.closestApproach, d);
    return d;
}

// Perform a raymarch from the camera
March cam_march(in Ray ray) {
    March march = mk_March(ray);
    //MARCH'S POPULATED VALUES: position.direction
    
    PointLight l = mk_PointLight(vec4(0.5,0.5,0,1), vec3(1), 16.);
    
    //March until we hit something, or run out of tries. In other words, correctly set the position
    float d = MARCH_MAX_DIST; // temp var
    bool hit, nohit;
    do {
        d = march_step(march);
        ++march.iterations;
        
        //Exit condition: we didn't hit anything
        nohit = march.distanceMarched > MARCH_MAX_DIST || march.iterations > MARCH_MAX_STEPS;
        
        //Exit condition: we hit something
        hit = d < MARCH_HIT_THRESHOLD;
    } while(!hit && !nohit);
    
    //Apply color and shading
    if(hit) {
        //MARCH'S POPULATED VALUES: position, distanceMarched, iterations, closestApproach
		
        march.normal = normal(march.position.origin, normal_detail);
        march.color = color(march);

        //MARCH FULLY POPULATED
        
        //Apply lighting
        march.color = lambert_light(l, march.color, march.position.origin, march.normal);
    } else {
        //We didn't hit anything. Set to transparent so layer can be blended
        march.color = vec4(0,0,0,0);
    }
    
    //Halo effect
    //Helps emphasize surface details and edges in monotone "caves"
    float halo = float(march.iterations)/96. - 0.1/max(march.closestApproach,1.);
    halo = clamp(halo, 0., 1.);
    march.color.rgb += vec3(1) * halo;
    march.color.a = 1.-( (1.-march.color.a) * (1.-halo) );
    
    return march;
}

// END RAYMARCHER

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
            texelFetch(iChannel0, camRotInd, 0).xy, texelFetch(iChannel0, camPosInd, 0).xyz);
    
    //Required so steps are the right distance
    ray.direction = normalize(ray.direction);
    
    March march = cam_march(ray);
    
    alpha_blend(texture(iChannel1, ray.direction.xyz), clamp(march.color, 0., 1.), fragColor);
}