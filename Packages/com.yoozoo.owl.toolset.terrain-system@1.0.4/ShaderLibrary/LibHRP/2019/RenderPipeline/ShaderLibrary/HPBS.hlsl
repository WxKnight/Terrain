#ifndef HRP_PBS_INCLUDED
#define HRP_PBS_INCLUDED



/************************************************************
 * 提供 PBS 计算相关模型

 rely 
 TAPipelineData
 Unity_PBRCommon (included)
 ************************************************************/

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"
#include "HUtils.hlsl"


/***************************************************************************************************
 *
 * Region : PBR Related Data Structure
 *
 ***************************************************************************************************/


struct PBSDirections
{
    half3 lightDir;
    half3 viewDir;
    half3 halfVec;
    half3 normal;

    half nDotL;
    half nDotV;
    half nDotH;
    half hDotL;
    half hDotV;
};



struct PBSSurfaceParam
{
// Surface Material Param

    // perceptual Roughness
    half perceptualRoughness;

    // really ggx-using roughness
    half roughness;

    // 0 for totally non-metal(will to 0.04), 1 for totally metal
    half metallic;

    half AO;

    half indirectAO;


// Surface Color Param

    half3 specularColor;


    half3 diffuseColor;
};





/***************************************************************************************************
 *
 * Region : Struct Construct
 *
 ***************************************************************************************************/


// input must be normalized
inline PBSDirections CreatePBSDirections(half3 lightDir, half3 viewDir, half3 normal)
{
    PBSDirections directions = (PBSDirections)0;

    directions.lightDir = lightDir;
    directions.viewDir = viewDir;
    directions.halfVec = normalize(lightDir + viewDir);
    directions.normal = normal;

    directions.nDotL = max(dot(directions.normal, directions.lightDir), 0.001);
    directions.nDotV = max(dot(directions.normal, directions.viewDir), 0.001);
    directions.nDotH = max(dot(directions.normal, directions.halfVec), 0.001);
    directions.hDotL = max(dot(directions.halfVec, directions.lightDir), 0.001);
    directions.hDotV = max(dot(directions.halfVec, directions.viewDir), 0.001);

    return directions;
}


// 只包含最简单的 PBR 参数，不包含 Indirect AO，不包含颜色
// 用来方便的进行下面的 PBR 模型运算
inline PBSSurfaceParam ExtractPBRSurfaceParamSimple(half perceptualRoughness, half metallic, half AO)
{
    PBSSurfaceParam param = (PBSSurfaceParam)0;
    param.perceptualRoughness = perceptualRoughness;
    param.roughness  = PerceptualRoughnessToRoughness(perceptualRoughness);
    param.metallic   = metallic;
    param.AO         = AO;
    param.indirectAO = 1;
    return param;
}



inline PBSSurfaceParam ExtractPBRSurfaceParam(half perceptualRoughness, half metallic, half AO, half indirectAO, float3 albedo)
{
    PBSSurfaceParam param = (PBSSurfaceParam)0;
    param.perceptualRoughness = perceptualRoughness;
    param.roughness  = PerceptualRoughnessToRoughness(perceptualRoughness);
    param.metallic   = metallic;
    param.AO         = AO;
    param.indirectAO = indirectAO;

    param.specularColor = lerp(kDieletricSpec.xyz, albedo, param.metallic);
    param.diffuseColor  = albedo * (1 - param.metallic);
    return param;
}



inline PBSSurfaceParam ExtractPBRSurfaceParam(sampler2D paramTex, float2 paramMapUV, float3 albedo)
{
    float4 pbrParamInTex = tex2D(paramTex, paramMapUV);
    return ExtractPBRSurfaceParam(
        pbrParamInTex.y + 0.04,        // rough
        pbrParamInTex.x,               // metal
        pbrParamInTex.z,
        pbrParamInTex.w,
        albedo
    );
}

//贴图顺序 RMA
inline PBSSurfaceParam ExtractPBRSurfaceParamRMA(sampler2D paramTex, float2 paramMapUV, float3 albedo, float AOStrength)
{
    float4 pbrParams = tex2D(paramTex, paramMapUV);
    return ExtractPBRSurfaceParam(
        pbrParams.r,                                // rough
        pbrParams.g,                                // metal
        lerp(1.0, pbrParams.b, AOStrength),
        0,
        albedo
    );
}

