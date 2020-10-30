// calculates the camera's movement based on the user's inputs
vec3 calcMovement()
{
    // gets the camera rotation
    vec2 camRot = texelFetch(iChannel0, camRotPos, 0).xy;
    
    // local right axis
    vec3 right = vec3(cos(camRot.y), 0.0, sin(camRot.y));
    
    // local forward axis
    vec3 forward = vec3(sin(camRot.y) * cos(camRot.x),
                                       -sin(camRot.x),
                       -cos(camRot.y) * cos(camRot.x));
    // global up axis
    vec3 up = vec3(0., 1., 0.);
    
    // gets the user's key inputs to determine camera movement
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
    // gets camera's current position
    vec4 self = texelFetch(iChannel0, ivec2(fragCoord), 0);
    
    // gets current pixel
    ivec2 posCoord = ivec2(fragCoord.x, fragCoord.y);
    
    // checks if the current pixel is where movement is stored
    if (posCoord == camPos)
    {
        // checks if on the first frame
        if (iFrame == 0)
        {
            // moves the camera outside of the fractal
            fragColor = vec4(0., 0., 1.5, 0.);
        }
        else
        {
            // converts the sampled channel into a texture
            vec4 camera = texelFetch(iChannel0, camPos, 0);
            
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
    if (posCoord == mousePos)
    {
        // allows the user to control the camera's rotation with the mouse
        fragColor.xy = iMouse.xy;
    }
    
    // checks if the current pixel is where the camera's rotation is stored
    if (posCoord == camRotPos)
    {
        // gets the camera's x and y positions
        vec2 camRot = self.xy;
        
        // gets the mouse's x and y positions
        vec2 deltaMouse = iMouse.xy - texelFetch(iChannel0, mousePos, 0).xy;
        
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