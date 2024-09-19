#ifndef HRP_BFP_DATA_INCLUDED
#define HRP_BFP_DATA_INCLUDED


#include "../../../../ShaderLibrary/HPipelineData.hlsl"


#ifdef _VERTEXFOG_ON
#define DECLARE_FOG_PARAM(i)  float4 fog : TEXCOORD##i;
#else
#define DECLARE_FOG_PARAM(i)
#endif

#ifdef _VERTEX_EFFECT_LIGHT
    #define DECLARE_EFFECT_LIGHT(i)  float3 effectCol : TEXCOORD##i;
#else
    #define DECLARE_EFFECT_LIGHT(i)
#endif

#define DECLARE_SHADOW_PARAM(i)  float4 _ShadowCoord : TEXCOORD##i;


#define BFP_STRUCT_COMMON                                    \
                            V2F_BEGEIN                      \
                                DATA_TtoW_WPos(4)           \
                                DECLARE_FOG_PARAM(7)        \
                                DECLARE_EFFECT_LIGHT(8)     \
                            V2F_END


#define BFP_STRUCT_SCREENPOS                                         \
                            V2F_BEGEIN                              \
                                DATA_TtoW_WPos(4)                   \
                                DECLARE_FOG_PARAM(7)                \
                                float4 screenPos : TEXCOORD8;       \
                                DECLARE_EFFECT_LIGHT(9)             \
                            V2F_END


#define BFP_STRUCT_SHADOWCOORD                               \
                            V2F_BEGEIN                      \
                                DATA_TtoW_WPos(4)           \
                                DECLARE_SHADOW_PARAM(7)     \
                                DECLARE_EFFECT_LIGHT(8)     \
                            V2F_END


#define BFP_STRUCT_SHADOWCOORD_FOG                           \
                            V2F_BEGEIN                      \
                                DATA_TtoW_WPos(4)           \
                                DECLARE_SHADOW_PARAM(7)     \
                                DECLARE_EFFECT_LIGHT(8)     \
                                DECLARE_FOG_PARAM(9)        \
                            V2F_END


#endif