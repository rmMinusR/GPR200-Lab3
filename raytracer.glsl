/**
 * GPU raycaster
 * Copyright Robert Christensen and Dan Buckstein
 * No license - all rights reserved
 */

// CAMERA PARAMETERS

const float viewportHeight = 2.0;
const float focalLength = 1.0;

const int SS_COUNT = 1;
//#define SS_COUNT int( getDecimalPart(iTime/3.) * 6. + 1. )

const float NEAR_PLANE = 0.1f;

// OBJECT PARAMETERS

const float SPHERE_RADIUS = 1.;
const vec4 SPHERE_CENTER = vec4(0, 0, -1.5, 1); //vec4(sin(iTime)/2., cos(iTime)/2., 2.5, 1)


// BEGIN UTILITY FUNCTIONS

//I want to be able to use the "this" keyword
#define this _this

//Float range remap. Now no longer an eeevil macro thanks to preprocessor!
#define GEN_DECLARE(genType) genType fmap(in genType v, in genType lo1, in genType hi1, in genType lo2, in genType hi2) { return (v-lo1)*(hi1-lo1)*(hi2-lo2)+lo2; }
GEN_DECLARE(float)
GEN_DECLARE(vec2)
GEN_DECLARE(vec3)
GEN_DECLARE(vec4)
#undef GEN_DECLARE

//Strip the integer part, return only the decimal part.
float getDecimalPart(in float x) {
    return x>0.?
        x-float(int(x)):
    	x-float(int(x))+1.;
}

//Length squared helper function
#define GEN_DECLARE(genType) float lenSq(in genType v) { return dot(v,v); }
GEN_DECLARE(vec2)
GEN_DECLARE(vec3)
GEN_DECLARE(vec4)
#undef GEN_DECLARE

//Square
float sq(in float v) { return v*v; }
int   sq(in int   v) { return v*v; }

// END UTLILITY FUNCTIONS


// BEGIN LAB 4 BOILERPLATE

// as_point: promote a 3D vector into a 4D vector representing a point (w=1)
//    point: input 3D vector to be converted into a point
vec4 as_point(in vec3 point)
{
    return vec4(point, 1.0);
}

// as_offset: promote a 3D vector into a 4D vector representing an offset (w=0)
//    offset: input 3D vector to be converted into an offset
vec4 as_direction(in vec3 offset)
{
    return vec4(offset, 0.0);
}

// END LAB 4 BOILERPLATE


// BEGIN RAY DATA STRUCTURE

struct Ray {
    vec4 origin;
    vec4 direction;
};

Ray mk_ray(in vec4 origin, in vec4 direction) {
    Ray v;
    v.origin = as_point(origin.xyz);
    v.direction = as_direction(direction.xyz);
    return v;
}

vec4 ray_at(in Ray this, in float t) {
    return as_point( this.origin.xyz + t*this.direction.xyz );
}

// END RAY DATA STRUCTURE


// BEGIN LAB 3 BOILERPLATE
// These snippets were copy-pasted from the assignment main page
// calcViewport() modified by RC for use in SSAA
// calcBGColor() modified by RC for data-structure syntax

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
//    ray:          output ray, origin-relative
//    viewport:     input viewing plane coordinate (use above function to calculate)
//    focalLength:  input distance to viewing plane
void calcRay(out Ray ray, in vec2 viewport, in float focalLength)
{
    // ray origin relative to viewer is the origin
    // w = 1 because it represents a point; can ignore when using
    ray.origin = vec4(0.0, 0.0, 0.0, 1.0);

    // ray direction relative to origin is based on viewing plane coordinate
    // w = 0 because it represents a direction; can ignore when using
    ray.direction = vec4(viewport.x, viewport.y, -focalLength, 0.0);
}

// calcBGColor: calculate the background color of a pixel given a ray
//    ray: input ray
vec4 calcBGColor(in Ray ray)
{
    return mix(vec4(0,0.8,1,1), vec4(0,0,0.8,1), clamp(ray.direction.y/2.+0.5, 0., 1.));
}

// END LAB 3 BOILERPLATE


/*

Raycastable objects must:

Have a named fully-encapsulating data structure with ctor:
 - MyRaycastable mk_MyRaycastable(...)

Implement the following method signatures:
 - float hit(in MyRaycastable this, in Ray ray) => returns T such that hit position is ray_at(T)
 - vec4 normal(in MyRaycastable this, in vec4 global_pos) => returns normalized direction vector perpendicular to the tangent at global_pos
 - vec4 color(in MyRaycastable this, in Ray ray, in float cachedT) => returns color of object for given ray
 - vec4 raytrace(in MyRaycastable this, in Ray ray) => returns color for given ray, or transparent if no hit

*/

//Helper macros that should be included in every raytrace()
#define BACKFACE_CULL if(dot(ray.direction, nrm) > 0.) return vec4(0,0,0,0);
#define NEARPLANE_CULL if(hit_gpos.z > -NEAR_PLANE) return vec4(0,0,0,0);

