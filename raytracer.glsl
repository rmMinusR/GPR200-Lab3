/**
 * GPU raycaster
 * Copyright Robert Christensen and Dan Buckstein
 * No license - all rights reserved
 */

// BEGIN ASSIGNMENT BOILERPLATE
// These snippets were copy-pasted from the assignment main page


// calcViewport: calculate the viewing plane (viewport) coordinate
//    viewport:       output viewing plane coordinate
//    ndc:            output normalized device coordinate
//    uv:             output screen-space coordinate
//    aspect:         output aspect ratio of screen
//    resolutionInv:  output reciprocal of resolution
//    viewportHeight: input height of viewing plane
//    fragCoord:      input coordinate of current fragment (in pixels)
//    resolution:     input resolution of screen (in pixels)
void calcViewport(out vec2 viewport, out vec2 ndc, out vec2 uv,
                  out float aspect, out vec2 resolutionInv,
                  in float viewportHeight, in vec2 fragCoord, in vec2 resolution)
{
    // inverse (reciprocal) resolution = 1 / resolution
    resolutionInv = 1.0 / resolution;
    
    // aspect ratio = screen width / screen height
    aspect = resolution.x * resolutionInv.y;

    // uv = screen-space coordinate = [0, 1) = coord / resolution
    uv = fragCoord * resolutionInv;

    // ndc = normalized device coordinate = [-1, +1) = uv*2 - 1
    ndc = uv * 2.0 - 1.0;

    // viewport: x = [-aspect*h/2, +aspect*h/2), y = [-h/2, +h/2)
    viewport = ndc * (vec2(aspect, 1.0) * (viewportHeight * 0.5));
}


// calcRay: calculate the ray direction and origin for the current pixel
//    rayDirection: output direction of ray from origin
//    rayOrigin:    output origin point of ray
//    viewport:     input viewing plane coordinate (use above function to calculate)
//    focalLength:  input distance to viewing plane
void calcRay(out vec4 rayDirection, out vec4 rayOrigin,
             in vec2 viewport, in float focalLength)
{
    // ray origin relative to viewer is the origin
    // w = 1 because it represents a point; can ignore when using
    rayOrigin = vec4(0.0, 0.0, 0.0, 1.0);

    // ray direction relative to origin is based on viewing plane coordinate
    // w = 0 because it represents a direction; can ignore when using
    rayDirection = vec4(viewport.x, viewport.y, -focalLength, 0.0);
}


// END ASSIGNMENT BOILERPLATE


// calcColor: calculate the color of a pixel given a ray
//    rayDirection: input ray direction
//    rayOrigin:    input ray origin
vec4 calcColor(in vec4 rayDirection, in vec4 rayOrigin)
{
    // DUMMY RESULT: OUTPUT RAY DIRECTION AS-IS
    // -> what does the ray look like as color?
    return rayDirection;
}


// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // viewing plane (viewport) info
    vec2 viewport, ndc, uv, resolutionInv;
    float aspect;
    const float viewportHeight = 2.0, focalLength = 1.0;

    // ray
    vec4 rayDirection, rayOrigin;

    // setup
    calcViewport(viewport, ndc, uv, aspect, resolutionInv,
                 viewportHeight, fragCoord, iResolution.xy);
    calcRay(rayDirection, rayOrigin,
            viewport, focalLength);

    // color
    fragColor = calcColor(rayDirection, rayOrigin);

    // TEST COLOR:
    //  -> what do the other things calculated above look like?
    //fragColor = vec4(viewport, 0.0, 0.0);
    //fragColor = vec4(ndc, 0.0, 0.0);
    //fragColor = vec4(uv, 0.0, 0.0);
}