#ifndef ULTRA_BAKE_INPUT_INCLUDED
#define ULTRA_BAKE_INPUT_INCLUDED
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterCoreRP/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/AutoTerainLitInput.hlsl"
uniform float4 _BakeScaleOffset;
uniform float4 _HeightMap_TexelSize;
uniform float4 _TerrainDimension;

TEXTURE2D(_HeightMap);
SAMPLER(sampler_HeightMap);
#endif
