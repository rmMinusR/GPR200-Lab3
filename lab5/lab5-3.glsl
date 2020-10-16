/*
   Lab 5 part 3 by Robert Christensen
   With contributions by Daniel S. Buckstein
*/

// BEGIN TYPE ALIASES

// sScalar: alias for a 1D scalar (non-vector)
// sCoord: alias for a 2D coordinate
// sDCoord: alias for a 2D displacement or measurement
// sBasis: alias for a 3D basis vector
// sPoint: alias for a point/coordinate/location in space
// sVector: alias for a vector/displacement/change in space

#define sScalar float
#define sCoord vec2
#define sDCoord vec2
#define sBasis vec3
#define sPoint vec4
#define sVector vec4

// color3: alias for RGB color
// color4: alias for RGBA color

#define color3 vec3
#define color4 vec4

// END TYPE ALIASES

// BEGIN SETTINGS

const color3 AMBIENT_COLOR     = color3(0, 1, 1);
const float  AMBIENT_INTENSITY = 0.3;

const color3 LIGHT_COLOR = color3(1, 0, 0);
const float  LIGHT_INTENSITY = 32.;

// END SETTINGS

// BEGIN RC'S UTILITY FUNCTIONS

#define PI 3.1415926535
#define DEG2RAD (PI/360.)
#define RAD2DEG (360./PI)

//I want to be able to use the "this" keyword
#define this _this

//Float range remap. Now no longer an eeevil macro thanks to preprocessor!
#define GEN_DECLARE(genType) genType fmap(in genType v, in genType lo1, in genType hi1, in genType lo2, in genType hi2) { return (v-lo1)*(hi1-lo1)*(hi2-lo2)+lo2; }
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

// END RC'S UTILITY FUNCTIONS

// BEGIN LAB 5 GLSL STARTER CODE BY DANIEL S. BUCKSTEIN

// BEGIN DB'S UTILITY FUNCTIONS

// asPoint: promote a 3D vector into a 4D vector representing a point in space (w=1)
sPoint asPoint(in sBasis v) { return sPoint(v, 1.0); }
#define as_point(x) asPoint(x)

// asVector: promote a 3D vector into a 4D vector representing a vector through space (w=0)
sVector asVector(in sBasis v) { return sVector(v, 0.0); }
#define as_vector(x) asVector(x)

// END DB'S UTILITY FUNCTIONS
    
// BEGIN COORDINATE HANDLING
    
// sViewport: info about viewport
//    viewportPoint: location on the viewing plane 
//							x = horizontal position
//							y = vertical position
//							z = plane depth (negative focal length)
//	  pixelCoord:    position of pixel in image
//							x = [0, width)	-> [left, right)
//							y = [0, height)	-> [bottom, top)
//	  resolution:    resolution of viewport
//							x = image width in pixels
//							y = image height in pixels
//    resolutionInv: resolution reciprocal
//							x = reciprocal of image width
//							y = reciprocal of image height
//	  size:       	 in-scene dimensions of viewport
//							x = viewport width in scene units
//							y = viewport height in scene units
//	  ndc: 			 normalized device coordinate
//							x = [-1, +1) -> [left, right)
//							y = [-1, +1) -> [bottom, top)
// 	  uv: 			 screen-space (UV) coordinate
//							x = [0, 1) -> [left, right)
//							y = [0, 1) -> [bottom, top)
//	  aspectRatio:   aspect ratio of viewport
//	  focalLength:   distance to viewing plane
struct sViewport
{
    sPoint viewportPoint;
	sCoord pixelCoord;
	sDCoord resolution;
	sDCoord resolutionInv;
	sDCoord size;
	sCoord ndc;
	sCoord uv;
	sScalar aspectRatio;
	sScalar focalLength;
};

// initViewport: calculate the viewing plane (viewport) coordinate
//    vp: 		      output viewport info structure
//    viewportHeight: input height of viewing plane
//    focalLength:    input distance between viewer and viewing plane
//    fragCoord:      input coordinate of current fragment (in pixels)
//    resolution:     input resolution of screen (in pixels)
void initViewport(out sViewport vp,
                  in sScalar viewportHeight, in sScalar focalLength,
                  in sCoord fragCoord, in sDCoord resolution)
{
    vp.pixelCoord = fragCoord;
    vp.resolution = resolution;
    vp.resolutionInv = 1.0 / vp.resolution;
    vp.aspectRatio = vp.resolution.x * vp.resolutionInv.y;
    vp.focalLength = focalLength;
    vp.uv = vp.pixelCoord * vp.resolutionInv;
    vp.ndc = vp.uv * 2.0 - 1.0;
    vp.size = sDCoord(vp.aspectRatio, 1.0) * viewportHeight;
    vp.viewportPoint = asPoint(sBasis(vp.ndc * vp.size * 0.5, -vp.focalLength));
}

// END COORDINATE HANDLING

// BEGIN RAY BASIS

// sRay: ray data structure
//	  origin: origin point in scene
//    direction: direction vector in scene
struct sRay
{
    sPoint origin;
    sVector direction;
};
    
sPoint ray_at(in sRay this, in float t) { return this.origin + this.direction * t; }

// initRayPersp: initialize perspective ray
//    ray: 		   output ray
//    eyePosition: position of viewer in scene
//    viewport:    input viewing plane offset
void initRayPersp(out sRay ray,
             	  in sBasis eyePosition, in sBasis viewport)
{
    // ray origin relative to viewer is the origin
    ray.origin = asPoint(eyePosition);

    // ray direction relative to origin is based on viewing plane coordinate
    ray.direction = asVector(viewport - eyePosition);
}

