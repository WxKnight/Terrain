/***************************************************************************************************
*
* AlphaTest 相关代码
*

rely
 TAPipelineData (included)
 TAPipelineDataUtils(included)
 TALighting(included)
 TAPBS(included)
***************************************************************************************************/


#ifndef HRP_ALPHATEST_INCLUDED
#define HRP_ALPHATEST_INCLUDED

#include "../../ShaderLibrary/HPipelineData.hlsl"
#include "../../ShaderLibrary/HPipelineDataUtils.hlsl"
#include "../../ShaderLibrary/HLighting.hlsl"
#include "../../ShaderLibrary/HPBS.hlsl"

/***************************************************************************************************
 * Region : AlphaTest Get Surf Data Related Functions
 ***************************************************************************************************/


inline PBSSurfaceParam GetAlphaTestSurfDataNoSpec(half4 tintColor, half4 albedo)
{
    PBSSurfaceParam data = (PBSSurfaceParam)0;
    data.diffuseColor.xyz = albedo.xyz * tintColor.xyz;
    data.indirectAO = 1;
    return data;
}


inline PBSSurfaceParam GetAlphaTestSurfData(half4 tintColor, half4 albedo,half4 specColor)
{
    PBSSurfaceParam data = (PBSSurfaceParam)0;
    data.diffuseColor.xyz = albedo.xyz * tintColor.xyz;
    data.specularColor.xyz = specColor.xyz;
    data.indirectAO = 1;

    return data;

}

/***************************************************************************************************
 * Region :AlphaTest Get Dir Data Related Function
 ***************************************************************************************************/

inline PBSDirections GetAlphaTestDirDataForNoSpec(half3 lightDir, half3 viewDir, half3 normal)
{
    PBSDirections data = (PBSDirections)0;

    data.nDotL = max(dot(normal, lightDir), 0.0);
    data.nDotV = dot(normal, viewDir);

    return data;
}

inline PBSDirections GetAlphaTestDirData(half3 lightDir, half3 viewDir, half3 normal)
{
    PBSDirections data = (PBSDirections)0;

    half3 halfDir = normalize(lightDir + viewDir);
    data.nDotH = max(dot(halfDir, normal), 0.001);
    data.nDotL = dot(normal, lightDir);
    data.nDotV = dot(normal, viewDir);

    return data;
}

/***************************************************************************************************
 * Region : AlphaTest Calculate Color Related Functions
 ***************************************************************************************************/

inline half3 DiffuseForAlphaTestDiffuseOnly(half3 lightCol, half3 diffuseColor)
{
    return diffuseColor * lightCol;

}

inline half3 DiffuseForAlphaTest(half3 lightCol, half3 diffuseColor,half ndotl, half4 scatterColor, half scatterOffset)
{
    if (ndotl <= 0)
    {
        half3 scatter = max(abs(ndotl), scatterOffset) * lightCol * diffuseColor;
        return scatter * scatterColor.xyz;
    }
    else
        return diffuseColor * lightCol;
    
}


inline half3 DiffuseForAlphaTestWindProb(half3 lightCol, half3 lightDir, half3 worldNormal, half dirLightingScale)
{
    return max(dot(lightDir, worldNormal) * 0.5 + 0.5, 0) * lightCol * dirLightingScale;

}

/***************************************************************************************************
 * Region :  Light Probe Related Functions todo extract
 ***************************************************************************************************/

half3 LightProbe(half indirectAO, half3 wNormal, half3 diffuseColor)
{
    return diffuseColor * SampleSH(wNormal) * indirectAO;
}

#endif
