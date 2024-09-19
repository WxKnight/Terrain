// Baked Forward Pipeline
// Tiled Forward Pipeline
// Tiled Deferred Pipeline


#ifndef HRP_BFP_CORE_INCLUDED
#define HRP_BFP_CORE_INCLUDED

#include "../../../../ShaderLibrary/HCore.hlsl"
#include "../../../../ShaderLibrary/HPipelineDataUtils.hlsl"
#include "../../../../ShaderLibrary/HLighting.hlsl"
#include "../../../../ShaderLibrary/HPBS.hlsl"
#include "../../../../ShaderLibrary/HUtils.hlsl"
#include "../../../Features/HSkyGroundAmbientLight.hlsl"

//低配下对用纯色补偿IBL，并调整BlinnPhong brdf的scale, 在EnvironmentSetup中设置
uniform half4 _EnvIBLFakeColor;
//uniform half    _SpecBrdfScaleForLow;


inline HV2F BFP_CreateV2FData(HAppData appData, float4 st)
{
    HV2F o = (HV2F) 0;

    UNITY_SETUP_INSTANCE_ID(appData);
    UNITY_TRANSFER_INSTANCE_ID(appData, o);

    o.vertex = TransformObjectToHClip(appData.vertex.xyz);
    o.color = appData.color;
    UV0(o) = appData.uv0 * st.xy + st.zw;
    PackLightMapUV(o, appData);

    GetPackedT2W(appData, o.tToW);

    return o;
}

inline void BFP_UnpackV2FData(inout HV2F data)
{
    UNITY_SETUP_INSTANCE_ID(data);
    RenormalizeT2W(data.tToW);
}

inline AHDLightInfo BFP_LightmapToAHD(float2 lightmapUV, float3 vertexWorldNormal)
{
#ifdef _LOW_LIGHTMAP_TO_AHD
    return DirectionalLightmapToAHDLow(lightmapUV, _MainLightPosition.xyz, vertexWorldNormal);
#else
    return DirectionalLightmapToAHD(lightmapUV, vertexWorldNormal);
#endif
}

// 直接光照来自于设定的光源，Ambient 来自于天地光
// TODO: sh 影响光源强度
// 现有的 SH 密度，不足以支撑使用 SH 来影响光源强度
inline AHDLightInfo BFP_RealTimeToAHD(float3 normal)
{
    AHDLightInfo info = (AHDLightInfo) 0;
    info.directionalLightCol = _MainLightColor.xyz;
    info.directionalLightDir = _MainLightPosition.xyz;

    info.ambientLightCol = CalculateSkyGroundAmbientLight(normal);
    return info;
}

inline AHDLightInfo BFP_RealTime(float3 normal)
{
    AHDLightInfo info = (AHDLightInfo) 0;
    info.directionalLightCol = _MainLightColor.xyz;
    info.directionalLightDir = _MainLightPosition.xyz;

    info.ambientLightCol = ShadeSH9(float4(normal, 1));

    return info;
}

inline half3 BFP_Diffuse(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, float3 lightColor, float3 cameraLightColor)
{
    half3 normalDiffuse = CalculateLambertDiffuse(fresnel, dirs.nDotL, lightColor);
    half3 cameraDiffuse = CalculateLambertDiffuse(fresnel, dirs.nDotV, cameraLightColor);
    return lerp(normalDiffuse, cameraDiffuse, 0.3) * surface.diffuseColor;
}

inline half3 BFP_DiffuseForScene(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, float3 lightColor)
{
    half3 normalDiffuse = CalculateLambertDiffuse(fresnel, dirs.nDotL, lightColor);
    return normalDiffuse * surface.diffuseColor;
}

inline half3 BFP_DiffuseHalfLambert(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, float3 lightColor, float3 cameraLightColor)
{
    half3 normalDiffuse = CalculateHalfLambertDiffuse(fresnel, dirs.nDotL, lightColor);
    half3 cameraDiffuse = CalculateHalfLambertDiffuse(fresnel, dirs.nDotV, cameraLightColor);
    return lerp(normalDiffuse, cameraDiffuse, 0.3) * surface.diffuseColor;
}

inline half3 BFP_Specular(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, half3 lightColor)
{
#if defined(_SCENE_GRAPHIC_SUPREME) || defined(_SCENE_GRAPHIC_HIGH) || defined(_SCENE_GRAPHIC_MEDIUM) || defined(_CHARACTER_GRAPHIC_HIGH) || defined(_CHARACTER_GRAPHIC_MEDIUM)
    return CalculateUnity2018GGXBRDF(fresnel, surface, dirs) * dirs.nDotL * lightColor;
#else
    return CalculateBlinnPhongBRDF(fresnel, surface, dirs) * dirs.nDotL * lightColor * surface.specularColor * lerp(18, 5, surface.metallic);
#endif
}

