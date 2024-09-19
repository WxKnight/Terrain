// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef HRP_DM_STANDARD_DEPTH_ONLY_INCLUDED
#define HRP_DM_STANDARD_DEPTH_ONLY_INCLUDED

// Functionality for Standard shader "meta" pass
// (extracts albedo/emission for lightmapper etc.)

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"

#define _NEED_ALPHA_TEST 1


#ifdef _NEED_ALPHA_TEST
    sampler2D _MainTex;
    half4     _MainTex_ST;
    half      _Cutoff;
#endif


struct Appdata_NormalOnly
{
    float4 pos : POSITION;

#ifdef _NEED_ALPHA_TEST
    half2  uv  : TEXCOORD0;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct V2f_NormalOnly
{
    float4 vertex : SV_POSITION;
    float3 wPos:TEXCOORD1;
#ifdef _NEED_ALPHA_TEST
    half2  uv     : TEXCOORD0;
#endif


    UNITY_VERTEX_INPUT_INSTANCE_ID
};



V2f_NormalOnly VertNormalOnly(Appdata_NormalOnly appData)
{
    V2f_NormalOnly o = (V2f_NormalOnly)0;

    UNITY_SETUP_INSTANCE_ID(appData);
    UNITY_TRANSFER_INSTANCE_ID(appData, o);

    o.vertex = TransformObjectToHClip(appData.pos.xyz);
#ifdef _NEED_ALPHA_TEST
    o.uv     = appData.uv * _MainTex_ST.xy + _MainTex_ST.zw;
#endif
    o.wPos =  mul(unity_ObjectToWorld, appData.pos.xyz);
    return o;
}


half4 FragNormalOnly(V2f_NormalOnly i) : SV_Target
{
    
#ifdef _NEED_ALPHA_TEST
    float4 color = tex2D(_MainTex, i.uv);
    clip(color.a - _Cutoff);
#endif
    
    float3 normal = (normalize(cross(ddy(i.wPos), ddx(i.wPos)))+1)*0.5f ;


    return float4(normal,1);
}



#endif // DM_STANDARD_DEPTH_ONLY_INCLUDED