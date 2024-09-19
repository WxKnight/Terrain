/***************************************************************************************************
 * 
 * 定义主要数据结构，并给出基本打包和访问方式
 *
 * 宏开关

   1. For TAAppdata
    _REQUIRE_APP_UV1_2CHANNEL    影响是否启用 half2 UV1
    _REQUIRE_APP_UV1_4CHANNEL    影响是否启用 half4 UV1
    _REQUIRE_APP_UV2             影响是否启用 UV2
    _REQUIRE_APP_UV3             影响是否启用 UV3
    _REQUIRE_APP_UV4             影响是否启用 UV4
    _REQUIRE_APP_UV234           语法糖，打开则直接打开 UV 234
    _LIGHTMAP_ON                 会在 TAAppdata 启用 REQUIRE_APP_UV1_2CHANNEL （对V2F也有影响）

   2. For HV2F
    _PRECISE_TBN                 影响是否启用精准的 TBN（否则可能是非标准化的），会保证 TN 的单位化及大致垂直，并会重新计算B
    _VERY_PRECISE_TBN            比 PRECISE 更加精准，保证数学上正确
    _LIGHTMAP_ON                 将 half2 uv1 该数据赋予在 HV2F 的 uv1
    _REQUIRE_V2F_UV2             影响是否在 v2f 中启用 half2 uv2 通道



 * Rely:
 *      1. Core.hlsl  (Contained, for UNITY_VERTEX_INPUT_INSTANCE_ID define)
 *      2. TAUtils    (Contained, for UnityObjectToWorldNormal / UnityObjectToWorldDir)
 *
 ***************************************************************************************************/


#ifndef HRP_PIPELINE_DATA_INCLUDED
#define HRP_PIPELINE_DATA_INCLUDED


#include "HCore.hlsl"
#include "HUtils.hlsl"





/***************************************************************************************************
 *
 * Region : App Data
 *
 ***************************************************************************************************/

#ifdef _LIGHTMAP_ON
    #define _REQUIRE_APP_UV1_2CHANNEL
#endif

#ifdef _REQUIRE_APP_UV234
    #define _REQUIRE_APP_UV2
    #define _REQUIRE_APP_UV3
    #define _REQUIRE_APP_UV4
#endif



struct HAppData
{
    float4 color    : COLOR;
    float4  vertex   : POSITION;
    half3  normal   : NORMAL;
    half4  tangent  : TANGENT;
    half2  uv0      : TEXCOORD0;

    // uv1 可能被 lightmap 使用（普通是2通道，如果使用 realtime gi 则是4通道）
    // 而一般来说，uv2 及以上都是用来存储特殊数据的，
    // 因此暂时没有提供 half2 / half4 两种选择

#if    defined _REQUIRE_APP_UV1_2CHANNEL
    half2  uv1      : TEXCOORD1;
#elif  defined _REQUIRE_APP_UV1_4CHANNEL
    half4  uv1      : TEXCOORD1;
#endif

#ifdef _REQUIRE_APP_UV2
    half4  uv2      : TEXCOORD2;
#endif

#ifdef _REQUIRE_APP_UV3
    half4  uv3      : TEXCOORD3;
#endif

#ifdef _REQUIRE_APP_UV4
    half4  uv4      : TEXCOORD4;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};




/***************************************************************************************************
 *
 * Region : v2f Data
 *
 ***************************************************************************************************/



/*********************************
 * v2f 数据结构定义
 *********************************/

 // Light Map UV
#ifdef _LIGHTMAP_ON
#define DATA_LIGHTMAP_UV_TEXCOORD1      float2 uv1 : TEXCOORD1;
#else
#define DATA_LIGHTMAP_UV_TEXCOORD1      // no light map, nothing
#endif


#ifdef _REQUIRE_V2F_UV2
#define DATA_UV2_TEXCOORD2      float2 uv2 : TEXCOORD2;
#else
#define DATA_UV2_TEXCOORD2      // nothing
#endif


/**
 * Tagnet To World Matrix, and World Position
 * will use TEXCOORD i. i+1. i+2
 *
 * 1. In _PRECISE_TBN pattern, contains wtangent, wnormal, wbinormal
 *    xyz is tbn, w is world position
 * 2. In NOT _PRECISE_TBN pattern, contains wtangent, wnormal, tangent.sign
 *
 * TODO: this pack is not very good, since wpos can be very large while tbn very small (in [-1, 1])
 * now we use half4, but be caution that for really large world, 'half' may not be sufficiant for wpos
 */
#define DATA_TtoW_WPos(i)      float4 tToW[3] : TEXCOORD##i;



