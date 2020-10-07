// BEGIN RC'S UTILITY FUNCTIONS

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

// lengthSq: calculate the squared length of a vector type
#define GEN_DECLARE(genType) float lengthSq(in genType x) { return dot(x, x); }
GEN_DECLARE(vec2)
GEN_DECLARE(vec3)
GEN_DECLARE(vec4)
#undef GEN_DECLARE

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

// crossFade


// calcCoord: calculates the coordinates to display a 2D image
//    px:    current pixel coordinate
//    res:   coordinate system of 2D image's resolution
//    ratio: ratio of image resolution to screen resolution
sCoord calcCoord(in sCoord px, in sDCoord res, in sScalar ratio)
{
    return (px / res) * ratio;
}

// wave: distorts a 2D image with a wave effect
//    originLoc: 2D coordinate to be distorted
void wave(inout sCoord originLoc)
{
    originLoc.x += sin(originLoc.y * 5.0 + iTime) / 2.0;
}

// calcColor: calculate the color of current pixel
//	  vp:  input viewport info
//	  ray: input ray info
color4 calcColor(in sViewport vp, in sRay ray)
{
    sCoord px = vp.pixelCoord;
    sDCoord res = iChannelResolution[0].xy;
    sScalar ratio = res.y * vp.resolutionInv.y;
    color4 chan0 = texture(iChannel0, calcCoord(px, res, ratio));
    color4 chan1 = texture(iChannel1, calcCoord(px, res, ratio));
    return mix(chan0, chan1, (sin(iTime) + 1.0) / 2.0);
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