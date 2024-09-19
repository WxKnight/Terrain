#ifndef HRP_LIGHTING_INCLUDED
#define HRP_LIGHTING_INCLUDED



/************************************************************
 * 提供普适的光照模型
 * 1. 直接光照模型
 * 2. LightMap AHD 模型
 * 3. SH9 模型
 * 4. SH9 AHD 模型

 ************************************************************/



#include "HRoninSH.hlsl"
#include "HUnitySH.hlsl"
#include "HUtils.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Lighting.hlsl"



struct AHDLightInfo
{
    float3 directionalLightDir;
    float3 directionalLightCol;
    float3 ambientLightCol;
};



/*********************************
 * Extract AHD
 *********************************/


// 没有 Ambient
inline AHDLightInfo RuntimeLightInfoWrapToAHD(float3 lightColor, float3 lightDir)
{
    AHDLightInfo info = (AHDLightInfo)0;
    info.directionalLightCol = lightColor;
    info.directionalLightDir = lightDir;
    return info;
}



inline AHDLightInfo DirectionalLightmapToAHDLow(float2 lightmapUV, float3 lightDirection, float3 vertexWorldNormal)
{
    float4 lightColInTex = HTEX2D_LIGHTMAP(lightmapUV);
    float3 lightCol = lightColInTex.rgb * pow(lightColInTex.w, 2.2) * 34.493242; // decode

    AHDLightInfo ahdInfo = (AHDLightInfo)0;
    ahdInfo.directionalLightDir = vertexWorldNormal;
    ahdInfo.directionalLightCol = lightCol * 0.7;
    ahdInfo.ambientLightCol     = lightCol * 0.6;

    return ahdInfo;
}



inline AHDLightInfo DirectionalLightmapToAHD(float2 lightmapUV, float3 vertexWorldNormal)
{
    float4 lightDirInTex = HTEX2D_LIGHTMAP_DIR(lightmapUV);
    float4 lightDir      = float4(2 * lightDirInTex - 1);

    float4 lightColInTex = HTEX2D_LIGHTMAP(lightmapUV);
    float3 lightCol      = lightColInTex.rgb * pow(lightColInTex.w, 2.2) * 34.493242;            // decode


    float  mainLightFactor = length(lightDir.xyz);
    float3 mainLightDir = normalize(lightDir.xyz / max(0.001, mainLightFactor));
    float  nDotL        = max(lightDir.w, dot(mainLightDir, vertexWorldNormal));

    AHDLightInfo ahdInfo = (AHDLightInfo)0;
    ahdInfo.directionalLightDir = mainLightDir;
    ahdInfo.directionalLightCol = mainLightFactor * lightCol / max(0.1, nDotL);
    ahdInfo.ambientLightCol     = lightCol * (1 - mainLightFactor);

    return ahdInfo;
}



#define SH9ToAHD(props, info)     \
            ACCESS_SH_INSTANCED_PROP(props)                 \
            info.directionalLightCol = RoninSHLight0Col;    \
            info.directionalLightDir = RoninSHLight0Dir;    \
            info.ambientLightCol     = RoninSHAmbient;







#endif