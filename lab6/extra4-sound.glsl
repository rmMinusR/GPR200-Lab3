/*

Can be placed anywhere, no setup necessary.

*/

vec2 mainSound( float time )
{
    //vary pitch by displacing time
    float td = 0.5*sin(time);
    //attenuate it
    float attenuation = sin(time*32.)*0.1 + sin(time*24.)*0.07;
    //generate it
    return attenuation * vec2( sin(2.*PI*440.0*(time+td)) );
}