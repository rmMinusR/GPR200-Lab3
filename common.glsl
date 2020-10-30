const int INT_MAX = 0xFFFFFFFF;
const float FLOAT_MAX = float(INT_MAX); // FIXME

const int MARCH_MAX_STEPS = 64;
const float MARCH_MAX_DIST = 128.;
const float MARCH_HIT_THRESHOLD = 0.00001;

// codes for A, W, D, and S keys respectively
const int LEFT = 65;
const int UP = 87;
const int RIGHT = 68;
const int DOWN = 83;

const vec2 mouseSens = vec2(0.004, -0.004);
const vec2 moveSens = vec2(0.1);

// coordinates to store each piece of data
const ivec2 camPos = ivec2(0,0);
const ivec2 mousePos = ivec2(1,0);
const ivec2 camRotPos = ivec2(2,0);

const float PI = 3.1415926535;
const float DEG2RAD = PI/180.;

#define this _this

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

//Float range remap. Now no longer an eeevil macro thanks to preprocessor!	
#define GEN_DECLARE(genType) genType fmap(in genType v, in genType lo1, in genType hi1, in genType lo2, in genType hi2) { return (v-lo1)/(hi1-lo1)*(hi2-lo2)+lo2; }	
GEN_DECLARE(float)	
GEN_DECLARE(vec2)	
GEN_DECLARE(vec3)	
GEN_DECLARE(vec4)	
#undef GEN_DECLARE

//Square
#define GEN_DECLARE(genType) genType sq(in genType v) { return v*v; }
GEN_DECLARE(int  ) GEN_DECLARE(ivec2) GEN_DECLARE(ivec3) GEN_DECLARE(ivec4)
GEN_DECLARE(float) GEN_DECLARE( vec2) GEN_DECLARE( vec3) GEN_DECLARE( vec4)
#undef GEN_DECLARE
    
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
void calcRay(out Ray ray, in vec2 viewport, in float focalLength,
             in vec2 camRot, in vec3 camPos)
{
    // ray origin relative to viewer is the origin
    // w = 1 because it represents a point; can ignore when using
    ray.origin = vec4(camPos, 1.0);

    // ray direction relative to origin is based on viewing plane coordinate
    // w = 0 because it represents a direction; can ignore when using
    ray.direction = vec4(viewport.x, viewport.y, -focalLength, 0.0);
    
    mat3 xRot = mat3(vec3(1, 0, 0),
                     vec3(0, cos(camRot.x), -sin(camRot.x)),
                     vec3(0, sin(camRot.x),  cos(camRot.x)));
    
    mat3 yRot = mat3(vec3(cos(camRot.y), 0, sin(camRot.y)),
                     vec3(0, 1, 0),
                     vec3(-sin(camRot.y), 0, cos(camRot.y)));
    
    ray.direction.xyz = yRot * xRot * ray.direction.xyz;
}

// END LAB 3 BOILERPLATE


// BEGIN LAB 4 BOILERPLATE
// These snippets were copy-pasted from the assignment main page

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


// BEGIN LIGHTS

struct PointLight {
    vec4 pos;
    vec4 color; //W/A used as intensity
};

PointLight mk_PointLight(in vec4 center, in vec3 color, in float intensity) {
    PointLight val;
    val.pos = as_point(center.xyz);
    val.color.rgb = color;
    val.color.a = abs(intensity);
    return val;
}

float attenuation_coeff(in float d, in float intensity) {
    return 1./sq(d/intensity+1.);
}

// BEGIN LAMBERTIAN MODEL

//BOTH INPUTS MUST BE NORMALIZED
float lambert_diffuse_coeff(in vec4 light_ray_dir, in vec4 normal) {
    return dot(normal, light_ray_dir);
}

float lambert_diffuse_intensity(in PointLight light, in vec4 pos, in vec4 nrm) {
    vec4 light_vector = normalize(light.pos-pos);
    return lambert_diffuse_coeff(light_vector, nrm) * attenuation_coeff(length(light_vector), light.color.a);
}

vec4 lambert_light(in PointLight light, in vec4 color, in vec4 pos, in vec4 nrm) {
    return vec4( lambert_diffuse_intensity(light, pos, nrm) * color.rgb * light.color.rgb, color.a);
}

// END LAMBERTIAN MODEL

// END LIGHTS


// BEGIN OBJECTS

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

float signedDistance(in Sphere this, vec4 position) {
    return length(this.center-position)-this.radius;
}

//Get the *outer* normal of the given sphere.
//Inner normal isn't necessary because inner faces are culled.
vec4 normal(in Sphere this, in vec4 glob_pos) {
    //return normalize(global_pos-this.center);
    //return (global_pos-this.center)/this.radius;
    float offset = 0.01;
    vec4 xDir = vec4(offset, 0., 0., 0.);
    vec4 yDir = vec4(0., offset, 0., 0.);
    vec4 zDir = vec4(0., 0., offset, 0.);
    return vec4(normalize(vec3(signedDistance(this, glob_pos+xDir)-signedDistance(this, glob_pos-xDir),
		                       signedDistance(this, glob_pos+yDir)-signedDistance(this, glob_pos-yDir),
		                       signedDistance(this, glob_pos+zDir)-signedDistance(this, glob_pos-zDir))), 0.);
}

vec4 color(in Sphere this, in March march) {
    return vec4( march.normal.rgb*0.5+0.5, 1. );
}

// END SPHERE

// END OBJECTS


// BEGIN RAYMARCHER

March mk_March(in Ray ray) { March val; val.position = ray; val.closestApproach = MARCH_MAX_DIST; return val; }

float march_step(inout March march, in Sphere sphere) {
    float d = signedDistance(sphere, march.position.origin);
    march.position.origin += d*march.position.direction;
    march.distanceMarched += d;
    march.closestApproach = min(march.closestApproach, d);
    return d;
}

March cam_march(in Ray ray) {
    March march = mk_March(ray);
    //MARCH CURRENT VALUES: position
    
    Sphere s = mk_Sphere(vec4(0,0,-1.5,1),1.);
    PointLight l = mk_PointLight(vec4(0.5,0.5,0,1), vec3(1), 16.);
    
    float d = FLOAT_MAX; // temp var
    bool hit, nohit;
    do {
        d = march_step(march, s);
        
        ++march.iterations;
        
        nohit = march.distanceMarched > MARCH_MAX_DIST || march.iterations > MARCH_MAX_STEPS;
        hit = d < MARCH_HIT_THRESHOLD;
    } while(!hit && !nohit);
    
    if(hit) {
        //MARCH CURRENT VALUES: position, distanceMarched, iterations, closestApproach

        march.normal = normal(s, march.position.origin);
        march.color = color(s, march);

        //MARCH FULLY POPULATED

        //Do lighting (mixed so it isn't entirely black in shadow)
        march.color = mix(march.color, lambert_light(l, march.color, march.position.origin, march.normal), 0.8);
    } else {
        march.normal = -march.position.direction;
        march.color = vec4(0,0,0,1);
    }
    
    //Haloing
    float halo = float(march.iterations)/float(MARCH_MAX_STEPS) - 0.1/max(march.closestApproach,1.);
    //halo *= halo;
    //halo = pow(halo, 1.5);
    march.color += vec4(1) * halo;
    
    return march;
}
// END RAYMARCHER