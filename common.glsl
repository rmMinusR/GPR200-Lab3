/*

Midterm: Fractal raymarcher
'Common' tab by Robert Christensen and Sean Sawyers-Abbott

Contents:
 - Parameters
 - Constants
 - Utils
 - Data structures
 - Lab 3 boilerplate
 - Lights
    - Lambertian model
 - Mandelbulb

*/

// BEGIN PARAMETERS

// Parameters for raymarching
const int MARCH_MAX_STEPS = 256;   // Maximum iteration cap. Must be something reasonable or WebGL will crash.
const float MARCH_MAX_DIST = 128.; // Distance for us to safely assume we haven't hit anything.
const float MARCH_HIT_THRESHOLD = 0.00001; // How close must we be to be considered a "hit"?

// Mouse and keyboard sensitivity for controlling the camera
const vec2 mouseSens = vec2(-0.01, 0.01);
const float moveSens = 0.001;

// Mandelbulb parameters

//#define power (1.+mod(iTime/8., 1.)*8.)
const float power = 10.;
const float normal_detail = 0.004;

// END PARAMETERS


// BEGIN CONSTANTS

// Coordinates where each piece of data is stored in accumulation buffer
const ivec2 camPosInd = ivec2(0,0);
const ivec2  mouseInd = ivec2(1,0);
const ivec2 camRotInd = ivec2(2,0);

// Math constants
const float PI = 3.1415926535;
const float DEG2RAD = PI/180.;

// Keycode constants for A, W, D, and S keys respectively
const int ESC = 0x1b;
const int SHIFT = 0x10;
const int LCTRL = 0x11;
const int SPACE = 0x20;
const int KEY_A = 0x41;
const int KEY_D = 0x44;
const int KEY_S = 0x53;
const int KEY_W = 0x57;

// END CONSTANTS


// BEGIN UTILS

// Square
#define GEN_DECLARE(genType) genType sq(in genType v) { return v*v; }
GEN_DECLARE(int  ) GEN_DECLARE(ivec2) GEN_DECLARE(ivec3) GEN_DECLARE(ivec4)
GEN_DECLARE(float) GEN_DECLARE( vec2) GEN_DECLARE( vec3) GEN_DECLARE( vec4)
#undef GEN_DECLARE

// "Un-reserve" the this keyword
#define this _this

// Blend layers based on transparency
void alpha_blend(in vec4 back, in vec4 front, out vec4 result) {
    result = vec4( mix(back, front, front.a).rgb, 1.-( (1.-back.a)*(1.-front.a) ) );
}

// END UTILS


// BEGIN DATA STRUCTURES

struct Ray {
    vec4 origin, direction;
};

struct March {
    //We need approach direction as well for light view_v -> halfway
    //(BP only) because camera will be moving
    Ray position;
    
    //Saves a normalize() call
    float distanceMarched;
    int iterations;
    
    //Traditional outputs
    vec4 normal;
    vec4 color;
    
    //Allows for halos and other cool effects
    //Ideally would be a double
    float closestApproach;
};

// END DATA STRUCTURES


// BEGIN LAB 3 BOILERPLATE
// These snippets were copy-pasted from the assignment main page
// calcViewport() modified by RC for use in SSAA (currently unused for performance reasons)
// calcRay() modified by SSA for camera transformation

// Calculate the coordinate on the viewing plane
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

// Build a ray for the current pixel
void calcRay(out Ray ray, in vec2 viewport, in float focalLength,
             in vec2 camRot, in vec3 camPos)
{
    // ray origin relative to viewer is the origin
    ray.origin = vec4(camPos, 1.0); //SSA: move camera

    // ray direction relative to origin is based on viewing plane coordinate
    ray.direction = vec4(viewport.x, viewport.y, -focalLength, 0.0);
    
    //SSA: rotate camera rays
    mat3 xRot = mat3(vec3(1, 0, 0),
                     vec3(0, cos(camRot.x), -sin(camRot.x)),
                     vec3(0, sin(camRot.x),  cos(camRot.x)));
    
    mat3 yRot = mat3(vec3(cos(camRot.y), 0, sin(camRot.y)),
                     vec3(0, 1, 0),
                     vec3(-sin(camRot.y), 0, cos(camRot.y)));
    
    ray.direction.xyz = yRot * xRot * ray.direction.xyz;
}