// BEGIN SPHERE

struct Sphere {
    vec4 center;
    float radius;
};

Sphere mk_Sphere(in vec4 center, in float radius) {
    Sphere s;
    if(radius > 0. && center.w == 1.) {
        s.center = center;
        s.radius = radius;
    } else {
        s.center = vec4(0,0,0,1);
        s.radius = 1.;
    }
    return s;
}

//Does given ray intersect given sphere? If so, at what t such that
//the global hit location will be ray::at(t)?
float hit(in Sphere this, in Ray ray) {
    vec4 relpos = ray.origin-this.center;
	
	float      a = lenSq(ray.direction);
	float half_b = dot(relpos, ray.direction);
	float      c = lenSq(relpos) - sq(this.radius);
	
    float disc = sq(half_b) - a*c;
    
    if(disc < 0.) return -1.;
    else {
        return abs( (-half_b-sqrt(disc))/a );
    }
}

//Get the *outer* normal of the given sphere.
//Inner normal isn't necessary because inner faces are culled.
vec4 normal(in Sphere this, in vec4 global_pos) {
    //return normalize(global_pos-this.center);
    return (global_pos-this.center)/this.radius;
}

//Get the color of the given sphere, for given ray.
//Uses cached t such that hit location is ray_at(ray, t)
vec4 color(in Sphere this, in Ray ray, in float cachedT) {
    //Pretty-universal variables
    vec4 hit_gpos = ray_at(ray, cachedT);
    vec4 nrm = normal(this, hit_gpos);
    
    BACKFACE_CULL;
    NEARPLANE_CULL;
    
    //Actual color logic (currently shows normal)
    vec4 col = vec4( vec3(.5,.5,.5)+nrm.xyz*0.7, 1 );
    
    return col;
}

//Raytrace onto a sphere. Calls sphere_hit and (if hit) sphere_color
vec4 raytrace(in Sphere this, in Ray ray) {
	float hitT = hit(this, ray);
    
    if(hitT >= 0.) return color(this, ray, hitT);
    else return vec4(0,0,0,0);
}

// END SPHERE


// BEGIN RAYTRACING

//Blend layers based on alpha
void alpha_blend(in vec4 back, in vec4 front, out vec4 result) {
    result = vec4( mix(back, front, front.a).rgb, 1.-( (1.-back.a)*(1.-front.a) ) );
}

//Sample ALL objects in the scene. If you want to add objects, write
//them in here. Note: there is no Z-testing, so render back-to-front
vec4 rt_sample_all(in Ray ray, in Ray rMouse) {
    vec4 col_out = calcBGColor(ray);
    
    //Parametric sphere
    Sphere sphere = mk_Sphere(SPHERE_CENTER, SPHERE_RADIUS);
    alpha_blend(col_out, raytrace(sphere, ray), col_out);
    
    //For debugging purposes
    float mouseT = hit(sphere, rMouse);
    
    return col_out;
}

// END RAYTRACING


// BEGIN SUPERSAMPLE ANTIALIASING

//Sample a pixel using SuperSampled AntiAliasing technique
//Peter Shirley uses random() calls, but we can't for performance
//reasons plus it doesn't exist predefined in GLSL
vec4 sample_pixel_ssaa(in vec2 viewport, in float focalLength, in vec2 px_size, in int ss_count, in vec2 vpMouse) {
    float pixel_weight = 1./float(sq(ss_count));
    
    vec2 neg_corner = viewport-px_size/2.;
    vec2 pos_corner = viewport+px_size/2.;
    
    vec4 pixel_col = vec4(0,0,0,0);
        
    //debug: mouse ray
    Ray mouseRay;
    calcRay(mouseRay, vpMouse, focalLength);
    
    Ray ray;
    for(ivec2 ss_ind = ivec2(0,0); ss_ind.x < ss_count; ++ss_ind.x) for(ss_ind.y = 0; ss_ind.y < ss_count; ++ss_ind.y) {
        //Create sample coordinates from viewport and subsample index
        vec2 sample_coord = mix(neg_corner, pos_corner, (vec2(ss_ind)+vec2(0.5,0.5))/float(ss_count) );
        
        //Ray constructed from those coordinates
        calcRay(ray, sample_coord, focalLength);
        
        //Sample all and add (weighted) to output
        pixel_col += rt_sample_all(ray, mouseRay);
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
	
    // debugging: mouse raycast (most values discarded)
    vec2 vpMouse;
    calcViewport(vpMouse, px_size, ndc, uv, aspect, resolutionInv,
                 viewportHeight, iMouse.xy, iResolution.xy);
    
    // setup
    calcViewport(viewport, px_size, ndc, uv, aspect, resolutionInv,
                 viewportHeight, fragCoord, iResolution.xy);
    
    // color
    fragColor = sample_pixel_ssaa(viewport, focalLength, px_size, SS_COUNT, vpMouse);
}