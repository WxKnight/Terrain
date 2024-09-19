/***************************************************************************************************
*
* 天地光
* 
***************************************************************************************************/

#ifndef HRP_SKY_GROUND_AMBIENT_INCLUDED
#define HRP_SKY_GROUND_AMBIENT_INCLUDED


#include "../Pipeline/BFP/Core/BFP_Core.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Lighting.hlsl"

uniform half3 _CharactorAmbientSky;
uniform half3 _CharactorAmbientEquator;
uniform half3 _CharactorAmbientGround;

half3 CalculateSkyGroundAmbientLight(half3 normalWorld)
{
#if defined(_CHARACTER_GRAPHIC_MEDIUM) || defined(_CHARACTER_GRAPHIC_LOW)
    //Flat ambient is just the sky color
    half3 ambient = _CharactorAmbientSky.rgb * 0.75;
    return ambient;
#else

    //Magic constants used to tweak ambient to approximate pixel shader spherical harmonics 
    half3 worldUp = half3(0, 1, 0);
    half skyGroundDotMul = 2.5;
    half minEquatorMix = 0.5;
    half equatorColorBlur = 0.33;

    half upDot = dot(normalWorld, worldUp);

    //Fade between a flat lerp from sky to ground and a 3 way lerp based on how bright the equator light is.
    //This simulates how directional lights get blurred using spherical harmonics

    //Work out color from ground and sky, ignoring equator
    half adjustedDot = upDot * skyGroundDotMul;
    half3 skyGroundColor = lerp(_CharactorAmbientGround, _CharactorAmbientSky, saturate((adjustedDot + 1.0) * 0.5));

    //Work out equator lights brightness
    half equatorBright = saturate(dot(_CharactorAmbientEquator.rgb, _CharactorAmbientEquator.rgb));

    //Blur equator color with sky and ground colors based on how bright it is.
    half3 equatorBlurredColor = lerp(_CharactorAmbientEquator, saturate(_CharactorAmbientEquator + _CharactorAmbientGround + _CharactorAmbientSky), equatorBright * equatorColorBlur);

    //Work out 3 way lerp inc equator light
    half smoothDot = abs(upDot);
    half3 equatorColor = lerp(equatorBlurredColor, _CharactorAmbientGround, smoothDot) * step(upDot, 0) + lerp(equatorBlurredColor, _CharactorAmbientSky, smoothDot) * step(0, upDot);

    return lerp(skyGroundColor, equatorColor, saturate(equatorBright + minEquatorMix)) * 0.75;
#endif
}



#endif