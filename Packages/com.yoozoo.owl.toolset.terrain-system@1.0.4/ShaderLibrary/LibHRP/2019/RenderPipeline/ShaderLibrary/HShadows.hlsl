#ifndef HRP_SHADOWS_INCLUDED
#define HRP_SHADOWS_INCLUDED

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterCoreRP/ShaderLibrary/Common.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterCoreRP/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "HShadowSample.hlsl"

#ifdef _UNIQUE_CHAR_SHADOW
    TA_SHADOWMAP_TEX(_ShadowCasterMap);
    TA_SHADOWMAP_SAMPLER(sampler_ShadowCasterMap);
#endif

#ifdef _UNIQUE_CHAR_SHADOW
    float4x4 _WorldToShadowUnique;
#endif

half MainLightRealtimeShadowAttenuation(float4 shadowCoord)
{
#if (!defined(_SHADOWS_ENABLED) && !defined(_IS_SHADOW_ENABLED)) || defined(_RECEIVE_SHADOWS_OFF)
    return 1.0h;
#endif

    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
}

half MainLightRealtimeShadowAttenuation(float2x4 shadowCoords)
{
#if (!defined(_SHADOWS_ENABLED) && !defined(_IS_SHADOW_ENABLED)) || defined(_RECEIVE_SHADOWS_OFF)
    return 1.0h;
#endif
    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half4 shadowParams = GetMainLightShadowParams();
    half atten1 = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoords[0], shadowSamplingData, shadowParams, false);
    half atten2 = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoords[1], shadowSamplingData, shadowParams, false);
    return min(atten1, atten2);
}

#endif