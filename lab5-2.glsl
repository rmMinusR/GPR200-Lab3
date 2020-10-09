/*
   Lab 5 part 2 by Sean Sawyers-Abbott
   With contributions by Daniel S. Buckstein and Robert Christensen
*/

//Do I do the wave?
#define DO_WAVE

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

// END LAB 5 BOILERPLATE

// BEGIN RENDERING FUNCTIONS

// wave: distorts a 2D image with a wave effect
//    originLoc: 2D coordinate to be distorted
void wave(inout sCoord originLoc)
{
    originLoc.x += sin(originLoc.y * 5.0 + iTime) / 2.0;
}

// calcColor: calculate the color of current pixel
//	  vp:  input viewport info
//	  ray: input ray info
color4 calcColor(in sViewport vp)
{
    #ifndef DO_WAVE
    	return texture(iChannel0, vp.uv); // returns the texture as a still image
    #else
    	wave(vp.uv); // distorts the coordinate
   		return texture(iChannel0, vp.uv); // returns the texture as a distorted image
    #endif
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
    
    // render
    initViewport(vp, viewportHeight, focalLength, fragCoord, iResolution.xy);
    fragColor += calcColor(vp);
}