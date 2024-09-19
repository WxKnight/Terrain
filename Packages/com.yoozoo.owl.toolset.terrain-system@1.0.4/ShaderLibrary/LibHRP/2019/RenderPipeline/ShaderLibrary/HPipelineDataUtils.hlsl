/***************************************************************************************************
 * 
 * 对 TAPipelineData 中的数据结构，提供常用的复合工具
 *
 Rely 
    TAPipelineData

 ***************************************************************************************************/


#ifndef HRP_PIPELINE_DATA_UTILS_INCLUDED
#define HRP_PIPELINE_DATA_UTILS_INCLUDED


#include "HUtils.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterCoreRP/ShaderLibrary/Packing.hlsl"


 /*********************************
 * Extract World Normal from HV2F
 *********************************/

inline half3 CalculateWorldNormal(half3 tNormal, HV2F v2fData)
{
    half3 wNormal = TangentToWorld(v2fData, tNormal);
    return normalize(wNormal);
}

inline half3 CalculateWorldNormal(sampler2D normalTex, half2 normalMapUV, HV2F v2fData)
{
    half3 tNormal = UnpackNormal(tex2D(normalTex, normalMapUV));
    return CalculateWorldNormal(tNormal, v2fData);
}

inline float3 CalculateWorldNormal(sampler2D normalTex, half2 normalMapUV, half bumpScale, HV2F v2fData)
{
    half3 tNormal = UnpackScaleNormal(tex2D(normalTex, normalMapUV).xyz, bumpScale);
    return CalculateWorldNormal(tNormal, v2fData);
}

//Calculate normal from normalmap using rg only
half3 UnpackNormalRG(half4 packedNormal)
{
    return UnpackNormalmapRGorAG(packedNormal, 1.0);
}

inline half3 CalculateWorldNormalRG(float2 normalxy, HV2F v2fData)
{
    half3 tNormal = UnpackNormalRG(float4(normalxy.xy, 0, 1));
    return CalculateWorldNormal(tNormal, v2fData);
}

/*********************************
* Extract Surface PBR Param
*********************************/





#endif