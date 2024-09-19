#ifndef ULTRA_BAKE_PASSES_INCLUDED
#define ULTRA_BAKE_PASSES_INCLUDED

#define _BAKE_VARYING
struct BakeVaryings
{
	float4 uvMainAndLM				: TEXCOORD0;
	float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
	float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3
	float4 uvSplat45                : TEXCOORD3;
	float4 uvSplat67                : TEXCOORD4;
	float4 uvSplat89                : TEXCOORD5;
	float4 uvSplat1011                : TEXCOORD6;
	float4 uvSplat1213                : TEXCOORD7;
	float4 uvSplat1415                : TEXCOORD8;
	float4 vertex : SV_POSITION;
};

#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/AutoTerainLitPasses.hlsl"
#include "../../../ShaderLibrary/TerrainLitUtils.hlsl"

struct BakeAttributes
{
	float4 positionOS       : POSITION;
	float2 texcoord               : TEXCOORD0;
};

BakeVaryings vert(BakeAttributes v)
{
	BakeVaryings o = (BakeVaryings)0;
	o.uvMainAndLM.zw = v.texcoord;
	v.texcoord.xy = v.texcoord.xy * _BakeScaleOffset.xy + _BakeScaleOffset.zw;

	VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
	o.vertex = vertexInput.positionCS;
	o.uvMainAndLM.xy = v.texcoord;
	TransformLayerUV(v.texcoord, o);
	return o;
}

void InitializeFragmentNormal(in float2 uv, inout float3 normal) {
	float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
	float u1 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv - du);
	float u2 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv + du);
	float3 tu = float3(_HeightMap_TexelSize.x * _TerrainDimension.x, (u2 - u1) * _TerrainDimension.y, 0);

	float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
	float v1 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv - dv);
	float v2 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv + dv);
	float3 tv = float3(0, (v2 - v1) * _TerrainDimension.y, _HeightMap_TexelSize.y * _TerrainDimension.z);

	normal = cross(tv, tu);
	normal = normalize(normal);
}

#ifdef _TERRAIN_BLEND_TRIPLANAR
void Bake(BakeVaryings IN, in float4 uvTriplanar, in float3 normal
#else
void Bake(BakeVaryings IN
#endif
	, inout half4 mixedDiffuse, inout half3 normalTS, inout half metallic, inout half occlusion, inout half smoothness, inout half4 splatControl[4], inout half4 masks[4][4], inout half4 hasMask[4])
{
	mixedDiffuse = 0;
	normalTS = 0;
	metallic = 0;
    smoothness = 0;
	occlusion = 0;
	#ifdef _TERRAIN_BLEND_TRIPLANAR
    	GetTerrainPBRInfo(IN, uvTriplanar, normal
	#else
    	GetTerrainPBRInfo(IN
	#endif
	, mixedDiffuse, normalTS, metallic, smoothness, occlusion, splatControl, masks, hasMask);
}

void GetParameters(BakeVaryings IN, inout half4 mixedDiffuse, inout half3 normalTS, inout half metallic, inout half smoothness, inout half occlusion){
   
    half4 splatControl[4];
    half4 masks[4][4];
    half4 hasMask[4];
	FetchSplat(IN, splatControl, masks, hasMask);

#ifdef _TERRAIN_BLEND_TRIPLANAR
	float heightFactor = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, IN.uvMainAndLM.xy).r;
	float3 positionOS = float3(_TerrainDimension.xy * IN.uvMainAndLM.xy, _TerrainDimension.z * heightFactor);
	float4 uvTriplanar = 0;
	uvTriplanar.xy = float2(positionOS.x * _TriplanarScale.x, positionOS.y * _TriplanarScale.y) * 0.01;
	uvTriplanar.zw = float2(positionOS.z * _TriplanarScale.z, 0) * 0.01;
	float3 normal = 0;
	InitializeFragmentNormal(IN.uvMainAndLM.xy, normal);
#endif

	mixedDiffuse = 0;
	smoothness = 0;
	normalTS = 0;
	metallic = 0;
	occlusion = 0;

#ifdef _TERRAIN_BLEND_TRIPLANAR
	Bake(IN, uvTriplanar, normal
#else
	Bake(IN
#endif
	, mixedDiffuse, normalTS, metallic, occlusion, smoothness, splatControl, masks, hasMask);
}

half4 BakeDiffuseFragment(BakeVaryings IN) : SV_Target
{
	half4 mixedDiffuse = 0;
	half smoothness = 0;
	half3 normalTS = 0;
	half metallic = 0;
	half occlusion = 0;
	GetParameters(IN, mixedDiffuse, normalTS, metallic, smoothness, occlusion);
	return half4(mixedDiffuse.rgb, smoothness);
}

half4 BakeNormalFragment(BakeVaryings IN) : SV_Target
{
	half4 mixedDiffuse = 0;
	half smoothness = 0;
	half3 normalTS = 0;
	half metallic = 0;
	half occlusion = 0;
	GetParameters(IN, mixedDiffuse, normalTS, metallic, smoothness, occlusion);

#if HAS_HALF
	normalTS.z += 0.01h;
#else
	normalTS.z += 1e-5f;
#endif
	normalTS = normalize(normalTS);
	normalTS = (normalTS.xyz + 1.0) * 0.5;
	return half4(normalTS.rg, occlusion, metallic);
}

#endif
