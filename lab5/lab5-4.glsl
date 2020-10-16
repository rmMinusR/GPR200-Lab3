/*
   Lab 5 part 3 by Robert Christensen
   With contributions by Daniel S. Buckstein
*/

// BEGIN RC'S UTILITY FUNCTIONS

#define PI 3.1415926535
#define DEG2RAD (PI/360.)
#define RAD2DEG (360./PI)

//I want to be able to use the "this" keyword
#define this _this

//Strip the integer part, return only the decimal part.
float getDecimalPart(in float x) {
    return x>0.?
        x-float(int(x)):
    	x-float(int(x))+1.;
}

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

// BEGIN ROTATIONS

vec4 rotateX(in vec4 v, in float ang) {
    return vec4(
    	v.x,
        v.y*cos(ang)-v.z*sin(ang),
        v.y*sin(ang)+v.z*cos(ang),
        v.w
    );
}

vec4 rotateY(in vec4 v, in float ang) {
    return vec4(
    	v.x*cos(ang)+v.z*sin(ang),
        v.y,
        -v.x*sin(ang)+v.z*cos(ang),
        v.w
    );
}

vec4 rotateZ(in vec4 v, in float ang) {
    return vec4(
    	v.x*cos(ang)-v.y*sin(ang),
        v.x*sin(ang)+v.y*cos(ang),
        v.z,
        v.w
    );
}

// END ROTATIONS

// END RC'S UTILITY FUNCTIONS

// BEGIN LAB 5 GLSL STARTER CODE BY DANIEL S. BUCKSTEIN

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

// BEGIN DB'S UTILITY FUNCTIONS

// asPoint: promote a 3D vector into a 4D vector representing a point in space (w=1)
sPoint asPoint(in sBasis v) { return sPoint(v, 1.0); }

// asVector: promote a 3D vector into a 4D vector representing a vector through space (w=0)
sVector asVector(in sBasis v) { return sVector(v, 0.0); }

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

// BEGIN RENDERING FUNCTIONS

// calcColor: calculate the color of current pixel
//	  vp:  input viewport info
//	  ray: input ray info
color4 calcColor(in sViewport vp, in sRay ray)
{
    return texture(iChannel0, rotateY(ray.direction, iTime*DEG2RAD*45.).xyz);
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
    
    // viewport info
    sViewport vp;

    // ray
    sRay ray;
    
    // render
    initViewport(vp, viewportHeight, focalLength, fragCoord, iResolution.xy);
    initRayPersp(ray, eyePosition, vp.viewportPoint.xyz);
    fragColor += calcColor(vp, ray);
}
