Shader "TerrainSystem/HRP/Terrain/UltraLit"
{
    Properties
    {
		[Toggle(_TERRAIN_BLEND_HEIGHT)] _EnableHeightBlend("EnableHeightBlend", Float) = 0.0
		[ShowProperty(_TERRAIN_BLEND_HEIGHT)] _HeightTransition("Height Transition", Range(0, 1.0)) = 0.0

		[Toggle(_TERRAIN_BLEND_TRIPLANAR)] _EnableTriplanarBlend("EnableTriplanarBlend", Float) = 0.0
		[ShowProperty(_TERRAIN_BLEND_TRIPLANAR)] _TriplanarScale("Triplanar Scale", Vector) = (1,1,1,0)
        
		[Toggle(_TERRAIN_ANTI_TILING)] _EnableAntiTiling("EnableAntiTiling", Float) = 0.0
		
		[Toggle] _EnableInstancedPerPixelNormal("Enable Instanced per-pixel normal", Float) = 1.0
        // used in fallback on old cards & base map
        [HideInInspector] _MainTex("BaseMap (RGB)", 2D) = "grey" {}
        [HideInInspector] _BaseColor("Main Color", Color) = (1,1,1,1)
        [HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}

		[HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Control1("Control1 (RGBA)", 2D) = "black" {}
		[HideInInspector] _Control2("Control2 (RGBA)", 2D) = "black" {}
		[HideInInspector] _Control3("Control3 (RGBA)", 2D) = "black" {}

	}

    HLSLINCLUDE
    #pragma multi_compile __ _ALPHATEST_ON
	//#pragma shader_feature_local _TERRAIN_8_LAYERS
	#define SHADER_LIB_VERSION 2019
    ENDHLSL

    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "False" "SplatCount" = "16"}

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 4.5

            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

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
			#pragma shader_feature_local _TERRAIN_BLEND_TRIPLANAR
			#pragma shader_feature_local _TERRAIN_ANTI_TILING
			#pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _MASKMAP            
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL

			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitInput_Auto.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitPasses_Auto.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitInput_Auto.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitPasses_Auto.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitInput_Auto.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitPasses_Auto.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #define SCENESELECTIONPASS
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitInput_Auto.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitPasses_Auto.hlsl"


            ENDHLSL
        }

        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
    }
    Dependency "AddPassShader" = "Hidden/TerrainSystem/HRP/Terrain/Lit (Add Pass)"
    Dependency "BaseMapShader" = "Hidden/TerrainSystem/HRP/Terrain/Lit (Base Pass)"
    Dependency "BaseMapGenShader" = "Hidden/TerrainSystem/HRP/Terrain/Lit (Basemap Gen)"
    
    //CustomEditor "UnityEditor.Rendering.Universal.TerrainLitShaderGUI"

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