//combine 3 textures into 2:albedo.a = ao, normal.b = roughness, normal.a = metallic
inline PBSSurfaceParam ExtractPBRSurfaceParamPackmaps(float4 albedo_ao, float4 normal_rm)
{
    return ExtractPBRSurfaceParam(
        normal_rm.z + 0.04, // rough
        normal_rm.w, // metal
        albedo_ao.w, //AO     
        1, //IndirectAO
        albedo_ao.rgb
    );
}

/***************************************************************************************************
 *
 * Region : Fresnel Term
 *
 ***************************************************************************************************/


inline float3 FresnelTerm(float3 f0, float sDotL)
{
    return f0 + (1 - f0) * pow(1 - sDotL, 5);
}


inline float FresnelTerm(float f0, float sDotL)
{
    return f0 + (1 - f0) * pow(1 - sDotL, 5);
}




/***************************************************************************************************
 *
 * Region : PBS Diffuse Model
 *
 ***************************************************************************************************/


inline half3 CalculateLambertDiffuse(float3 fresnel, float nDotL, float3 lightColor)
{
    return nDotL * lightColor * (1 - fresnel);
}


inline half3 CalculateHalfLambertDiffuse(float3 fresnel, float nDotL, float3 lightColor)
{
    float halfnDotL = nDotL * 0.5 + 0.5;
    return halfnDotL * lightColor  * (1 - fresnel);
}




/***************************************************************************************************
 *
 * Region : PBS Specular Model
 *
 ***************************************************************************************************/


///////////////////////////////////////////
// Blinn-Phong Model

inline half3 CalculateBlinnPhongBRDF(half perceptualRoughness, half nDotH)
{
    half shinness = max(1 - perceptualRoughness, 0.04);
    return shinness * pow(nDotH, 100 * shinness);
}

inline half3 CalculateBlinnPhongBRDF(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs)
{
    return CalculateBlinnPhongBRDF(surface.perceptualRoughness, dirs.nDotH);
}



///////////////////////////////////////////
// Unity 2015 SigGrash GGX Specular Model
// Slide 26

inline half3 CalculateUnity2015GGXBRDF(half perceptualRoughness, half roughenss, half nDotH, half lDotH)
{
    half r4 = roughenss * roughenss;

    half invD = (nDotH * r4 - nDotH) * nDotH + 1; // 2 mad, equals : nh^2 * (r4 - 1) + 1
    invD = invD * lDotH * 2;
    half halfinvD = 0.5 * invD;
    half invBRDF = (invD * perceptualRoughness + halfinvD) * invD + 0.001;
    return r4 / invBRDF;
}

inline half3 CalculateUnity2015GGXBRDF(float3 f0, PBSSurfaceParam surface, PBSDirections dirs)
{
    return f0 * CalculateUnity2015GGXBRDF(surface.perceptualRoughness, surface.roughness, dirs.nDotH, dirs.hDotL);
}



float SmithG1ForGGX(float ndots, float alpha)
{
    return 2.0 * ndots / (ndots * (2.0 - alpha) + alpha);
}

inline float GGXTerm(float NdotH, float roughness)
{
    float a2 = roughness * roughness;
    float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
    return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
                                            // therefore epsilon is smaller than what can be represented by half
}


///////////////////////////////////////////
// Reference : Unity 2018 BRDF1
// almost same as SmithG1
// much better than 2015

inline float3 CalculateUnity2018GGXBRDF(float3 fresnel, float roughness, float nDotL, float nDotV, float nDotH, float hDotL)
{
    float a4 = roughness * roughness;
    float invD = nDotH * nDotH * (a4 - 1) + 1;
    invD = max(0.001, invD * invD);
    //float d = a4 / invD;
    float d = GGXTerm(nDotH, roughness);

    float gv = SmithG1ForGGX(nDotV, roughness);
    float gl = SmithG1ForGGX(nDotL, roughness);
    float v  = gv * gl / max(0.001, 4 * nDotL * nDotV);

    // co-op with bloom
    return min(fresnel * d * v, 4);
}


inline float3 CalculateUnity2018GGXBRDF(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs)
{
    return CalculateUnity2018GGXBRDF(
        fresnel, surface.roughness,
        dirs.nDotL, dirs.nDotV, dirs.nDotH, dirs.hDotL);
}



/***************************************************************************************************
 *
 * Region : PBS IBL Model
 *
 ***************************************************************************************************/


// almost same as Unity_GlossyEnvironment
inline half3 GetIBLLight(float perceptualRoughness, float3 viewDir, float3 wNormal)
{
    half3 reflectDir = reflect(-viewDir, wNormal);
    half  mip        = HPerceptualRoughnessToMipmapLevel(perceptualRoughness) * 2;

    half4 IBLCol = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
    return HDecodeHDREnvironment(IBLCol, unity_SpecCube0_HDR);
}