// initRayOrtho: initialize orthographic ray
//    ray: 		   output ray
//    eyePosition: position of viewer in scene
//    viewport:    input viewing plane offset
void initRayOrtho(out sRay ray,
             	  in sBasis eyePosition, in sBasis viewport)
{
    // offset eye position to point on plane at the same depth
    initRayPersp(ray, eyePosition + sBasis(viewport.xy, 0.0), viewport);
}

// END RAY BASIS

// END LAB 5 BOILERPLATE

// BEGIN LIGHTS
// Taken from Robert's Lab 4

//Helper data structure
struct rt_hit {
    sPoint pos;
    sVector nrm;
    color4 color;
};

//Represents a single point light
struct PointLight {
    vec4 pos;
    vec4 color; //W/A used as intensity
};

//PointLight ctor
PointLight mk_PointLight(in vec4 center, in vec3 color, in float intensity) {
    PointLight val;
    val.pos = as_point(center.xyz);
    val.color.rgb = color;
    val.color.a = abs(intensity);
    return val;
}

//Attenuation coefficient due to light distance
float attenuation_coeff(in float d, in float intensity) {
    return 1./sq(d/intensity+1.);
}

// BEGIN LAMBERTIAN MODEL

//Lambertian diffuse coefficient
//BOTH INPUTS MUST BE NORMALIZED
float lambert_diffuse_coeff(in vec4 light_ray_dir, in vec4 normal) {
    return dot(normal, light_ray_dir);
}

//Lambertian diffuse intensity
float lambert_diffuse_intensity(in PointLight light, in rt_hit hit) {
    vec4 light_vector = normalize(light.pos-hit.pos);
    return lambert_diffuse_coeff(light_vector, hit.nrm) * attenuation_coeff(length(light_vector), light.color.a);
}

//Performs Lambertian lighting on the given rt_hit
void lambert_light(in PointLight light, inout rt_hit hit) {
    hit.color.rgb = lambert_diffuse_intensity(light, hit) * hit.color.rgb * light.color.rgb;
}

// END LAMBERTIAN MODEL

// BEGIN BLINN-PHONG MODEL

//Blinn-Phong specular coefficient
float phong_spec_coeff(in PointLight light, in rt_hit hit) {
    vec4 view_vector = normalize(-hit.pos);
    vec4 light_vector = normalize(light.pos-hit.pos);
    //vec4 refl_light_vector = reflect(-light_vector, hit.nrm);
    vec4 halfway = vec4(normalize(view_vector+light_vector).xyz, 0);
    return dot(hit.nrm, halfway);
}

//Blinn-Phong specular intensity
float phong_spec_intensity(in PointLight light, in rt_hit hit, in int highlight_exp) {
    float k = phong_spec_coeff(light, hit);
    return ipow(k, highlight_exp);
}

//Performs Blinn-Phong lighting on the given rt_hit
void phong_light(in PointLight light, inout rt_hit hit, in color3 diffuse, in color3 specular, in int highlight_exp) {
    //IaCa + CL( IdCd + IsCs )
    
    color3 IaCa = AMBIENT_INTENSITY*AMBIENT_COLOR;
    color3 IdCd = lambert_diffuse_intensity(light, hit)*diffuse;
    float Is = phong_spec_intensity(light, hit, highlight_exp); vec3 Cs = specular;
    
    hit.color.rgb = IaCa + light.color.rgb*( IdCd + Is*Cs );
}

// END PHONG MODEL

// END LIGHTS

// BEGIN RAYTRACEABLE OBJECTS

sVector normal(in sViewport this) {
    return normalize(vec4(this.ndc, 0, 0));
}

color4 color(in sViewport this, in sRay ray, in PointLight light) {
    //Create virtual hit object
    rt_hit hit;
    hit.pos = asPoint(sBasis(this.viewportPoint.xy, -1));
    hit.nrm = normal(this);
    
    //Colors for lighting
    color3 specular = color3(1, 1, 1);
    color3 diffuse = color3(0.8, 0.8, 0.8);
    
    //Apply Blinn-Phong lighting
    phong_light(light, hit, diffuse, specular, 64);
    
    return hit.color;
}

// END RAYTRACEABLE OBJECTS

// BEGIN RENDERING FUNCTIONS

// calcColor: calculate the color of current pixel
//	  vp:  input viewport info
//	  ray: input ray info
color4 calcColor(in sViewport vp, in sRay ray, in sViewport mouseVp, in sRay mouseRay)
{
    //Make a light at the mouse position
    PointLight light = mk_PointLight(sPoint(ray_at(mouseRay, 2.).xy, 1, 1), LIGHT_COLOR, LIGHT_INTENSITY);
    
    //Render the viewport quad
    return color(vp, ray, light);
}

// END RENDERING FUNCTIONS

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
    
    // map fragment coords
    sViewport vp;
	sRay ray;
    
    initViewport(vp, viewportHeight, focalLength, fragCoord, iResolution.xy);
    initRayPersp(ray, eyePosition, vp.viewportPoint.xyz);
    
    // map mouse coords
    
    sViewport mouseCoord;
    sRay mouseRay;
    
    initViewport(mouseCoord, viewportHeight, focalLength, iMouse.xy, iResolution.xy);
    initRayPersp(mouseRay, eyePosition, mouseCoord.viewportPoint.xyz);
    
    // render
    
    fragColor += calcColor(vp, ray, mouseCoord, mouseRay);
}
