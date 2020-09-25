/**
 * GPU raycaster
 * Copyright Robert Christensen and Dan Buckstein
 * No license - all rights reserved
 */

// OBJECT PARAMETERS


#define SPHERE_RADIUS 1.
#define SPHERE_CENTER vec3(0,0,2.5)
#define SS_COUNT 4

// BEGIN UTILITY FUNCTIONS

//Evil macro. Don't put functions into it (except for x)
//Has to be a macro because genTypes don't exist
#define fmap(v, lo1, hi1, lo2, hi2) ( (v-lo1)*(hi1-lo1)*(hi2-lo2)+lo2 )

//Strip the integer part, return only the decimal part.
float getDecimalPart(in float x) {
    return x>0.?
        x-float(int(x)):
    	x-float(int(x))+1.;
}

//Project a ray by T
vec3 ray_project(in vec3 rayOrigin, in vec3 rayDirection, in float t) {
    return rayOrigin+rayDirection*t;
}

//Length squared helper function
float lenSq(in vec3 v) { return dot(v,v); }

//Square
float sq(in float v) { return v*v; }
int   sq(in int   v) { return v*v; }

// END UTLILITY FUNCTIONS


// BEGIN ASSIGNMENT BOILERPLATE
// These snippets were copy-pasted from the assignment main page
// calcViewport() modified by RC for SSAA


// calcViewport: calculate the viewing plane (viewport) coordinate
//    viewport:       output viewing plane coordinate
//RC: px_size:        output size of each pixel, for SSAA calculations, in viewport coordinates
//    ndc:            output normalized device coordinate
//    uv:             output screen-space coordinate
//    aspect:         output aspect ratio of screen
//    resolutionInv:  output reciprocal of resolution
//    viewportHeight: input height of viewing plane
//    fragCoord:      input coordinate of current fragment (in pixels)
//    resolution:     input resolution of screen (in pixels)
void calcViewport(out vec2 viewport, out vec2 px_size, out vec2 ndc, out vec2 uv,
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
    vec2 rhsCoeff = vec2(aspect, 1.0) * (viewportHeight * 0.5);
    viewport = ndc * rhsCoeff;
    px_size = resolutionInv * 2. * rhsCoeff; //Derived from UV and NDC
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


// calcBGColor: calculate the background color of a pixel given a ray
//    rayDirection: input ray direction
//    rayOrigin:    input ray origin
vec4 calcBGColor(in vec3 rayDirection, in vec3 rayOrigin)
{
    return mix(vec4(0,0.8,1,1), vec4(0,0,0.8,1), clamp(rayDirection.y/2.+0.5, 0., 1.));
}


// END ASSIGNMENT BOILERPLATE


// BEGIN SPHERE


float sphere_hit(in vec3 rayOrigin, in vec3 rayDirection,
                 in vec3 sphereCenter, in float sphereRadius) {
    vec3 relpos = rayOrigin-sphereCenter;
	
	float      a = lenSq(rayDirection);
	float half_b = dot(relpos, rayDirection);
	float      c = lenSq(relpos) - sq(sphereRadius);
	
    float disc = sq(half_b) - a*c;
    
    if(disc < 0.) return -1.;
    else {
        return abs( (-half_b+sqrt(disc))/a );
    }
}

vec3 sphere_normal(in vec3 gPos,
                   in vec3 sphereCenter, in float sphereRadius) {
    return normalize(gPos-sphereCenter);
}

vec4 sphere_color(in vec3 rayOrigin, in vec3 rayDirection,
                  in vec3 sphereCenter, in float sphereRadius,
                  in float cachedT) {
    vec3 hit_gpos = ray_project(rayOrigin, rayDirection, cachedT);
    vec3 nrm = sphere_normal(hit_gpos, sphereCenter, sphereRadius);
    
    //Backface culling
    if(dot(rayDirection, nrm) < 0.) return vec4(0,0,0,0);
    
    vec4 col = vec4( vec3(.5,.5,1)+nrm*3., 1 );
    
    return col;
}

vec4 raytrace_sphere(in vec3 rayOrigin, in vec3 rayDirection,
                     in vec3 sphereCenter, in float sphereRadius) {
	float hitT = sphere_hit(rayOrigin, rayDirection, sphereCenter, sphereRadius);
    
    if(hitT >= 0.) return sphere_color(rayOrigin, rayDirection, sphereCenter, sphereRadius, hitT);
    else return vec4(0,0,0,0);
}


// END SPHERE


// BEGIN RAYTRACING


//Blend layers based on alpha
void rt_blend(in vec4 back, in vec4 front, out vec4 result) {
    result = vec4(mix(back, front, front.a).rgb, 1.-( (1.-back.a)*(1.-front.a) ) );
}

vec4 rt_sample_all(in vec3 rayOrigin, in vec3 rayDirection) {
    vec4 col_out = calcBGColor(rayDirection, rayOrigin);
    
    //Parametric sphere
    rt_blend(col_out, raytrace_sphere(rayOrigin, rayDirection, SPHERE_CENTER, SPHERE_RADIUS), col_out);
    
    return col_out;
}


// END RAYTRACING


// BEGIN SUPERSAMPLE ANTIALIASING


vec4 sample_pixel_ssaa(in vec2 viewport, in float focalLength, in vec2 px_size, in int ss_count) {
    float pixel_weight = 1./float(sq(ss_count));
    
    vec2 neg_corner = viewport-px_size/2.;
    vec2 pos_corner = viewport+px_size/2.;
    
    vec4 pixel_col = vec4(0,0,0,0);
    
    vec4 rayDirection, rayOrigin;
    for(ivec2 ss_ind = ivec2(0,0); ss_ind.x < ss_count; ++ss_ind.x) for(ss_ind.y = 0; ss_ind.y < ss_count; ++ss_ind.y) {
        //Create sample coordinates from viewport and subsample index
        vec2 sample_coord = mix(neg_corner, pos_corner, (vec2(ss_ind)+vec2(0.5,0.5))/float(ss_count) );
        
        //Ray constructed from those coordinates
        calcRay(rayDirection, rayOrigin, sample_coord, focalLength);
        
        //Sample all and add (weighted) to output
        pixel_col += rt_sample_all(rayOrigin.xyz, rayDirection.xyz);
    }
    
    return pixel_col*pixel_weight;
}


// END SUPERSAMPLE ANTIALIASING


// mainImage: process the current pixel (exactly one call per pixel)
//    fragColor: output final color for current pixel
//    fragCoord: input location of current pixel in image (in pixels)
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // viewing plane (viewport) info
    vec2 viewport, px_size, ndc, uv, resolutionInv;
    float aspect;
    const float viewportHeight = 2.0, focalLength = 1.0;

    // setup
    calcViewport(viewport, px_size, ndc, uv, aspect, resolutionInv,
                 viewportHeight, fragCoord, iResolution.xy);
    // color
    fragColor = sample_pixel_ssaa(viewport, focalLength, px_size, SS_COUNT);
}