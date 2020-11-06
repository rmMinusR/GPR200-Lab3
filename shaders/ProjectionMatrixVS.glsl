#version 330

#ifdef GL_ES
precision highp float;
#endif

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

// for rotation based on time
uniform float time;

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
float phong(vec4 lightVector, vec4 viewVector, vec4 normal) {
	vec4 reflectedLightVector = reflect(lightVector, normal);
	float ks = max(0., dot(viewVector, reflectedLightVector));
	return ipow(ks, 2);
}

void main() {
	// variables for changing the position of the camera
	float x = 0, y = 0, z = -2.5;
	vec4 view_pos = vec4(x, y, z, 1.);
	
	// creating the variables for each of the lights
	vec4 viewVector = normalize(view_pos-pos);
	vec4 lightVector0 = light0.position-pos;
	float distToLight0 = length(lightVector0);
	lightVector0 /= distToLight0;
	vec4 lightVector1 = light1.position-pos;
	float distToLight1 = length(lightVector1);
	lightVector1 /= distToLight1;
	vec4 lightVector2 = light2.position-pos;
	float distToLight2 = length(lightVector2);
	lightVector2 /= distToLight2;
	
	// variables for the near/far clipping planes
	float s = 1/tan(90*3.1415926/360);
	float n = 1, f = 100;
	
	// creates a box to hold the object for rendering
	mat4 vpMat = mat4(s, 0, 0, 0,
					  0, s, 0, 0,
					  0, 0, -f/(f-n), -f*n/(f-n),
					  0, 0, -1, 0);
					  
	// matrix for both rotating around and moving the camera away from the origin
	mat4 matCameraTransform = mat4(cos(time), -sin(time), 0, 0,
								   sin(time), cos(time), 0, 0,
								   0, 0, 1, 0,
								   x, y, z, 1);
	
	// calculating the specular intensity for each light using phong reflectance
	specIntensity 	 = step(0.5, phong(lightVector0, viewVector, normal)) * light0.color
					 + step(0.5, phong(lightVector1, viewVector, normal)) * light1.color
					 + step(0.5, phong(lightVector2, viewVector, normal)) * light2.color;
					 
	// calculating the diffuse intensity for each light using lambertian reflectance
	diffuseIntensity = (step(0.5, lambert(lightVector0, normal, light0, distToLight0)) * 0.9 + 0.1) * light0.color
					 + (step(0.5, lambert(lightVector1, normal, light1, distToLight1)) * 0.9 + 0.1) * light1.color
					 + (step(0.5, lambert(lightVector2, normal, light2, distToLight2)) * 0.9 + 0.1) * light2.color;
	
	vecUv = uv;
	
	gl_Position = vpMat * matCameraTransform * (mModel * pos);
}