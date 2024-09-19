#ifndef TERRAIN_SYSTEM_TERRAIN_LIGHTING_INCLUDED
#define TERRAIN_SYSTEM_TERRAIN_LIGHTING_INCLUDED

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterHRP/RenderPipeline/ShaderLibrary/HPipelineData.hlsl"
V2F_BEGEIN
DATA_TtoW_WPos(3)
V2F_END
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterHRP/RenderPipeline/Shaders/Pipeline/BFP/Core/BFP_Core.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterHRP/RenderPipeline/ShaderLibrary/HLighting.hlsl"

// We either sample GI from baked lightmap or from probes.
// If lightmap: sampleData.xy = lightmapUV
// If probe: sampleData.xyz = L2 SH terms
#undef SAMPLE_GI
#ifdef LIGHTMAP_ON
#define SAMPLE_GI(lmName, shName, normalWSName) SampleLightmapAHD(lmName, normalWSName)
#else
#define SAMPLE_GI(lmName, shName, normalWSName) SampleSHPixel(shName, normalWSName)
#endif


// Sample baked lightmap. Non-Direction and Directional if available.
// Realtime GI is not supported.
half3 SampleLightmapAHD(float2 lightmapUV, half3 normalWS)
{
	AHDLightInfo lightInfo = BFP_LightmapToAHD(lightmapUV, normalWS);

	return lightInfo.directionalLightCol + lightInfo.ambientLightCol;
}
#endif