inline half3 BFP_SpecularForLevel(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, half3 lightColor)
{
#if defined (_SPECULAR_BRDF_GGX)
    return CalculateUnity2018GGXBRDF(fresnel, surface, dirs) * dirs.nDotL * lightColor;
#else
    return CalculateBlinnPhongBRDF(fresnel, surface, dirs) * dirs.nDotL * lightColor * surface.specularColor * lerp(18, 5, surface.metallic);
#endif
}

//clamp blinn phong brdf，针对杭州城金属大楼
inline half3 BFP_SpecularForLevel_ClampLow(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, half3 lightColor, float clampMaxForLow)
{
#if defined (_SPECULAR_BRDF_GGX)
    return CalculateUnity2018GGXBRDF(fresnel, surface, dirs) * dirs.nDotL * lightColor;
#else
    return min(CalculateBlinnPhongBRDF(fresnel, surface, dirs), clampMaxForLow) * dirs.nDotL * lightColor * surface.specularColor * lerp(20, 5, surface.metallic);
#endif
}

// TODO: is it need to multiply specularColor?
inline half3 BFP_InSpecular(PBSSurfaceParam surface, PBSDirections dirs)
{
#if defined(_SCENE_GRAPHIC_HIGH) || defined(_CHARACTER_GRAPHIC_SUPREME)
    return UnrealIBLApproximation(surface, dirs);
#elif defined(_SCENE_GRAPHIC_MEDIUM) || defined(_CHARACTER_GRAPHIC_HIGH)
    return CoDIBLApproximation(surface, dirs);
#else
    return 0;
#endif
}

inline half3 BFP_InSpecularForLevel(PBSSurfaceParam surface, PBSDirections dirs)
{
#if defined(_IBL_UE)
    return UnrealIBLApproximation(surface, dirs);
#elif defined(_IBL_COD)
    return CoDIBLApproximation(surface, dirs);
#else
    return 0;
#endif
}

inline half3 BFP_InSpecularFakeIBL(PBSSurfaceParam surface, PBSDirections dirs)
{
    half3 reflectDir = reflect(-dirs.viewDir, dirs.normal);
    half3 inspecular = surface.specularColor * _EnvIBLFakeColor.rgb * (1 - abs(reflectDir.y)); //function
    return inspecular;
}

//低配PolishedFloor使用
inline half3 BFP_GetIBLLightLerpFake(samplerCUBE specCubeSampler, half specCubeStrength, float perceptualRoughness, float3 viewDir, float3 wNormal, half metallic)
{
    half3 reflectDir = reflect(-viewDir, wNormal);
    half mip = HPerceptualRoughnessToMipmapLevel(perceptualRoughness) * 2;

    half4 IBLCol = texCUBElod(specCubeSampler, float4(reflectDir, mip));
    half3 iblColCube = HDecodeHDREnvironment(IBLCol, float4(1, 1, 0, 0));

    half3 iblColMetal = _EnvIBLFakeColor.rgb * (1 - abs(reflectDir.y)); //fake ibl
    half3 iblCol = lerp(iblColCube * specCubeStrength, iblColMetal, metallic);
    return iblCol;
}

inline half3 BFP_InSpecularForCharacter(samplerCUBE specCubeSampler, PBSSurfaceParam surface, PBSDirections dirs)
{
#if defined(_SCENE_GRAPHIC_HIGH) || defined(_CHARACTER_GRAPHIC_SUPREME)
    return UnrealIBLApproximation(specCubeSampler, surface, dirs);
#elif defined(_SCENE_GRAPHIC_MEDIUM) || defined(_CHARACTER_GRAPHIC_HIGH)
    return CoDIBLApproximation(specCubeSampler, surface, dirs);
#else
    return 0;
#endif
}


// Debug




// custom debug



#ifdef BLEND_ON
#define DEBUG_BLEND(finalColor, albedo, emission, transparent)  ADD_COLOR_TO_DEBUG(finalColor.xyz + albedo.xyz * emission, albedo.w * transparent);
#else
#define DEBUG_BLEND(finalColor, albedo, emission, transparent)
#endif


// not containt blend
#define DEBUG_COLOR(finalColor, lightMapColor, diffuse, specular, indirectDiffuse, indirectSpecular, AO)   \
    DEBUG_COLOR_BEGIN(finalColor, lightMapColor, diffuse, specular, indirectDiffuse, indirectSpecular, AO); \
    DEBUG_COLOR_END


float4 ShowCharaterQuarlity()
{
#if   defined(_CHARACTER_INTERNAL_GRAPHIC_SUPREME)
    return float4(1, 0, 0, 1);
#elif defined(_CHARACTER_INTERNAL_GRAPHIC_HIGH)
    return float4(0, 1, 0, 1);
#elif defined(_CHARACTER_INTERNAL_GRAPHIC_MEDIUM)
    return float4(0, 0, 1, 1);
#else // _CHARACTER_INTERNAL_GRAPHIC_LOW
    return float4(0, 0, 0, 1);
#endif
}



#endif