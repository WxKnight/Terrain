#ifndef TERRAIN_SYSTEM_HRP_TERRAIN_LIT_UTILS_INCLUDED
#define TERRAIN_SYSTEM_HRP_TERRAIN_LIT_UTILS_INCLUDED

#ifdef _BAKE_VARYING
#ifdef _TERRAIN_BLEND_TRIPLANAR
void GetTerrainPBRInfo(BakeVaryings IN, float4 uvTriplanar, float3 normal
#else
void GetTerrainPBRInfo(BakeVaryings IN
#endif
#else
void GetTerrainPBRInfo(Varyings IN
#endif
    , inout half4 mixedDiffuse, inout half3 normalTS, inout half metallic, inout half smoothness, inout half occlusion, half4 splatControl[4], half4 masks[4][4], half4 hasMask[4]){
#ifdef _NORMALMAP
	normalTS = 0;
#else
	normalTS = half3(0.0h, 0.0h, 1.0h);
#endif

	mixedDiffuse = 0;
	half4 defaultSmoothness0 = 0;
	half4 defaultSmoothness1 = 0;
	half4 defaultSmoothness2 = 0;
	half4 defaultSmoothness3 = 0;
#ifdef _TERRAIN_BLEND_TRIPLANAR
	#ifdef _BAKE_VARYING
		SplatmapMix0Triplanar(uvTriplanar, normal, IN.uvSplat01, IN.uvSplat23, splatControl[0], mixedDiffuse, normalTS, defaultSmoothness0);
		SplatmapMix1Triplanar(uvTriplanar, normal, IN.uvSplat45, IN.uvSplat67, splatControl[1], mixedDiffuse, normalTS, defaultSmoothness1);
		SplatmapMix2Triplanar(uvTriplanar, normal, IN.uvSplat89, IN.uvSplat1011, splatControl[2], mixedDiffuse, normalTS, defaultSmoothness2);
		SplatmapMix3Triplanar(uvTriplanar, normal, IN.uvSplat1213, IN.uvSplat1415, splatControl[3], mixedDiffuse, normalTS, defaultSmoothness3);
	#else
		SplatmapMix0Triplanar(IN.uvTriplanar, IN.normal, IN.uvSplat01, IN.uvSplat23, splatControl[0], mixedDiffuse, normalTS, defaultSmoothness0);
		SplatmapMix1Triplanar(IN.uvTriplanar, IN.normal, IN.uvSplat45, IN.uvSplat67, splatControl[1], mixedDiffuse, normalTS, defaultSmoothness1);
		SplatmapMix2Triplanar(IN.uvTriplanar, IN.normal, IN.uvSplat89, IN.uvSplat1011, splatControl[2], mixedDiffuse, normalTS, defaultSmoothness2);
		SplatmapMix3Triplanar(IN.uvTriplanar, IN.normal, IN.uvSplat1213, IN.uvSplat1415, splatControl[3], mixedDiffuse, normalTS, defaultSmoothness3);
	#endif
#else
	SplatmapMix0(IN.uvSplat01, IN.uvSplat23, splatControl[0], mixedDiffuse, normalTS, defaultSmoothness0);
	SplatmapMix1(IN.uvSplat45, IN.uvSplat67, splatControl[1], mixedDiffuse, normalTS, defaultSmoothness1);
	SplatmapMix2(IN.uvSplat89, IN.uvSplat1011, splatControl[2], mixedDiffuse, normalTS, defaultSmoothness2);
	SplatmapMix3(IN.uvSplat1213, IN.uvSplat1415, splatControl[3], mixedDiffuse, normalTS, defaultSmoothness3);
#endif

#ifdef _NORMALMAP
	// avoid risk of NaN when normalizing.
#if HAS_HALF
	normalTS.z += 0.01h;
#else
	normalTS.z += 1e-5f;
#endif
	normalTS = normalize(normalTS);
#endif

	//**
	metallic = 0;
	occlusion = 0;
    smoothness = 0;
	FetchMOS0(metallic, occlusion, smoothness, defaultSmoothness0, splatControl[0], hasMask[0], masks[0]);
	FetchMOS1(metallic, occlusion, smoothness, defaultSmoothness1, splatControl[1], hasMask[1], masks[1]);
	FetchMOS2(metallic, occlusion, smoothness, defaultSmoothness2, splatControl[2], hasMask[2], masks[2]);
	FetchMOS3(metallic, occlusion, smoothness, defaultSmoothness3, splatControl[3], hasMask[3], masks[3]);
}
#endif