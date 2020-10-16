/*

Accumulation Buffer (iChannel0 should be self)
Tracks mouse position, mouse delta, resolution
Uses mouse delta to create a view angle (clips if the mouse jumps -- delta is too extreme)

SETUP:
 - iChannel0: self - MUST be nearest

Recommended in Buffer D

*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Carry history (abuses Clamped mode)
    fragColor = texture(iChannel0, (fragCoord+vec2(-1,0))/iResolution.xy);
    
    vec4 mouseUV = iMouse;
    mouseUV.xy /= iResolution.xy;
    
    //Unless otherwise written to
    if(fragCoord.x < 1.) {
        
        //PX 0 = mouse data
        if(fragCoord.y < iResolution.y*0.25) {
            fragColor = mouseUV;
        }
        
        //PX 1 = mouse delta
        else if(fragCoord.y < iResolution.y*0.5) {
            vec4 pMouse = texture(iChannel0, vec2(0,0));
            fragColor = mouseUV-pMouse;
        }
        
        //PX 2 = pitch/yaw data
        else if(fragCoord.y < iResolution.y*0.75) {
            vec4 dMouse = texture(iChannel0, vec2(0,0.25));
            vec2 cPos = texture(iChannel0, vec2(0,0.5)).rg;
            
            if(lenSq(dMouse.xy*iResolution.xy) < sq(25.) && lenSq(iMouse.zw) > 0.) cPos += dMouse.xy * MOUSE_SENSITIVITY;
            
            //bound / wrap
            if(cPos.x < 0.) cPos.x += 1.;
            else if(cPos.x > 1.) cPos.x -= 1.;
            cPos.y = clamp(cPos.y, 0., 1.);
            
            fragColor.rg = cPos;
        }
        
        //PX 3 = resolution data
        else if(fragCoord.y < iResolution.y*1.0) {
            fragColor.xyz = iResolution.xyz;
        }
        
    }
    
}