const int LEFT  = 37;
const int UP    = 38;
const int RIGHT = 39;
const int DOWN  = 40;

const vec2 sens = vec2(1,1);

vec3 calcMovement()
{
    vec2 camRot = texelFetch(iChannel0, ivec2(2, 0), 0).xy;
    vec3 right = vec3(sin(camRot.y), 0.0, -cos(camRot.y));
    vec3 forward = vec3(sin(camRot.y) * cos(camRot.x), sin(camRot.x),
                        cos(camRot.y) * cos(camRot.x));
    vec2 keyInput = vec2( texelFetch(iChannel1, ivec2(UP, 0), 0).r
                         -texelFetch(iChannel1, ivec2(DOWN, 0), 0).r,
                          texelFetch(iChannel1, ivec2(RIGHT, 0), 0).r
                         -texelFetch(iChannel1, ivec2(LEFT, 0), 0).r );
    forward *= keyInput.y;
    right *= keyInput.x;
    return vec3(keyInput, 0);//right + forward;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 self = texelFetch(iChannel0, ivec2(fragCoord), 0);
    ivec2 posCoord = ivec2(fragCoord.x, fragCoord.y);
    
    if (posCoord == ivec2(0, 0))
    {
        fragColor.xyz = texelFetch(iChannel0, ivec2(0,0), 0).xyz + calcMovement();
    }
    
    if (posCoord == ivec2(1, 0))
    {
        fragColor.xy = iMouse.xy;
    }
    
    if (posCoord == ivec2(2, 0))
    {
        vec2 camRot = self.xy;
        vec2 deltaMouse = iMouse.xy-texelFetch(iChannel0, ivec2(1, 0), 0).xy;
        
        if (length(deltaMouse) < 25. || true)
        {
            camRot += deltaMouse.yx * sens;
        }
        
        fragColor.x = clamp(camRot.x, -90., 90.);
        fragColor.y = camRot.y;
    }
}