// END LAB 3 BOILERPLATE


// BEGIN LIGHTS

struct PointLight {
    vec4 pos;
    vec4 color; //W/A used as intensity
};

// Initialize a PointLight
PointLight mk_PointLight(in vec4 center, in vec3 color, in float intensity) {
    PointLight val;
    val.pos = vec4(center.xyz, 1.);
    val.color.rgb = color;
    val.color.a = intensity;
    return val;
}

// Attenuation coefficient
float attenuation_coeff(in float d, in float intensity) {
    return 1./sq(d/intensity+1.);
}

// BEGIN LAMBERTIAN MODEL

// Lambertian diffuse coefficient
// BOTH INPUTS MUST BE NORMALIZED
float lambert_diffuse_coeff(in vec4 light_ray_dir, in vec4 normal) {
    return dot(normal, light_ray_dir);
}

// Lambertian diffuse coefficient
float lambert_diffuse_intensity(in PointLight light, in vec4 pos, in vec4 nrm) {
    vec4 light_vector = light.pos-pos;
    float lv_len = length(light_vector);
    return lambert_diffuse_coeff(light_vector/lv_len, nrm) * attenuation_coeff(lv_len, light.color.a);
}

// Apply the Lambertian lighting model (only supports one light)
vec4 lambert_light(in PointLight light, in vec4 color, in vec4 pos, in vec4 nrm) {
    return vec4( lambert_diffuse_intensity(light, pos, nrm) * color.rgb * light.color.rgb, color.a);
}

// END LAMBERTIAN MODEL

// END LIGHTS

// BEGIN MANDELBULB

// Mandelbulb distance estimation. We vaguely understand it but it isn't our code--we just optimized it.
// http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
// Via: https://www.youtube.com/watch?v=Cp5WWtMoeKg
float signedDistance(in vec4 position) {
    vec3 z = position.xyz;
    float dr = 1.0;
    float r = 0.0;
    
    for (int i = 0; i < 15; ++i) {
        r = length(z);
		
        // Escape check
        if (r<=2.) {
            // convert to polar coordinates
            float theta = acos(z.z/r);
            float phi = atan(z.y,z.x);
            dr =  pow( r, power-1.0)*power*dr + 1.0;

            // scale and rotate the point
            float zr = pow( r,power);
            theta = theta*power;
            phi = phi*power;

            // convert back to cartesian coordinates
            z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
            z+=position.xyz;
        } else break;
    }
    
    return 0.5*log(r)*r/dr;
}

// Approximates the normal of the surface
// Offset should probably be dynamic based on view distance, otherwise the image will look noisy.
// Adapated from http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-ii-lighting-and-coloring/
vec4 normal(in vec4 glob_pos, in float offset) {
    vec4 xDir = vec4(offset, 0., 0., 0.);
    vec4 yDir = vec4(0., offset, 0., 0.);
    vec4 zDir = vec4(0., 0., offset, 0.);
    return vec4(normalize(vec3(signedDistance(glob_pos+xDir)-signedDistance(glob_pos-xDir),
		                       signedDistance(glob_pos+yDir)-signedDistance(glob_pos-yDir),
		                       signedDistance(glob_pos+zDir)-signedDistance(glob_pos-zDir))), 0.);
}

// Simple bit of coloring
// Makes more sense with this architecture than orbit trapping
vec4 color(in March march) {
    return vec4( march.normal.xyz*0.5+0.5, 1. );
}

// END MANDELBULB
