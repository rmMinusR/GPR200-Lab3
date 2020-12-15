#ifndef HG_DITHER
#define HG_DITHER

int dither_helper(in bvec2 b) {
	return (b.x?1:0) | (!b.x^^b.y?2:0);
}

float dither(in ivec2 v) {
	bvec2 major = bvec2( v & 2 );
	bvec2 minor = bvec2( v & 1 );
	
	int value = 0;
	value |= dither_helper(major.xy);
	value |= dither_helper(minor.yx) << 2;
	return (value+0.5)/16.0;
}

#endif