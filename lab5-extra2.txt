/**
 * GPU raycaster
 * Copyright Robert Christensen and Dan Buckstein
 * No license - all rights reserved
 */

// CAMERA PARAMETERS

const float viewportHeight = 2.0;
const float focalLength = 1.0;

const int SS_COUNT = 4;
//#define SS_COUNT int( getDecimalPart(iTime/3.) * 6. + 1. )

const float NEAR_PLANE = 0.1f;


// LIGHT PARAMETERS

const vec3  AMBIENT_COLOR = vec3(1, 1, 1);
const float AMBIENT_INTENSITY = 0.1;

const int   HIGHLIGHT_EXP = 1 << 8;
const float HIGHLIGHT_OFFSET = 1.07;

const int MAX_LIGHTS = 2;

const float DEBUG_LIGHT_SPHERE_RADIUS = 0.02f;


// OBJECT PARAMETERS

const float SPHERE_RADIUS = 1.;
const vec4 SPHERE_CENTER = vec4(0, 0, -2.5, 1); //vec4(sin(iTime)/2., cos(iTime)/2., 2.5, 1)


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
#define GEN_DECLARE(genType) genType sq(in genType v) { return v*v; }
GEN_DECLARE(int  ) GEN_DECLARE(ivec2) GEN_DECLARE(ivec3) GEN_DECLARE(ivec4)
GEN_DECLARE(float) GEN_DECLARE( vec2) GEN_DECLARE( vec3) GEN_DECLARE( vec4)
#undef GEN_DECLARE

//Clamp between 0-1
#define GEN_DECLARE(genType) genType clamp01(in genType v) { return clamp(v, 0., 1.); }
GEN_DECLARE(float) GEN_DECLARE( vec2) GEN_DECLARE( vec3) GEN_DECLARE( vec4)
#undef GEN_DECLARE

//Integer-power. Significantly faster than pow(float, float)
/*
b^x =
b^(x_0+x_1+...+x_n) =
b^x_0 * b^x_1 * ... * b^x_n
All k in x_k are powers of two
*/
float ipow(float b, int x) {
    //Acts as a stack representing x, will be interpreted one bit at a time LSB first
    uint powstack = uint(x);
    
    //Will always be b raised to some power that is a power of two
    //(p^q)^2 = p^2q
    float p2 = b;
    
    //The output b^x_0 * ... * b^x_k
    float val = 1.;
    
    //Loop until we've reached the last bit (will always be most-significant)
    while(powstack != uint(0)) {
        //Pop a bit from remaining power stack
        bool poppedBit = (powstack&uint(1)) != uint(0);
        powstack = powstack >> 1;
        
        //Update output value
        if(poppedBit) val *= p2;
        
        //Powers of b raised to a power of two.
        //(p^q)^2 = p^2q
        //(p^2^k)^2 = p^(2*2^k) = p^2^(k+1)
        p2 *= p2;
    }
    
    return val;
}

//Blend layers based on alpha
void alpha_blend(in vec4 back, in vec4 front, out vec4 result) {
    result = vec4( mix(back, front, front.a).rgb, 1.-( (1.-back.a)*(1.-front.a) ) );
}

//Variant of atan that correctly interprets values where x,y<0
float atan2(in float y, in float x) {
    float base = atan(y/x);
    return (y>=0.)?base:(180.+base);
}

// END UTLILITY FUNCTIONS


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


// BEGIN RAY

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

// END RAY


// BEGIN RAYTRACE-HIT DATA STRUCTURE

/*

Raycastable objects must:

Have a named fully-encapsulating data structure with ctor:
 - MyRaycastable mk_MyRaycastable(...)

Implement the following method signatures:
 - float hit(in MyRaycastable this, in Ray ray) => returns T such that hit position is ray_at(T)
 - vec4 normal(in MyRaycastable this, in vec4 global_pos) => returns normalized direction vector perpendicular to the tangent at global_pos
 - vec4 raytrace(in MyRaycastable this, in Ray ray) => returns color for given ray, or transparent if no hit

*/

//Helper macros that should be included in every raytrace()
#define PREPARE_VARS(cachedT) rt_hit hit;\
    hit.pos = ray_at(ray, cachedT);\
    hit.nrm = normal(this, hit.pos);
