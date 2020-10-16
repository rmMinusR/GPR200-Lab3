/*

Modified Buffer A
Uses Accumulation Buffer instead of raw mouse position. This
lets us get "pan"-like mouse usage instead of the view resetting.

SETUP:
 - iChannel0: Cubemap to view
 - iChannel1: Accumulation Buffer

*/

//------------------------------------------------------------
// RENDERING FUNCTIONS

// calcColor: calculate the color of current pixel
//	  vp:  input viewport info
//	  ray: input ray info
color4 calcColor(in sViewport vp, in sRay ray)
{
    vec2 view_angle = texture(iChannel1, vec2(0, 0.5)).xy;
    
    // finds the ray's position on the cubemap
    sVector pitch = rotateX(ray.direction, (view_angle.y-0.5) * PI);
    sVector rotation = rotateY(pitch, view_angle.x * PI * 2.0);
    // sample cube map
    return texture(iChannel0, rotation.xyz);
}


//------------------------------------------------------------
// SHADERTOY MAIN

// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage(out color4 fragColor, in sCoord fragCoord)
{
    // viewing plane (viewport) inputs
    const sBasis eyePosition = sBasis(0.0);
    const sScalar viewportHeight = 2.0, focalLength = 1.5;
    
    // viewport info
    sViewport vp;

    // ray
    sRay ray;
    
    // render
    initViewport(vp, viewportHeight, focalLength, fragCoord, iResolution.xy);
    initRayPersp(ray, eyePosition, vp.viewportPoint.xyz);
    fragColor += calcColor(vp, ray);
}