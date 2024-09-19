/***************************************************************************************************
*
***************************************************************************************************/


#ifndef HRP_SKIN_RIM_LIGHT_INCLUDED
#define HRP_SKIN_RIM_LIGHT_INCLUDED



#include "../Pipeline/BFP/Core/BFP_Core.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Lighting.hlsl"

float _RimLightRate;
float _RimLightScale;
float _RimLightOffset;


// https://computergraphics.stackexchange.com/questions/5355/constant-screen-space-width-rim-shading
float3 CalculateRimLight(float3 normal, float3 lightDir, float3 viewDir)
{
    float unclampedNDotL = dot(normal, lightDir);
    float edge = 1 - dot(normal, viewDir);
    float facing = -dot(viewDir, lightDir) * 0.5 + 0.25;
    float outline = 1 / (1 + exp(-100 * (edge - _RimLightOffset)));
    return saturate(outline * facing) * _RimLightScale * smoothstep(-0.3, -0.1, unclampedNDotL);
}



#endif
