#ifndef HRP_BFP_META_FOR_PACKMAPS_INCLUDED
#define HRP_BFP_META_FOR_PACKMAPS_INCLUDED

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/MetaInput.hlsl"
#include "../../../../ShaderLibrary/HTextureUtils.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _Color;
float4 _DiffuseTex_ST;
CBUFFER_END

TEXTURE2D(_DiffuseTex);
SAMPLER(sampler_DiffuseTex);
TEXTURE2D(_NormalTex);    
SAMPLER(sampler_NormalTex);

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
#ifdef _TANGENT_TO_WORLD
    float4 tangentOS     : TANGENT;
#endif
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
};

Varyings vert_meta(Attributes input)
{
    Varyings output;
    output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2,
        unity_LightmapST, unity_DynamicLightmapST);
    output.uv = TRANSFORM_TEX(input.uv0, _DiffuseTex);
    return output;
}

float4 frag_meta(Varyings input) : SV_Target
{
    MetaInput metaInput = (MetaInput) 0;
    
    float4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, input.uv);
    float4 gloss = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, input.uv);
    float metallic = gloss.w;
    float3 specularCol = GammaToLinearSpace(lerp(0.2209, albedo.xyz, metallic));
    
    metaInput.Albedo = albedo.rgb * _Color.rgb;
    metaInput.SpecularColor = specularCol;
    metaInput.Emission = 0;
    
    return MetaFragment(metaInput);
}

#endif