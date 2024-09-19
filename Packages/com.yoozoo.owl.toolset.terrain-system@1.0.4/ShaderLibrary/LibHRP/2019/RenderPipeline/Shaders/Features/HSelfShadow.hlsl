/***************************************************************************************************
*
*SelfShadow 相关代码
*
* 需要使用  uv1234，通过定义如下宏//todo : 后续根据更新的HAppData 定义进行修改
* #define _LIGHTMAP_ON
* #define _REQUIRE_UV_3
* #define _REQUIRE_UV_4
* #define DAO_PARAM0(appdata) (appdata).uv1
* #define DAO_PARAM1(appdata) (appdata).uv2
* #define DAO_PARAM2(appdata) (appdata).uv3
* #define DAO_PARAM3(appdata) (appdata).uv4
* 
* rely   
*   None
*
* 需要按照如下方式使用：
*      #include "../../Features/HSelfShadow.hlsl"
*       HV2F vert(HAppData i)
*       {
*        HV2F o;
*       AHDLightInfo info;
        SH9ToAHD(Props, info);
        float3 lightDir = TransformWorldToObjectDir(info.directionalLightDir.xyz);//得到局部坐标系下的光照颜色
        o.dAO = EvaluateDAO(lightDir, v.param0, v.param1, v.param2, v.param3);
*      }
*
*       float4 frag(HV2F i) : SV_Target
*      {
*             ......
*           half3 diffuse = RegularCalculation(...);//常规着色计算
*           diffuse *= i.dAO;
*			...        //后续其他计算
*       }
***************************************************************************************************/

#ifndef HRP_SELF_SHADOW_INCLUDED
#define HRP_SELF_SHADOW_INCLUDED



half EvaluateDAO(float3 lightDir,
    float4 param0,
    float4 param1,
    float4 param2,
    float4 param3)
{
    float x = lightDir.x;
    float y = lightDir.y;
    float z = lightDir.z;
    float x2 = x * x;
    float y2 = y * y;
    float z2 = z * z;

    half visible = 0;
    // evaluate
    visible += param0.x;
    visible += param0.y * y + param0.z * z + param0.w * x;

    visible += param1.x * y * x;
    visible += param1.y * y * z;
    visible += param1.z * (3 * z2 - 1);
    visible += param1.w * x * z;
    visible += param2.x * (x2 - y2);

    visible += param2.y * y * (3 * x2 - y2);
    visible += param2.z * z * x * y;
    visible += param2.w * y * (5 * z2 - 1);
    visible += param3.x * z * (5 * z2 - 3);
    visible += param3.y * x * (5 * z2 - 1);
    visible += param3.z * z * (x2 - y2);
    visible += param3.w * x * (x2 - 3 * y2);

    return visible;
}

#endif