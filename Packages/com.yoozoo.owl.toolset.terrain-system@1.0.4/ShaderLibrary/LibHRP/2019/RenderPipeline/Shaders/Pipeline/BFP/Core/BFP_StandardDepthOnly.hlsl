// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef HRP_DM_STANDARD_DEPTH_ONLY_INCLUDED
#define HRP_DM_STANDARD_DEPTH_ONLY_INCLUDED

// Functionality for Standard shader "meta" pass
// (extracts albedo/emission for lightmapper etc.)

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"


#ifdef _NEED_ALPHA_TEST
    sampler2D _MainTex;
    half4     _MainTex_ST;
    half      _Cutoff;
#endif


struct Appdata_DepthOnly
{
    float4 pos : POSITION;

#ifdef _NEED_ALPHA_TEST
    half2  uv  : TEXCOORD0;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct V2f_DepthOnly
{
    float4 vertex : SV_POSITION;

#ifdef _NEED_ALPHA_TEST
    half2  uv     : TEXCOORD0;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};



V2f_DepthOnly VertDepthOnly(Appdata_DepthOnly appData)
{
    V2f_DepthOnly o = (V2f_DepthOnly)0;

    UNITY_SETUP_INSTANCE_ID(appData);
    UNITY_TRANSFER_INSTANCE_ID(appData, o);

    o.vertex = TransformObjectToHClip(appData.pos.xyz);
#ifdef _NEED_ALPHA_TEST
    o.uv     = appData.uv * _MainTex_ST.xy + _MainTex_ST.zw;
#endif
    return o;
}


half4 FragDepthOnly(V2f_DepthOnly i) : SV_Target
{
#ifdef _NEED_ALPHA_TEST
    float4 color = tex2D(_MainTex, i.uv);
    clip(color.a - _Cutoff);
#endif
    return 0;
}



#endif // DM_STANDARD_DEPTH_ONLY_INCLUDED