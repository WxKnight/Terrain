/***************************************************************************************************
*
* 自发光相关代码
*
*使用示例
*       #include "../../Features/HEmission.hlsl"
*       ...
*
*       float4 frag(HV2F i) : SV_Target
*      {
*           ...
*           half4 finalColor = RegularCalculation(...);//常规着色计算
*           finalColor += Emission(emissionTex, uv, diffuseCol, emissionCol);
*
*           ...
*       }
*
*
* reply
*     TAUtils(include) HTEX2D方法
***************************************************************************************************/


#ifndef HRP_EMISSION_INCLUDED
#define HRP_EMISSION_INCLUDED

#include "../../ShaderLibrary/HUtils.hlsl"

half3 Emission(sampler2D emissionTex, half2 uv,  half3 diffuseCol, half3 emissionCol)
{
    half3 emission = HTEX2D(emissionTex, uv).xyz;
    emission = emission * emissionCol * diffuseCol;
    return emission;

}

#endif
