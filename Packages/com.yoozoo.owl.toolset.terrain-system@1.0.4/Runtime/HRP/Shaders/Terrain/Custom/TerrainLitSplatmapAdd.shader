﻿Shader "TerrainSystem/HRP/TerrainLitSplatmapAdd" 
{
	Properties{
		 _Control("Control (RGBA)", 2D) = "red" {}
		 _Splat3("Layer 3 (A)", 2D) = "white" {}
		 _Splat2("Layer 2 (B)", 2D) = "white" {}
		 _Splat1("Layer 1 (G)", 2D) = "white" {}
		 _Splat0("Layer 0 (R)", 2D) = "white" {}
		 _Normal3("Normal 3 (A)", 2D) = "bump" {}
		 _Normal2("Normal 2 (B)", 2D) = "bump" {}
		 _Normal1("Normal 1 (G)", 2D) = "bump" {}
		 _Normal0("Normal 0 (R)", 2D) = "bump" {}
		[HideInInspector][Gamma] _Metallic0("Metallic 0", Range(0.0, 1.0)) = 0.0
		[HideInInspector][Gamma] _Metallic1("Metallic 1", Range(0.0, 1.0)) = 0.0
		[HideInInspector][Gamma] _Metallic2("Metallic 2", Range(0.0, 1.0)) = 0.0
		[HideInInspector][Gamma] _Metallic3("Metallic 3", Range(0.0, 1.0)) = 0.0
		_Mask3("Mask 3 (A)", 2D) = "grey" {}
		_Mask2("Mask 2 (B)", 2D) = "grey" {}
		_Mask1("Mask 1 (G)", 2D) = "grey" {}
		_Mask0("Mask 0 (R)", 2D) = "grey" {}
		[HideInInspector] _Smoothness0("Smoothness 0", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness1("Smoothness 1", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness2("Smoothness 2", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness3("Smoothness 3", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _NormalScale0("NormalScale 0", Range(0.0, 16.0)) = 1.0
		[HideInInspector] _NormalScale1("NormalScale 1", Range(0.0, 16.0)) = 1.0
		[HideInInspector] _NormalScale2("NormalScale 2", Range(0.0, 16.0)) = 1.0
		[HideInInspector] _NormalScale3("NormalScale 3", Range(0.0, 16.0)) = 1.0
		[HideInInspector] _LayerHasMask0("Layer Has Mask 0", Float) = 0.0
		[HideInInspector] _LayerHasMask1("Layer Has Mask 1", Float) = 0.0
		[HideInInspector] _LayerHasMask2("Layer Has Mask 2", Float) = 0.0
		[HideInInspector] _LayerHasMask3("Layer Has Mask 3", Float) = 0.0
	}
	HLSLINCLUDE
	#pragma multi_compile __ _ALPHATEST_ON
	#define SHADER_LIB_VERSION 2019
	ENDHLSL

	SubShader
	{
		Tags { "Queue" = "Geometry-99" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

		Pass
		{
			Name "TerrainAddLit"
			Tags { "LightMode" = "UniversalForward" }
			Blend One One
			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 3.0

			#pragma vertex SplatmapVert
			#pragma fragment SplatmapFragment

			// -------------------------------------
			// Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

			#pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _MASKMAP    
			// Sample normal in pixel shader when doing instancing
			#pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL            
			#define TERRAIN_SPLAT_ADDPASS

			#include "TerrainLitSplatmapInput.hlsl"
			#include "TerrainLitSplatmapPasses.hlsl"
			ENDHLSL
		}
	}
	Fallback "Hidden/Universal Render Pipeline/FallbackError"
}