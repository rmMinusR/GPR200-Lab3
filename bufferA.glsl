/*

Midterm: Fractal raymarcher
'Buffer A' tab by Sean Sawyers-Abbott, with contributions from Robert Christensen

This shader is an accumulation buffer that manages the camera position and rotation.

Channel setup:
 0: self
 1: keyboard

*/

// calculates the camera's movement in global space based on the user's inputs
vec3 calcMovement()
{
    // gets the camera rotation
    vec2 camRot = texelFetch(iChannel0, camRotInd, 0).xy;
    
    // local right axis
    vec3 right = vec3(cos(camRot.y), 0.0, sin(camRot.y));
    
    // local forward axis
    vec3 forward = vec3(sin(camRot.y) * cos(camRot.x),
                                       -sin(camRot.x),
                       -cos(camRot.y) * cos(camRot.x));
    // global up axis
    vec3 up = vec3(0., 1., 0.);
    
    // gets the user's key inputs to determine camera movement
    // "local" 3D movement ranging -1 to 1 on each axis
    vec3 keyInput = vec3( texelFetch(iChannel1, ivec2(KEY_D, 0), 0).r
                         -texelFetch(iChannel1, ivec2(KEY_A, 0), 0).r,
                          texelFetch(iChannel1, ivec2(KEY_W, 0), 0).r
                         -texelFetch(iChannel1, ivec2(KEY_S, 0), 0).r,
                          texelFetch(iChannel1, ivec2(SPACE, 0), 0).r
                         -texelFetch(iChannel1, ivec2(LCTRL, 0), 0).r);
    
    // checks if the shift key is held to speed up camera movement
    keyInput *= texelFetch(iChannel1, ivec2(SHIFT, 0), 0).r + 1.;
    
    // puts movement into the axes
    right *= keyInput.x * moveSens;
    forward *= keyInput.y * moveSens;
    up *= keyInput.z * moveSens;
    
    // returns total movement
    return right + forward + up;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // gets current pixel
    ivec2 posCoord = ivec2(fragCoord.x, fragCoord.y);
    
    // checks if the current pixel is where movement is stored
    if (posCoord == camPosInd)
    {
        // initialization to default value: checks if on the first frame or escape is pressed
        if (iFrame == 0 || texelFetch(iChannel1, ivec2(ESC, 0), 0).r == 1.)
        {
            // moves the camera outside of the fractal
            // slightly offsets the XY position as for some reason
            // if it's at 0.0, 0.0, then it will teleport into
            // the fractal upon moving directly forwards
            // or backwards upon start
            fragColor = vec4(0.001, 0.001, 1.5, 0.);
            //RC: this is because distance estimation messes up around (x=0, y=0)
            //Take a look at the -Z tip of the fractal and you'll see it break down into pointclouds
        }
        else
        {
            // converts the sampled channel into a texture
            vec4 camera = texelFetch(iChannel0, camPosInd, 0);
            
            // gets the length of the camera
            float lenCam = length(camera);
            
            // checks if the camera's length is too far away
            if (lenCam > 4.5)
            {
                // sets the camera to be inside the safe space
                camera = camera / lenCam * 4.5;
            }
            
            // gets the distance from the camera to the nearest point
            float dist = signedDistance(camera);
            
            // calculates the movement while getting slower when it
            // gets closer to the nearest point
            fragColor = camera + vec4(calcMovement() * dist, 0.0);
        }
    }
    
    // checks if the current pixel is where mouse position is stored
    if (posCoord == mouseInd)
    {
        // allows the user to control the camera's rotation with the mouse
        fragColor.xy = iMouse.xy;
    }
    
    // checks if the current pixel is where the camera's rotation is stored
    if (posCoord == camRotInd)
    {
        // checks if escape is pressed
        if (texelFetch(iChannel1, ivec2(ESC, 0), 0).r == 1.)
        {
            fragColor = vec4(0.);
        }
        else
        {
	        // gets the camera's rotation
	        vec2 camRot = texelFetch(iChannel0, ivec2(camRotInd), 0).xy;
	        
	        // gets the mouse's x and y positions
	        vec2 deltaMouse = iMouse.xy - texelFetch(iChannel0, mouseInd, 0).xy;
	        
	        // ensures smooth, consistent rotation of the camera
	        if (length(deltaMouse) < 25.)
	        {
	            // rotates the camera at the given speed
	            camRot += deltaMouse.yx * mouseSens;
	        }
	        
        	// rotates the camera in the x direction and
        	// stops the camera from doing a full rotation up or down
        	fragColor.x = clamp(camRot.x, -90.*DEG2RAD, 90.*DEG2RAD);
        	
        	// rotates the camera in the y direction
        	fragColor.y = camRot.y;
        }
    }
}