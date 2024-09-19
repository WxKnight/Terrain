/************************************************************
 * 盗墓项目使用的常用 Shadow 函数
 *
 * 可配置的宏
 * 1. ALPHA_TEST : 支持 alpha test 的 shadow 投射
 *                 会自动声明 _MainTex 和 _Cutoff 两个变量
 *
 ************************************************************/


#ifndef HRP_DM_SHADOW_INCLUDED
#define HRP_DM_SHADOW_INCLUDED

#include "../../../../ShaderLibrary/HShadows.hlsl"

#ifdef ALPHA_TEST
sampler2D _MainTex;
half      _Cutoff;
#endif

// x: global clip space bias, y: normal world space bias
//float4 _ShadowBias;
float3 _LightDirection;



// Struct Define For Shadow
struct appdata_shadow
{
    half4 color     : COLOR;
    half4 vertex    : POSITION;
    half3 normal    : NORMAL;
    half4 tangent   : TANGENT;
    half4 texcoord  : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f_shadow
{
    float4 pos  : SV_POSITION;

#ifdef ALPHA_TEST
    float2 tex  : TEXCOORD1;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



float4 ClipSpaceShadowCasterPos(float4 vertex, half3 normal)
{
    float4 wPos = mul(UNITY_MATRIX_M, vertex);
    float3 wNormal = TransformObjectToWorldNormal(normal);

    //unity version
    float shadowCos = dot(_LightDirection, wNormal);
    float shadowSine = sqrt(1 - shadowCos * shadowCos);
    float normalBias = _ShadowBias.y * shadowSine;
    // normal bias is negative since we want to apply an inset normal offset
    wPos.xyz -= wNormal * normalBias;

    float4 clipPos = mul(UNITY_MATRIX_VP, wPos);

    // _ShadowBias.x sign depens on if platform has reversed z buffer
    float farAway = 1;
#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
    (clipPos.z  - UNITY_NEAR_CLIP_VALUE) / (UNITY_RAW_FAR_CLIP_VALUE - UNITY_NEAR_CLIP_VALUE);
    farAway = max(0.1, farAway * farAway);
#endif

#if UNITY_REVERSED_Z
    clipPos.z += farAway * _ShadowBias.x * max(0.1, (1 - shadowCos));
    clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#else
    clipPos.z -= farAway * _ShadowBias.x * max(0.1, (1 - shadowCos));
    clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return clipPos;
}



v2f_shadow vert_shadow(appdata_shadow v)
{
    v2f_shadow o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    o.pos = ClipSpaceShadowCasterPos(v.vertex, v.normal);

#ifdef ALPHA_TEST
    o.tex = v.texcoord;
#endif

    return o;
}

half4 frag_shadow(v2f_shadow i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
#ifdef ALPHA_TEST
    half4 alpha = tex2D(_MainTex, i.tex);
    clip(alpha.a - _Cutoff);
#endif
    return 0;
}


#endif //DM_SHADOW_INCLUDED