inline half3 GetIBLLight(samplerCUBE specCubeSampler, float perceptualRoughness, float3 viewDir, float3 wNormal)
{
    half3 reflectDir = reflect(-viewDir, wNormal);
    half  mip = HPerceptualRoughnessToMipmapLevel(perceptualRoughness) * 2;

    half4 IBLCol = texCUBElod(specCubeSampler, float4(reflectDir, mip));
    return HDecodeHDREnvironment(IBLCol, float4(1, 1, 0, 0));
}




///////////////////////////////////////////
// Unreal IBL Model

inline half3 UnrealIBLBRDFApprox(half3 specular, half roughness, half nDotV)
{
    const half4 c0 = half4(   -1, -0.0275, -0.572,  0.022);
    const half4 c1 = half4(    1,  0.0425,  1.04,  -0.04);
    const half2 c2 = half2(-1.04,  1.04);

    half4 r     = roughness * c0 + c1;
    half  a004  = min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
    half2 AB    = c2 * a004 + r.zw;
    return specular * AB.x + AB.y;
}


half3 UnrealIBLApproximation(half3 specular, float perceptualRoughness, float roughness, float nDotV, float3 viewDir, float3 wNormal)
{
    half3 brdf = UnrealIBLBRDFApprox(specular, roughness, nDotV);
    half3 iblCol = GetIBLLight(perceptualRoughness, viewDir, wNormal);
    return brdf * iblCol;
}


half3 IBLApproximationOpt(half3 specular, float perceptualRoughness, float metallic, float nDotV, float3 viewDir, float3 wNormal)
{
    half3 iblCol = GetIBLLight(perceptualRoughness, viewDir, wNormal);
    return iblCol * nDotV * lerp(0.45, 1, metallic) * specular;
}


half3 UnrealIBLApproximation(PBSSurfaceParam surface, PBSDirections dirs)
{
    // return UnrealIBLApproximation(surface.specularColor, surface.perceptualRoughness, surface.roughness, dirs.nDotV, dirs.viewDir, dirs.normal);
    return IBLApproximationOpt(surface.specularColor, surface.perceptualRoughness, surface.metallic, dirs.nDotV, dirs.viewDir, dirs.normal);
}


half3 UnrealIBLApproximation(samplerCUBE specCubeSampler, PBSSurfaceParam surface, PBSDirections dirs)
{
    half3 brdf = UnrealIBLBRDFApprox(surface.specularColor, surface.roughness, dirs.nDotV);
    half3 iblCol = GetIBLLight(specCubeSampler, surface.perceptualRoughness, dirs.viewDir, dirs.normal);
    return brdf * iblCol;
}




///////////////////////////////////////////
// COD IBL Model
// don't know the proximation, only optimazation is not use exp2

half3 CodIBLBRDFApprox(half3 specular, half roughness, half metallic, half nDotV)
{
    half3 brdf   = lerp(0.45, 1, metallic) * specular * max(1 - roughness, 0.5);
    half  frenel = 1 - nDotV;
    frenel = max(frenel * frenel, 0.2);
    return 5 * brdf * frenel;
}


half3 CoDIBLApproximation(half3 specular, float perceptualRoughness, float roughness, half metallic, float nDotV, float3 viewDir, float3 wNormal)
{
    half3 brdf   = CodIBLBRDFApprox(specular, roughness, metallic, nDotV);
    half3 iblCol = GetIBLLight(perceptualRoughness, viewDir, wNormal).xyz;
    return brdf * iblCol;
}


half3 CoDIBLApproximation(samplerCUBE specCubeSampler, PBSSurfaceParam surface, PBSDirections dirs)
{
    half3 brdf   = CodIBLBRDFApprox(surface.specularColor, surface.roughness, surface.metallic, dirs.nDotV);
    half3 iblCol = GetIBLLight(specCubeSampler, surface.perceptualRoughness, dirs.viewDir, dirs.normal);
    return brdf * iblCol;
}




half3 CoDIBLApproximation(PBSSurfaceParam surface, PBSDirections dirs)
{
    // hack roughness to make it smaller
    return CoDIBLApproximation(surface.specularColor, surface.perceptualRoughness, surface.roughness, surface.metallic, dirs.nDotV, dirs.viewDir, dirs.normal);
}



#endif