/**
 * 数据结构定义，用法如下：
 * 注意 UNITY_VERTEX_INPUT_INSTANCE_ID 必须要放结尾，不然部分机型会有显示问题
 *  V2F_BEGEIN
 *      half4 viewDir : TEXCOORD2;
 *      DATA_TtoW_WPos(3)
 *  V2F_END
 */
#define V2F_BEGEIN      \
    struct HV2F {                              \
        half4  color         : COLOR;            \
        float4 vertex        : SV_POSITION;      \
        half2  uv            : TEXCOORD0;        \
        DATA_LIGHTMAP_UV_TEXCOORD1              \
        DATA_UV2_TEXCOORD2


#define V2F_END         \
        UNITY_VERTEX_INPUT_INSTANCE_ID          \
        };




/*********************************
* Data Pack/Access Utils -- TBN
*********************************/

// 将 TBN 和 WorldPos 压缩到 3 个 float4 中
inline void GetPackedT2W(HAppData inData, out float4 tToW[3])
{
    // from CreateTangentToWorldPerVertex to calc TBN
    float3 wNormal  = TransformObjectToWorldNormal(inData.normal);
    float3 wTangent = TransformObjectToWorldDir(inData.tangent.xyz);
    float  sign     = unity_WorldTransformParams.w * inData.tangent.w;

#if defined(_PRECISE_TBN) || defined(_VERY_PRECISE_TBN)
    float3 wBiNormal = sign;
#else
    float3 wBiNormal = cross(wNormal, wTangent.xyz) * sign;
#endif

    // get worldPos
    float4 wPos = mul(UNITY_MATRIX_M, inData.vertex);

    // Pack Data
    tToW[0] = float4(wTangent.xyz, wPos.x);
    tToW[1] = float4(wBiNormal.xyz, wPos.y);
    tToW[2] = float4(wNormal.xyz, wPos.z);


  
}


inline void RenormalizeT2W(inout float4 tToW[3])
{
#if defined _PRECISE_TBN
    float3 tangent  = normalize(tToW[0].xyz);
    float3 normal   = normalize(tToW[2].xyz);
    float3 binormal = cross(normal, tangent) * tToW[1].x;
    tToW[0] = float4(tangent,  tToW[0].w);
    tToW[1] = float4(binormal, tToW[1].w);
    tToW[2] = float4(normal,   tToW[2].w);

#elif defined _VERY_PRECISE_TBN
    float3 tangent  = tToW[0].xyz;
    float3 normal   = normalize(tToW[2].xyz);
    tangent = normalize(tangent - normal * dot(tangent, normal));

    float3 binormal = cross(normal, tangent) * tToW[1].x;
    tToW[0] = float4(tangent,  tToW[0].w);
    tToW[1] = float4(binormal, tToW[1].w);
    tToW[2] = float4(normal,   tToW[2].w);

#else
    // do nothing, just leave as it is
#endif
}



// 将压缩数据的各分量提取出来
#define GetWorldPos(v2fData)       (float3( (v2fData).tToW[0].w, (v2fData).tToW[1].w, (v2fData).tToW[2].w ))
#define GetWorldTangent(v2fData)   ((v2fData).tToW[0].xyz)
#define GetWorldBiNormal(v2fData)  ((v2fData).tToW[1].xyz)
#define GetWorldNormal(v2fData)    ((v2fData).tToW[2].xyz)



// 将压缩数据的 TBN 矩阵使用起来
#define MatrixWorldToTangent(v2fData) float3x3((v2fData).tToW[0].xyz, (v2fData).tToW[1].xyz, (v2fData).tToW[2].xyz)

// T 和 W 之间的转换
#define WorldToTangent(v2fData, dir) ( mul(MatrixWorldToTangent(v2fData), (dir)) )
#define TangentToWorld(v2fData, dir) ( mul((dir), MatrixWorldToTangent(v2fData)) )



/*********************************
 * Data Access Utils  -- UV02
 *********************************/

 // 获取打包的 UV0 和 UV2
#define UV0(v2fData)            ((v2fData).uv)
#define UV2(v2fData)            ((v2fData).uv2.xy)
#define LightMapUV(v2fData)     ((v2fData).uv1.xy)


/*********************************
* Data Pack/Access Utils -- LightMap UV
*********************************/

#ifdef _LIGHTMAP_ON
#define PackLightMapUV(v2fData, appData)        (LightMapUV(o) = appData.uv1 * unity_LightmapST.xy + unity_LightmapST.zw)
#else
#define PackLightMapUV(v2fData, appData)        // no light map, nothing to do
#endif




#endif