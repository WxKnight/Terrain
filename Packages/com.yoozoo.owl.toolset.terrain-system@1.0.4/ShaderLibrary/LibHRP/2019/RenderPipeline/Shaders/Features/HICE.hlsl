/***************************************************************************************************
*
* 结冰特性相关代码
* 
* 算法                      以观察方向为光照方向计算镜面 1 ，以光照方向计算镜面 2 ，镜面 2 添加了边缘光，二者相加为镜面色。
*                           采样结冰颜色纹理、和反射率以 nv 和冰厚度参数为权重进行插值，作为漫反射颜色。
*                           采样立方体贴图，作为环境色。镜面 + 漫反射 + 环境作为结冰部分。
*                           以消融贴图为权重，将结冰部分和最终颜色进行插值。
* 
* 额外参数的意义说明
* _iceTEx;                  结冰颜色纹理
* _iceParam                 结冰参数贴图，R为结冰AO， G为结冰噪声， B为结冰溶解
* _iceNoise;                结冰噪声纹理
* _iceAO;                   结冰 AO 纹理
* _iceDissolveTex;          结冰溶解纹理
* _iceCube;                 结冰环境图

* _iceTilling;              无用
* _Noisetilling;            调整噪声采样，丰富噪声
* _iceTextureScale;         无用
* _iceRoughness;            调整粗糙度
* _iceSpecValue;            镜面 1 强度
* _iceSpecPower2;           镜面 2 强度
* _iceNoiseMin;             无用
* _iceRimPower;             边缘光强度
* _iceCubeIntensity;        环境图强度
* _iceRange;                结冰范围
* _iceMaxThickness;         冰最大厚度
* _iceMinThickness;         无用

* _iceRimColor;             边缘光颜色
* _iceColor;                无用
* _specColor1;              镜面 1 颜色
* _specColor2;              镜面 2 颜色
* 
* 用法
* CalculateIce()            函数输入反射率、世界视线方向、世界法线、模型的采样 uv ，世界灯光方向、世界灯光颜色和最终颜色
***************************************************************************************************/
#include "RimLight.hlsl"

#ifndef HRP_ICE_INCLUDED
#define HRP_ICE_INCLUDED


#define DECLARE_ICE_PARAM   \
    sampler2D _iceTEx;          \
    sampler2D _iceParam;        \
    samplerCUBE _iceCube;       \
    half _Noisetilling;         \
    half _iceRoughness;         \
    half _iceSpecValue;         \
    half _iceSpecPower2;        \
    half _iceRimPower;          \
    half _iceCubeIntensity;     \
    half _iceRange;             \
    half _iceMaxThickness;      \
    half4 _iceRimColor;         \
    half4 _specColor1;          \
    half4 _specColor2;    
    // half _iceNoiseMin;          \
    // sampler2D _iceNoise;        \
    // sampler2D _iceAO;           \
    // sampler2D _iceDissolveTex;  \
    // half _iceMinThickness;      \
    // half _iceTilling;           \
    // half4 _iceColor;            \
    // half _iceTextureScale;      \


// for fs
half3 CalculateIce(float3 albedo, float3 viewDir, float3 normalWorld, float2 uv, float3 lightDir, float3 lightColor, float3 color, 
    sampler2D iceTEx, sampler2D iceParam, samplerCUBE iceCube, half Noisetilling, 
    half iceRoughness, half iceSpecValue, half iceSpecPower2, half iceRimPower, half iceCubeIntensity, 
    half iceRange, half iceMaxThickness, half4 iceRimColor, half4 specColor1, half4 specColor2)
{
    // DECLARE_ICE_PARAM
    half4 iceParameter = tex2D(iceParam, uv* Noisetilling);
    half iceAO = iceParameter.r;
    half iceNoise = iceParameter.g;
    half4 ice = tex2D(iceTEx, uv);

//ice rim-------
    half3 rimColor2 = CalculateRimLight(normalWorld, viewDir, iceRimPower, iceRimColor);

    float3 eyeVec = -viewDir;
//--------------
//ice specular brdf1
    half3 iceL = viewDir;//normalize(UNITY_MATRIX_V[2].xyz);
    half3 iceH = viewDir;//normalize(iceL - eyeVec.xyz);
    half ice_dot_nh = max(dot(normalWorld,iceH),0.001);

    half3 ice_spec = lightColor * specColor1.xyz * pow(ice_dot_nh, iceRoughness * 128);
    ice_spec = max(iceSpecValue * pow(ice_spec.xyz, iceSpecPower2) *iceNoise , 0);
//--------------
//brdf2---------
    iceL = lightDir;//normalize(UNITY_MATRIX_V[2].xyz);
    iceH = normalize(iceL - eyeVec.xyz);
    ice_dot_nh = max(dot(normalWorld,iceH),0.001);

    half3 ice_spec2 = lightColor * specColor2.xyz * pow(ice_dot_nh, iceRoughness * 128);
    ice_spec2 = max(iceSpecValue * (pow(ice_spec2.xyz, iceSpecPower2) + rimColor2) *iceNoise , 0);
    ice_spec += ice_spec2;
//--------------
//dif-----------
    half ice_dot_nv = max(dot(normalWorld, viewDir), 0.001);
    half t1 = ice.x * ice_dot_nv;
    half level = lerp(0.0, t1, iceMaxThickness);
    half3 ice_dif = lerp(albedo.xyz, ice.xyz, level);
    //ice color
    ice.xyz = ice_dif + ice_spec ;
    // float3 ice2 = 0.5*ice_dif + 1.5*ice_spec+ 1 * rimColor2;
//--------------
//ice Cube------
    half3 R = reflect(eyeVec, (normalWorld));
    half4 cube = texCUBElod(iceCube, half4(R,5)) * iceCubeIntensity;
    ice.xyz += cube.xyz;//*rimColor2;
//--------------
//dissolve------
    half icedisst = iceParameter.b;
    // float noise = icedisst.r;
    half3 icenewWnormal = normalWorld * 0.5 + 0.5;
    icedisst *= icedisst * icedisst;
    icedisst += 1 - icenewWnormal.y;
    icedisst *= 0.5;
    //_iceRange=1-_iceRange;
    half icedisStep = step(iceRange, icedisst.x);
    half iceedge = saturate((icedisst.x - iceRange) / iceRange) * icedisStep;

    float3 originCol = color;
    color.xyz = lerp(color.xyz, ice.xyz, iceedge * iceAO);
//--------------
    return color;
}


#endif