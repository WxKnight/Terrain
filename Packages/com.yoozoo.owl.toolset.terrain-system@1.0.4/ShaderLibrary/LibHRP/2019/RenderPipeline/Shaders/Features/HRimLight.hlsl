/***************************************************************************************************
*
* 边缘光相关代码
* 
* 算法                  计算 1 减去视线方向和法线的余弦，使观察方向和法线夹角大的点出现边缘光。
* 
* 额外参数的意义说明
* _RimColor;          边缘光颜色
* _RimPower;          边缘光程度范围
* 
* 用法
* CalculateRimLight（） 函数传入世界法线、世界视线方向、边缘光颜色和边缘光程度范围
***************************************************************************************************/

#ifndef HRP_RIM_LIGHT_INCLUDED
#define HRP_RIM_LIGHT_INCLUDED

#define DECLARE_RIMLIGHT_PARAM   \
    half   _RimPower;            \
    half3  _RimColor;

#define DECLARE_RIMLIGHT_INSTANCING_PARAM		\
UNITY_DEFINE_INSTANCED_PROP(half, _RimPower)	\
UNITY_DEFINE_INSTANCED_PROP(half3, _RimColor)



// for fs
half3  CalculateRimLight(float3 normal, float3 viewDir, half RimPower, half3 RimColor)
{
    half nv = saturate(dot(normal, viewDir));
    return step(0.01, RimPower) * RimColor * pow(1.0 - nv, 1.0 / RimPower);
}

#endif
