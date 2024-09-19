/***************************************************************************************************
*
* 反射探针相关代码
* 
* 算法      Local Cubemap算法，基于位置的混合
*
*
* 额外参数的意义说明
* unity_SpecCube0_BoxMax;				ReflectionProbe0的box的最大位置
* unity_SpecCube0_BoxMin;				ReflectionProbe0的box的最小位置
* unity_SpecCube0_ProbePosition			ReflectionProbe0的box的中心
* unity_SpecCube1_BoxMax;				ReflectionProbe1的box的最大位置
* unity_SpecCube1_BoxMin;				ReflectionProbe1的box的最小位置
* unity_SpecCube1_ProbePosition;	    ReflectionProbe1的box的中心
* unity_SpecCube1_HDR;					ReflectionProbe1的HDR参数
* 
* 原始方法出自 UnityGlobalIllumination.cginc
* 用法      
* BoxProjectedCubemapDirection()  传入反射方向，世界位置，ReflectionProbe的box的中心和边界,计算基于box的反射方向
* GetWaterBlendIBLLight()	计算复杂的ReflectionProbe光照
***************************************************************************************************/

#ifndef HRP_REFLECTION_PROBE_INCLUDED
#define HRP_REFLECTION_PROBE_INCLUDED

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/UnityInput.hlsl"

//float4 unity_SpecCube0_BoxMax;		
//float4 unity_SpecCube0_BoxMin;		
//float4 unity_SpecCube0_ProbePosition;
//float4 unity_SpecCube1_BoxMax;		
//float4 unity_SpecCube1_BoxMin;		
//float4 unity_SpecCube1_ProbePosition;
//half4  unity_SpecCube1_HDR;

CBUFFER_START(UnityReflectionProbes)
float4 unity_SpecCube0_BoxMax;
float4 unity_SpecCube0_BoxMin;
float4 unity_SpecCube0_ProbePosition;

float4 unity_SpecCube1_BoxMax;
float4 unity_SpecCube1_BoxMin;
float4 unity_SpecCube1_ProbePosition;
half4 unity_SpecCube1_HDR;
CBUFFER_END


struct ReflectionProbeData
{
    float4 probePosition[2];
    half SphereRadius[2];

    float4 boxMin[2];
    float4 boxMax[2];
    float4x4 boxRotation;
};


// for fs
half3 BoxProjectedCubemapDirection (half3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{	
    if (cubemapCenter.w > 0.0)
    {
        half3 nrdir = normalize(worldRefl);

        half3 rbmax = (boxMax.xyz - worldPos) / nrdir;
        half3 rbmin = (boxMin.xyz - worldPos) / nrdir;

        half3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;

        half fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

        worldPos -= cubemapCenter.xyz;
        worldRefl = worldPos + nrdir * fa;
    }

    return worldRefl;
}

half3 GetBoxProjectedIBLLight(ReflectionProbeData data, float3 worldPos, float perceptualRoughness, float3 viewDir, float3 wNormal)
{
    //旋转
    float3 orgViewDir = viewDir;
    viewDir = mul(data.boxRotation, orgViewDir);
    
    //映射到box空间旋转一下
    float3 orgWorldPos = worldPos;
    worldPos = mul(data.boxRotation, (orgWorldPos - data.probePosition[0])) + data.probePosition[0];
    
    half3 reflectDir = reflect(-viewDir, wNormal);

    half3 originalReflUVW = reflectDir;
    reflectDir = BoxProjectedCubemapDirection(originalReflUVW, worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);

    half  mip = HPerceptualRoughnessToMipmapLevel(perceptualRoughness) * 2;

    half4 IBLCol = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);  
    half3 env = HDecodeHDREnvironment(IBLCol, unity_SpecCube0_HDR);
    return env;
}

half3 GetSphereProjectedReflectionProbe(ReflectionProbeData data, float3 worldPos, float perceptualRoughness, float3 viewDir, float3 wNormal)
{
    float4 probePos = float4(data.probePosition[0].xyz, 1);

    //旋转
    float4 orgViewDir = float4(viewDir, 0);
    viewDir = mul(data.boxRotation, orgViewDir).rgb;
    //映射到box空间旋转一下
    float4 orgWorldPos = float4(worldPos, 1);
    worldPos = (mul(data.boxRotation, (orgWorldPos - probePos)) + probePos).rgb;
    
    half3 reflectDir = reflect(-viewDir, wNormal);

    half  mip = HPerceptualRoughnessToMipmapLevel(perceptualRoughness) * 2;

    // Capture offset
    float3 C =  worldPos - probePos.xyz;
    // ReflectDir by radius
    half3 RR = reflectDir * data.SphereRadius[0];
    // Diffuse Light intensity
    half intensity = dot(RR, C) * 2.0;
    // ReflectDir by radius_dot2
    half RR_dot2 = dot(RR, RR);

    float3 texcoordSphere = (sqrt(max(0.0, pow(intensity, 2) - (dot(C, C) - pow(1.2 * data.SphereRadius[0], 2)) *
                            (RR_dot2 * 4.0) )) - intensity) * RR *(0.5/(RR_dot2 + 0.000001)) + C;
    half3 env = 0;

    half4 IBLCol = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, texcoordSphere, mip);
    env = HDecodeHDREnvironment(IBLCol, unity_SpecCube0_HDR);

    return env;
}

// for fs
half3 GetWaterBlendIBLLight(ReflectionProbeData data, float3 worldPos,float roughness, float3 viewDir, float3 wNormal, int isBlend)
{
	half3 specular = 0;

    half3 reflectDir = reflect(-viewDir, wNormal);

	#ifdef TA_SPECCUBE_BOX_PROJECTION
		half3 originalReflUVW = reflectDir;
		reflectDir = BoxProjectedCubemapDirection (originalReflUVW, worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
	#endif

    half  mip  = HPerceptualRoughnessToMipmapLevel(roughness) * 2;

    half4 IBLCol0 = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
    half3 env0 = HDecodeHDREnvironment(IBLCol0, unity_SpecCube0_HDR);

	//#ifdef TA_SPECCUBE_BLENDING
 //       if (isBlend == 1)
 //       {
	//	    //const float kBlendFactor = 0.99999;
	//	    //float blendLerp = data.boxMin[0].w;

	//	    //float blendLerp = length(_WorldSpaceCameraPos.xz - data.probePosition[0].xz) < length(_WorldSpaceCameraPos.xz - data.probePosition[1].xz)?1:0;

	//	    float blendLerp = saturate(length(_WorldSpaceCameraPos.xz - data.probePosition[1].xz) / length(_WorldSpaceCameraPos.xz - data.probePosition[0].xz));

	//	    #ifdef TA_SPECCUBE_BOX_PROJECTION
	//		    reflectDir = BoxProjectedCubemapDirection (originalReflUVW, worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
	//	    #endif

	//	    half4 IBLCol1 = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube1, samplerunity_SpecCube1, reflectDir, mip);
	//	    half3 env1 =  HDecodeHDREnvironment(IBLCol1, unity_SpecCube1_HDR);
	//	    specular = lerp(env1, env0, blendLerp);
 //       }
 //       else 
 //           specular = env0;
	//#else

		specular = env0;
	//#endif

	return specular;

}


#endif