#define BACKFACE_CULL if(dot(ray.direction, hit.nrm) > 0.) return rt_hit_none();
#define NEARPLANE_CULL if(hit.pos.z > -NEAR_PLANE) return rt_hit_none();

//Helper data structure
struct rt_hit {
    vec4 pos;
    vec4 nrm;
    vec4 color;
};

rt_hit rt_hit_none() { rt_hit val; return val; }

bool rt_hit_good(in rt_hit val) { return val.pos.z != 0.; }

//Combo of Z-test and alpha blend
//SHOULD ONLY BE USED IN rt_sample_all() or composition like raytrace(Multilight)
rt_hit z_blend(in rt_hit a, in rt_hit b) {
    if(!rt_hit_good(a)) return b;
    if(!rt_hit_good(b)) return a;
    
    rt_hit close, far;
    if(a.pos.z > b.pos.z) {
        close = a;
        far = b;
    } else {
        close = b;
        far = a;
    }
    
    rt_hit outv;
    outv.pos = close.pos;
    outv.nrm = close.nrm;
    alpha_blend(far.color, close.color, outv.color);
    
    return outv;
}

// END RAYTRACE-HIT DATA STRUCTURE


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

float lambert_diffuse_intensity(in PointLight light, in rt_hit hit) {
    vec4 light_vector = normalize(light.pos-hit.pos);
    return lambert_diffuse_coeff(light_vector, hit.nrm) * attenuation_coeff(length(light_vector), light.color.a);
}

void lambert_light(in PointLight light, inout rt_hit hit) {
    hit.color.rgb = lambert_diffuse_intensity(light, hit) * hit.color.rgb * light.color.rgb;
}

// END LAMBERTIAN MODEL

// BEGIN PHONG MODEL

float phong_spec_coeff(in PointLight light, in rt_hit hit) {
    vec4 view_vector = normalize(-hit.pos);
    vec4 light_vector = normalize(light.pos-hit.pos);
    //vec4 refl_light_vector = reflect(-light_vector, hit.nrm);
    vec4 halfway = vec4(normalize(view_vector+light_vector).xyz, 0);
    return dot(hit.nrm, halfway);
}

float phong_spec_intensity(in PointLight light, in rt_hit hit, in int highlight_exp) {
    float k = phong_spec_coeff(light, hit);
    return ipow(k*HIGHLIGHT_OFFSET, highlight_exp);
}

void phong_light(in PointLight light, inout rt_hit hit, in vec3 diffuse, in vec3 specular, in int highlight_exp) {
    //IaCa + CL( IdCd + IsCs )
    
    vec3 IaCa = AMBIENT_INTENSITY*AMBIENT_COLOR;
    vec3 IdCd = lambert_diffuse_intensity(light, hit)*diffuse;
    float Is = phong_spec_intensity(light, hit, highlight_exp); vec3 Cs = specular;
    
    hit.color.rgb = IaCa + light.color.rgb*( IdCd + Is*Cs );
    //hit.color.rgb = IaCa + light.color.rgb*( mix(vec3(Is), Cs, IdCd) );
}

// END PHONG MODEL

// BEGIN MULTIPLE LIGHTS

struct Multilight {
    vec4 ambient;
    PointLight[MAX_LIGHTS] lights;
    int light_count; //Should never exceed MAX_LIGHTS
};

void phong_multilight(in Multilight this, inout rt_hit hit, in vec3 diffuse, in vec3 specular, in int highlight_exp) {
    vec3 color_out = this.ambient.rgb * this.ambient.a;
    
    for(int i = 0; i < this.light_count; ++i) {
        PointLight light = this.lights[i];
        
        //Phong light boilerplate
    	vec3 IdCd = lambert_diffuse_intensity(light, hit)*diffuse;
        float Is = phong_spec_intensity(light, hit, highlight_exp); vec3 Cs = specular;
        color_out += clamp01(light.color.rgb*( IdCd + Is*Cs ));
    }
    
    hit.color.rgb = color_out;
}

// END MULITPLE LIGHTS

// BEGIN LIGHT DEBUG DISPLAY

