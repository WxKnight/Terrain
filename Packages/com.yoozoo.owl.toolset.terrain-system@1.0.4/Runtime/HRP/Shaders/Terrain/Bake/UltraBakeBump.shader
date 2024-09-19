Shader "TerrainSystem/HRP/Conversion/UltraBakeBump"
{
	HLSLINCLUDE
	#define SHADER_LIB_VERSION 2019
	ENDHLSL

	SubShader
	{
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always ZWrite Off Cull Off
		Pass
		{
			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 4.5

			#pragma vertex vert
			#pragma fragment BakeNormalFragment

			#pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
			#pragma shader_feature_local _TERRAIN_BLEND_TRIPLANAR
			#pragma shader_feature_local _TERRAIN_ANTI_TILING

			#define _NORMALMAP
			#define _MASKMAP

			#include "UltraBakeInput.hlsl"
			#include "UltraBakePasses.hlsl"
			ENDHLSL
		}
	}
}
