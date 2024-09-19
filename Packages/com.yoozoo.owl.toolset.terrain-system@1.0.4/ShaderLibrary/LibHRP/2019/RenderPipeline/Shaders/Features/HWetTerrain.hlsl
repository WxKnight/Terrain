/***************************************************************************************************
 * 
 * 特性：积水地形
 *
 *  混合
 *  1. 使用顶点色的 w 通道和 normal 贴图的 w 通道进行混合控制
 *
 *  支持的特性：
 *  _MIRROR_ON : 水上将反射人物倒影，具体参考 http://wiki.daxiastudio.com/index.php?title=%E3%80%8A%E7%9B%97%E5%A2%93%E7%AC%94%E8%AE%B0M%E3%80%8B%E9%95%9C%E9%9D%A2%E5%8F%8D%E5%B0%84%E8%84%9A%E6%9C%AC%E5%92%8C%E6%9D%90%E8%B4%A8%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E
 *
 *
 ***************************************************************************************************/


#ifndef HRP_WET_TERRAIN_INCLUDED
#define HRP_WET_TERRAIN_INCLUDED

#include "../../ShaderLibrary/HUtils.hlsl"
#include "../../ShaderLibrary/HPBS.hlsl"



#define WetBlendInfo half





#ifdef _MIRROR_ON

    #define DEFINE_UNIFORM_MIRROR_PARAM           \
        uniform sampler2D _RefTexture;            \
        uniform float4x4  _ReflectionTransformVP; \
        uniform float     _Disable_Mirror_Reflection;//用于区分是否渲染了reflectionRT

    #define DEFINE_MIRROR_PARAM     \
        float _MirrorRange;         \
        float _MirrorPower;

#else
    #define DEFINE_UNIFORM_MIRROR_PARAM
    #define DEFINE_MIRROR_PARAM

#endif



#define DEFINE_WET_PARAM \
            half4  _WetColor;           \
            float  _WetHardness;        \
            half   _WetIBLStrength;     \
            DEFINE_MIRROR_PARAM
            DEFINE_UNIFORM_MIRROR_PARAM






inline WetBlendInfo CalculateWetBlendInfo(float4 tNormal, float4 color, float wetHardness)
{
    float controlValue = color.w;
    half blendInfo = lerp(-tNormal.w, 0.5, controlValue);
    blendInfo = saturate(blendInfo * wetHardness) * step(0.01, controlValue);
    return blendInfo;
}


inline half3 ApplyWetToTerrainNormal(WetBlendInfo blendInfo, float4 tNormal, HV2F v2fData)
{
    half3 tNormalDisturb = -(tNormal.xyz - half3(0, 0, 1)) * 0.96 * blendInfo;
    tNormal.xyz += tNormalDisturb;
    return TangentToWorld(v2fData, tNormal.xyz);
}


inline half4 ApplyWetToTerrainAlbedo(WetBlendInfo blendInfo, float4 albedo, float3 wetColor)
{
    float3 wetAlbedo = albedo.xyz * lerp(1, wetColor, blendInfo);
    return half4(wetAlbedo.xyz, albedo.w);
}



inline void ApplyWetToTerrainPBRParam(WetBlendInfo blendInfo, float rainSmoothness, inout PBSSurfaceParam param)
{
    // apply wet to smoothness
    half originSmoothness = 1 - param.perceptualRoughness;
    half wetSmoothnewss   = lerp(originSmoothness, rainSmoothness, blendInfo);
    param.perceptualRoughness = 1 - wetSmoothnewss;
    param.roughness = PerceptualRoughnessToRoughness(param.perceptualRoughness);

    // apply wet to AO
    param.AO += blendInfo;
}



#ifdef _MIRROR_ON


    inline void ApplyWetToIBLColor(inout half3 originalColor, float3 worldPos, float mirrorRange, float mirrorPower, half wetBlendInfo)
    {
        if (_Disable_Mirror_Reflection > 0.1)
            return;

        float4 refClipPos = mul(_ReflectionTransformVP, float4(worldPos, 1.0));
        float2 refUV = refClipPos.xy / refClipPos.w * 0.5 + 0.5;

        half4 mirrorCol;
        if ((refUV.x >= 0.0) && (refUV.x <= 1.0) && (refUV.y >= 0.0) && (refUV.y <= 1.0))
            mirrorCol = tex2D(_RefTexture, refUV);
        else
            mirrorCol = 0.0;
        float mirrorFactor = max((refUV.y - mirrorRange) * mirrorPower, 0.0);
        mirrorCol.rgb = mirrorFactor * mirrorCol.rgb * saturate(wetBlendInfo - 0.85) * 4;//只在水渍较深的地方倒影
        if (mirrorCol.r > 0.0001)//在有倒影的区域，
            originalColor = lerp(originalColor, mirrorCol.rgb, wetBlendInfo);
    }

    #define ADD_WET_TO_IBL_COLOR(worldPos, originalIBLColor, wetBlendInfo)     ApplyWetToIBLColor(originalIBLColor, worldPos, _MirrorRange, _MirrorPower, wetBlendInfo);
#else
    #define ADD_WET_TO_IBL_COLOR(worldPos, originalIBLColor, wetBlendInfo)
#endif


inline half ApplyWetToIBLBRDF(half originalBRDF, PBSSurfaceParam surface, PBSDirections dirs, WetBlendInfo wetBlendInfo)
{
    half n4 = Pow4(1 - dirs.nDotV);
    half ibrBRDF = (0.9 * n4 + 0.1) * (1 - surface.perceptualRoughness);
    return lerp(originalBRDF, ibrBRDF, wetBlendInfo);
}



#endif