//Copy from Sphere
float hit(in PointLight this, in Ray ray) {
    vec4 relpos = ray.origin-this.pos;
	
	float      a = lenSq(ray.direction);
	float half_b = dot(relpos, ray.direction);
	float      c = lenSq(relpos) - sq(DEBUG_LIGHT_SPHERE_RADIUS);
	
    float disc = sq(half_b) - a*c;
    
    if(disc < 0.) return -1.;
    else {
        return abs( (-half_b-sqrt(disc))/a );
    }
}

//Copy from Sphere
vec4 normal(in PointLight this, in vec4 global_pos) {
    //return normalize(global_pos-this.center);
    return (global_pos-this.pos)/DEBUG_LIGHT_SPHERE_RADIUS;
}

//Copy from Sphere
rt_hit raytrace(in PointLight this, in Ray ray) {
	float hitT = hit(this, ray);
    
    if(hitT < 0.) return rt_hit_none();
    else {
        PREPARE_VARS(hitT);
        BACKFACE_CULL;
        NEARPLANE_CULL;

        hit.color.rgb = this.color.rgb;
        hit.color.a = 0.6;

        return hit;
    }
}

//Multiple lights. Tests them all based on Z
rt_hit raytrace(in Multilight this, in Ray ray) {
    rt_hit outv;
    for(int i = 0; i < this.light_count; i++) {
        rt_hit hit = raytrace(this.lights[i], ray);
        outv = z_blend(hit, outv);
    }
    return outv;
}

// END LIGHT DEBUG DISPLAY

// END LIGHTS


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

//Get the texture coordinate of the given sphere.
vec2 getTexCoords(in Sphere this, in vec4 global_pos) {
    vec4 local_pos = global_pos-this.center;
    vec2 val;
    
    //FIXME Terribly inefficient
    val.s = atan2(local_pos.z, local_pos.x); // azimuth
    val.t = atan2(local_pos.y, length(local_pos.xz)); // elevation
    
    //Make it turn with time. Equivalent to (val.s+iTime/2.)%1.
    val.s = getDecimalPart(val.s+iTime/2.);
    
    return val;
}

//Raytrace onto a sphere. Calls sphere_hit and (if hit) sphere_color
rt_hit raytrace(in Sphere this, in Ray ray, in Multilight lighting) {
	float hitT = hit(this, ray);
    
    if(hitT < 0.) return rt_hit_none();
    else {
        PREPARE_VARS(hitT);
        BACKFACE_CULL;
        NEARPLANE_CULL;

        //Set the color by sampling the texture in iChannel0
        hit.color = texture(iChannel0, getTexCoords(this, hit.pos));
        
        //Apply lighting
        phong_multilight(lighting, hit, hit.color.rgb, hit.color.rgb, HIGHLIGHT_EXP );

        return hit;
    }
}

// END SPHERE


// BEGIN RAYTRACING

//Sample ALL objects in the scene. If you want to add objects, write them in here.
//Note: There is now Z-testing!
vec4 rt_sample_all(in Ray ray, in Ray rMouse) {
    rt_hit outv;
    vec4 col_out = calcBGColor(ray);
    
    //Lights
    Multilight lighting;
    lighting.ambient = vec4(AMBIENT_COLOR, AMBIENT_INTENSITY);
    lighting.light_count = 2;
    
    lighting.lights[0] = mk_PointLight(SPHERE_CENTER+vec4(sin(iTime*1.5), cos(iTime*1.5),           1.5, 0) , vec3(1.0, 0.6, 0.6), 4.);
    lighting.lights[1] = mk_PointLight(SPHERE_CENTER+vec4( 2.*sin(iTime), sin(iTime*3.5), 2.*cos(iTime), 0) , vec3(0.6, 1.0, 1.0), 4.);
    
    //Parametric sphere
    
    outv = z_blend(raytrace(mk_Sphere(SPHERE_CENTER, SPHERE_RADIUS), ray, lighting), outv);
    //outv = z_blend(raytrace(mk_Sphere(ray_at(rMouse, 2.5), SPHERE_RADIUS), ray, lighting), outv);
    
    outv = z_blend(raytrace(lighting, ray), outv);
    
    alpha_blend(col_out, outv.color, col_out);
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