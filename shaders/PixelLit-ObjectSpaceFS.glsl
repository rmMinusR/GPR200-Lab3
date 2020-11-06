#version 330

#ifdef GL_ES
precision highp float;
#endif//GL_ES

uniform mat4 mViewport;

//Diffuse and specular textures
uniform sampler2D texDiff;
uniform sampler2D texSpec;

//Parameters from VS. Note that they will be lerped which messes with the normal length
in vec4 vertPos;
in vec4 vertNormal;
in vec2 vertUV;

//Final color
out vec4 fragColor;

struct Light {
	vec4 position;
	vec3 color;
	float intensity;
};

//Lights (see Variables tab)
uniform Light light0, light1, light2;

//Helper function
float sq(float v) { return v*v; }

//Integer-power. Significantly faster than pow(float, float)
float ipow(float b, int x) {
	/*
		b^x =
		b^(x_0+x_1+...+x_n) =
		b^x_0 * b^x_1 * ... * b^x_n
		x_k represents a bitmasked x where only the k-th bit is passed through
	*/
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

//Calculates lambertian reflectance for one light
vec3 lambert(in vec4 lightVector, in vec4 normal, in vec3 diffuse_color, in Light light, in float d) {
	float diffuse_coeff = max(0., dot(normal, lightVector));
	float attenuated_intensity = 1./sq(d/light.intensity+1.);
	float diffuse_intensity = diffuse_coeff * attenuated_intensity;
	
	return diffuse_intensity*diffuse_color;
}

//Calculates phong reflectance (specular highlight + lambertian) for one light
vec3 phong(vec4 view_pos, vec4 pos, vec4 normal, vec3 diffuse_color, vec3 spec_color, in Light light) {
	//Variables used by both specular and lambert computations
	vec4 viewVector = normalize(view_pos-pos);
	vec4 lightVector = light.position-pos;
	float lightDist = length(lightVector);
	lightVector /= lightDist;
	vec4 reflectedLightVector = reflect(lightVector, normal);
	
	//In the given equations, k sub s
	float ks = max(0., dot(viewVector, reflectedLightVector));
	
	//In the given equations, k sub s raised to the power a=128
	float spec_intensity = ipow(ks, 128);
	
	vec3 lambert_reflect = lambert(lightVector, normal, diffuse_color, light, lightDist);
	
	//(IdCd + IsCs)*CL
	return (lambert_reflect + spec_intensity*spec_color) * light.color;
}

void main() {
	//Get camera position
	vec4 vp_pos = vec4(mViewport[0].w, mViewport[1].w, mViewport[2].w, 1.);
	
	//Sample textures for diffuse and specular color
	vec3 diffuse_color = texture(texDiff, vertUV).rgb;
	vec3 spec_color =    texture(texSpec, vertUV).rgb;
	
	//Must renormalize the normal vector--lerping makes its magnitude less than 1
	//This causes specular highlights to show up only along edges, unsmoothed
	vec4 n_vertNormal = normalize(vertNormal);
	
	//Combine multiple lights into final color--ambient color is black
	fragColor = vec4(
		phong(vp_pos, vertPos, n_vertNormal, diffuse_color, spec_color, light0)
	  + phong(vp_pos, vertPos, n_vertNormal, diffuse_color, spec_color, light1)
	  + phong(vp_pos, vertPos, n_vertNormal, diffuse_color, spec_color, light2),
	1);
}