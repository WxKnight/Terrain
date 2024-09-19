Shader "TerrainSystem/HRP/TerrainLitAtlasSplatmap_4Layer" 
{
	Properties{
		[NoScaleOffset]_Control("Control", 2D) = "blue" {}
		[NoScaleOffset]_Weight("", 2D) = "white" {}
		[NoScaleOffset]_Splat0("DiffuseAtlas (Albedo: RGB, Roughness: A)", 2D) = "white" {}
		[NoScaleOffset]_Normal0("NormalAtlas", 2D) = "bump" {}
		_ScaleFactor("X:Vertical Factor, Y:Mipmap Bias", Vector) = (0.25, -0.5, 0, 0)
	}
	HLSLINCLUDE
	#pragma multi_compile __ _ALPHATEST_ON
	#define SHADER_LIB_VERSION 2019
	ENDHLSL

	SubShader
	{
		Tags { "Queue" = "Geometry-1" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "False"}

		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward" }
			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 3.0

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

			//#pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
			#pragma multi_compile_local _ _NORMALMAP
			#pragma shader_feature_local _MASKMAP            
			// Sample normal in pixel shader when doing instancing
			#pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL

			#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterCoreRP/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterCoreRP/ShaderLibrary/Packing.hlsl"
			#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/SurfaceInput.hlsl"
			#define _Surface 0.0 // Terrain is always opaque
#define _NORMALMAP

			CBUFFER_START(UnityPerMaterial)
				float4 _Control_TexelSize;
				half4 _ScaleFactor;
			CBUFFER_END

			TEXTURE2D(_Control);    SAMPLER(sampler_Control);
			TEXTURE2D(_Weight);    SAMPLER(sampler_Weight);
			TEXTURE2D(_Splat0);
			#ifdef _NORMALMAP
			TEXTURE2D(_Normal0);	SAMPLER(sampler_Normal0);
			#endif
			uniform half4 _TilingScales[16];


			#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Lighting.hlsl"

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
			};

			struct Varyings
			{
				float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap

			#if defined(_NORMALMAP)
				half4 normal                   : TEXCOORD3;    // xyz: normal, w: viewDir.x
				half4 tangent                  : TEXCOORD4;    // xyz: tangent, w: viewDir.y
				half4 bitangent                : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
			#else
				half3 normal                   : TEXCOORD3;
				half3 viewDir                  : TEXCOORD4;
				half3 vertexSH                  : TEXCOORD5; // SH
			#endif

				half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
				float3 positionWS               : TEXCOORD7;
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord              : TEXCOORD8;
			#endif
				float4 clipPos                  : SV_POSITION;
			};

			#ifdef _ALPHATEST_ON
			TEXTURE2D(_TerrainHolesTexture);
			SAMPLER(sampler_TerrainHolesTexture);

			void ClipHoles(float2 uv)
			{
				float hole = SAMPLE_TEXTURE2D(_TerrainHolesTexture, sampler_TerrainHolesTexture, uv).r;
				clip(hole == 0.0f ? -1 : 1);
			}
			#endif

			void InitializeInputData(Varyings IN, half3 normalTS, out InputData input)
			{
				input = (InputData)0;
				input.positionWS = IN.positionWS;
				half3 SH = half3(0, 0, 0);

			#if defined(_NORMALMAP)
				half3 viewDirWS = half3(IN.normal.w, IN.tangent.w, IN.bitangent.w);
				input.normalWS = TransformTangentToWorld(normalTS, half3x3(-IN.tangent.xyz, IN.bitangent.xyz, IN.normal.xyz));
				SH = SampleSH(input.normalWS.xyz);
			#else
				half3 viewDirWS = IN.viewDir;
				input.normalWS = IN.normal;
				SH = IN.vertexSH;
			#endif

				input.normalWS = NormalizeNormalPerPixel(input.normalWS);
				input.viewDirectionWS = viewDirWS;

			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				input.shadowCoord = IN.shadowCoord;
			#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
				input.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
			#else
				input.shadowCoord = float4(0, 0, 0, 0);
			#endif

				input.fogCoord = IN.fogFactorAndVertexLight.x;
				input.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				//NOTE SAMPLE_GI �����SampleSHPixel������������������⣬�ֻ���ʹ�õ���EVALUATE_SH_MIXED��
				//pcʹ�õ���EVALUATE_SH_VERTEX
				#if defined(LIGHTMAP_ON)
				input.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, SH, input.normalWS);
				#else
				input.bakedGI = SH;
				#endif
			}

			void SplatmapMix(in half4 uvSplat01, in half4 uvSplat23, inout half4 splatControl, out half4 mixedDiffuse, out half4 defaultSmoothness, inout half3 mixedNormal)
			{
				half4 diffAlbedo[4];

				diffAlbedo[0] = SAMPLE_TEXTURE2D_BIAS(_Splat0, sampler_Control, uvSplat01.xy, _ScaleFactor.y);
				diffAlbedo[1] = SAMPLE_TEXTURE2D_BIAS(_Splat0, sampler_Control, uvSplat01.zw, _ScaleFactor.y);
				diffAlbedo[2] = SAMPLE_TEXTURE2D_BIAS(_Splat0, sampler_Control, uvSplat23.xy, _ScaleFactor.y);
				diffAlbedo[3] = SAMPLE_TEXTURE2D_BIAS(_Splat0, sampler_Control, uvSplat23.zw, _ScaleFactor.y);

				defaultSmoothness = half4(1.0h, 1.0h, 1.0h, 1.0h) - half4(diffAlbedo[0].a, diffAlbedo[1].a, diffAlbedo[2].a, diffAlbedo[3].a);

				mixedDiffuse = 0.0h;
				mixedDiffuse += diffAlbedo[0] * half4(splatControl.rrr, 1.0h);
				mixedDiffuse += diffAlbedo[1] * half4(splatControl.ggg, 1.0h);
				mixedDiffuse += diffAlbedo[2] * half4(splatControl.bbb, 1.0h);
				mixedDiffuse += diffAlbedo[3] * half4(splatControl.aaa, 1.0h);

			#ifdef _NORMALMAP
				half3 nrm = 0.0f;
				nrm += splatControl.r * UnpackNormalRGBNoScale(SAMPLE_TEXTURE2D_BIAS(_Normal0, sampler_Normal0, uvSplat01.xy, _ScaleFactor.y)).yxz;
				nrm += splatControl.g * UnpackNormalRGBNoScale(SAMPLE_TEXTURE2D_BIAS(_Normal0, sampler_Normal0, uvSplat01.zw, _ScaleFactor.y)).yxz;
				nrm += splatControl.b * UnpackNormalRGBNoScale(SAMPLE_TEXTURE2D_BIAS(_Normal0, sampler_Normal0, uvSplat23.xy, _ScaleFactor.y)).yxz;
				nrm += splatControl.a * UnpackNormalRGBNoScale(SAMPLE_TEXTURE2D_BIAS(_Normal0, sampler_Normal0, uvSplat23.zw, _ScaleFactor.y)).yxz;
				// avoid risk of NaN when normalizing.
			#if HAS_HALF
				nrm.z += 0.01h;
			#else
				nrm.z += 1e-5f;
			#endif

				mixedNormal = normalize(nrm.xyz);
			#endif
			}

			///////////////////////////////////////////////////////////////////////////////
			//                  Vertex and Fragment functions                            //
			///////////////////////////////////////////////////////////////////////////////

			// Used in Standard Terrain shader
			Varyings SplatmapVert(Attributes v)
			{
				Varyings o = (Varyings)0;

				VertexPositionInputs Attributes = GetVertexPositionInputs(v.positionOS.xyz);

				o.uvMainAndLM.xy = v.texcoord;
				o.uvMainAndLM.zw = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;

				half3 viewDirWS = GetCameraPositionWS() - Attributes.positionWS;
				viewDirWS = SafeNormalize(viewDirWS);

			#if defined(_NORMALMAP)
				float4 vertexTangent = float4(cross(float3(0, 0, 1), v.normalOS), 1.0);
				VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, vertexTangent);

				o.normal = half4(normalInput.normalWS, viewDirWS.x);
				o.tangent = half4(normalInput.tangentWS, viewDirWS.y);
				o.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);
			#else
				o.normal = TransformObjectToWorldNormal(v.normalOS);
				o.viewDir = viewDirWS;
				o.vertexSH = SampleSH(o.normal);
			#endif
				o.fogFactorAndVertexLight.x = ComputeFogFactor(Attributes.positionCS.z);
				o.fogFactorAndVertexLight.yzw = VertexLighting(Attributes.positionWS, o.normal.xyz);
				o.positionWS = Attributes.positionWS;
				o.clipPos = Attributes.positionCS;

			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				o.shadowCoord = GetShadowCoord(Attributes);
			#endif
				return o;
			}

			// Used in Standard Terrain shader
			half4 SplatmapFragment(Varyings IN) : SV_TARGET
			{
			#ifdef _ALPHATEST_ON
				ClipHoles(IN.uvMainAndLM.xy);
			#endif

				half3 normalTS = half3(0.0h, 0.0h, 1.0h);
	
				half4 mixedDiffuse = 0.0h;
				half4 defaultSmoothness = 0.0h;
				float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
				
				uint4 controlVec = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV) * 15.0;
				
				uint4 offset = uint4(controlVec.x & 0x3, controlVec.x >> 2, controlVec.y & 0x3, controlVec.y >> 2);
				half4 uvSplat01 = 0;
				half4 uvSplat23 = 0;
				uint4 offset2 = uint4(controlVec.z & 0x3, controlVec.z >> 2, controlVec.w & 0x3, controlVec.w >> 2);

				uvSplat01.xy = (frac(splatUV * half2(_TilingScales[controlVec.x].x, _TilingScales[controlVec.x].y)) + offset.xy) * half2(0.25, _ScaleFactor.x);
				uvSplat01.zw = (frac(splatUV * half2(_TilingScales[controlVec.y].x, _TilingScales[controlVec.y].y)) + offset.zw) * half2(0.25, _ScaleFactor.x);
				uvSplat23.xy = (frac(splatUV * half2(_TilingScales[controlVec.z].x, _TilingScales[controlVec.z].y)) + offset2.xy) * half2(0.25, _ScaleFactor.x);
				uvSplat23.zw = (frac(splatUV * half2(_TilingScales[controlVec.w].x, _TilingScales[controlVec.w].y)) + offset2.zw) * half2(0.25, _ScaleFactor.x);

				//*****************************************************************
				half4 splatControl = SAMPLE_TEXTURE2D(_Weight, sampler_Weight, splatUV).xyzw;

				SplatmapMix(uvSplat01, uvSplat23, splatControl, mixedDiffuse, defaultSmoothness, normalTS);
				half3 albedo = mixedDiffuse.rgb;

				half3 defaultMetallic = half3(/*_Metallic0*/ 0.0h, /*_Metallic1*/ 0.0h, 0.0h);
				half3 defaultOcclusion = 1.0h;

				half smoothness = dot(splatControl, defaultSmoothness);
				half metallic = dot(splatControl, defaultMetallic);
				half occlusion = dot(splatControl, defaultOcclusion);

				InputData inputData;
				InitializeInputData(IN, normalTS, inputData);
				//half4 color = UniversalFragmentPBR(inputData, albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, occlusion, /* emission */  half3(0.0h, 0.0h, 0.0h), /* alpha */ 1.0h);
				half4 color = UniversalFragmentBlinnPhong(inputData, albedo, _MainLightColor, smoothness, /* emission */  half3(0.0h, 0.0h, 0.0h), /* alpha */ 1.0h);
				//color.rgb *= color.a;
				color.rgb = MixFog(color.rgb, inputData.fogCoord);

				return half4(color.rgb, 1.0h);
			}
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

			#include "TerrainLitSplatmapInput.hlsl"
			#include "TerrainLitSplatmapPasses.hlsl"
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

			#include "TerrainLitSplatmapInput.hlsl"
			#include "TerrainLitSplatmapPasses.hlsl"
			ENDHLSL
		}
	}
	Fallback "Hidden/Universal Render Pipeline/FallbackError"
}