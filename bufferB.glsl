vec3 calcMovement()
{
    vec2 camRot = texelFetch(iChannel0, camRotPos, 0).xy;
    
    vec3 right = vec3(cos(camRot.y), 0.0, sin(camRot.y));
    
    vec3 forward = vec3(sin(camRot.y) * cos(camRot.x),
                                       -sin(camRot.x),
                       -cos(camRot.y) * cos(camRot.x));
    
    vec2 keyInput = vec2( texelFetch(iChannel1, ivec2(RIGHT, 0), 0).r
                         -texelFetch(iChannel1, ivec2(LEFT , 0), 0).r,
                          texelFetch(iChannel1, ivec2(UP   , 0), 0).r
                         -texelFetch(iChannel1, ivec2(DOWN , 0), 0).r);
    forward *= keyInput.y * moveSens.y;
    right *= keyInput.x * moveSens.x;
    return right + forward;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 self = texelFetch(iChannel0, ivec2(fragCoord), 0);
    ivec2 posCoord = ivec2(fragCoord.x, fragCoord.y);
    
    if (posCoord == camPos)
    {
        fragColor = texelFetch(iChannel0, camPos, 0);
        fragColor += vec4(calcMovement(), 0.0);
    }
    
    if (posCoord == mousePos)
    {
        fragColor.xy = iMouse.xy;
    }
    
    if (posCoord == camRotPos)
    {
        vec2 camRot = self.xy;
        vec2 deltaMouse = iMouse.xy - texelFetch(iChannel0, mousePos, 0).xy;
        
        if (length(deltaMouse) < 25.)
        {
            camRot += deltaMouse.yx * mouseSens;
        }
        fragColor.x = clamp(camRot.x, -90.*DEG2RAD, 90.*DEG2RAD);
        fragColor.y = camRot.y;
    }
}