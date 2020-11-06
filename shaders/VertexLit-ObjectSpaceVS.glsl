#version 330

#ifdef GL_ES
precision highp float;
#endif//GL_ES

uniform mat4 mViewport;
uniform mat4 mModel;

layout (location = 0) in vec4 pos;
layout (location = 1) in vec4 normal;
layout (location = 2) in vec2 uv;

out vec3 specIntensity;
out vec3 diffuseIntensity;
out vec2 vecUv;

// struct to hold the data of the lights
struct Light {
	vec4 position;
	vec3 color;
	float intensity;
};

uniform Light light0, light1, light2;

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

// returns the diffuse intensity
float lambert(in vec4 lightVector, in vec4 normal, in Light light, in float d) {
	float diffuse_coeff = max(0., dot(normal, lightVector));
	float attenuated_intensity = 1./sq(d/light.intensity+1.);
	return diffuse_coeff * attenuated_intensity;
}

// returns the specular intensity
float phong(vec4 lightVector, vec4 viewVector, vec4 normal, in Light light) {
	vec4 reflectedLightVector = reflect(lightVector, normal);
	float ks = max(0., dot(viewVector, reflectedLightVector));
	return ipow(ks, 2);
}

void main() {
	vec4 view_pos = vec4(mViewport[0].w, mViewport[1].w, mViewport[2].w, 1.);
	
	vec4 viewVector = normalize(view_pos-pos);
	
	// creating the variables for each of the lights
	vec4 lightVector0 = light0.position-pos;
	float distToLight0 = length(lightVector0);
	lightVector0 /= distToLight0;
	vec4 lightVector1 = light1.position-pos;
	float distToLight1 = length(lightVector1);
	lightVector1 /= distToLight1;
	vec4 lightVector2 = light2.position-pos;
	float distToLight2 = length(lightVector2);
	lightVector2 /= distToLight2;
	
	// calculating the specular intensity for each light using phong reflectance
	specIntensity     = light0.color * phong(lightVector0, viewVector, normal, light0);
	specIntensity    += light1.color * phong(lightVector1, viewVector, normal, light1);
	specIntensity    += light2.color * phong(lightVector2, viewVector, normal, light2);
	
	// calculating the diffuse intensity for each light using lambertian reflectance
	diffuseIntensity  = light0.color * lambert(lightVector0, normal, light0, distToLight0);
	diffuseIntensity += light1.color * lambert(lightVector1, normal, light1, distToLight1);
	diffuseIntensity += light2.color * lambert(lightVector2, normal, light2, distToLight2);
	
	vecUv = uv;
	
	gl_Position = mViewport * mModel * pos;
}