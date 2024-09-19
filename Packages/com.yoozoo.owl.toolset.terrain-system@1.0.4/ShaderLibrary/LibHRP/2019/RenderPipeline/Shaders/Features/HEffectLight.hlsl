/***************************************************************************************************
*
* EffectLight 相关代码
*

rely
 TALighting(included)


 需要按照如下方式使用：
 *
 *      HLSLPROGRAM
 *      #include "../../Features/HEffectLight.hlsl"
 *      half4 frag(HV2F i) : SV_Target
 *      {
 *          ...
 *          half3 diffuse = CalculateLambertDiffuse(0, nDotL, mainLightColor) * diffuseColor;
 *          diffuse += GetLambertEffectLight(worldPos, worldNormal, diffuseColor);
 *          //根据需要选择不同的计算方法，可选择GetLambertEffectLight/GetHalfLambertEffectLight/GetAmbientEffectLight
 *          ...
 *      }
 *
 *
 *
***************************************************************************************************/

#ifndef HRP_EFFECT_LIGHT_INCLUDED
#define HRP_EFFECT_LIGHT_INCLUDED

#include "../../ShaderLibrary/HLighting.hlsl"
#include "HVolumetricLight.hlsl"

inline half3 GetAmbientEffectLight(float3 posWorld, half3 diffuseColor)
{
    half3 color = half3(0.0, 0.0, 0.0);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, posWorld);
        color += light.color * light.distanceAttenuation;
    }

    color *= diffuseColor;
    return color;
}

inline half3 GetLambertEffectLight(float3 posWorld, half3 normalWorld, half3 diffuseColor)
{
    half3 color = half3(0.0, 0.0, 0.0);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, posWorld);
        half3 lightColor = light.color * light.distanceAttenuation;
        half nDotL = saturate(dot(light.direction, normalWorld));
        color += CalculateLambertDiffuse(0, nDotL, lightColor);
    }

    // 物体接收的体积光照明 
    color += GetVolumetricLight(posWorld, normalWorld);

    color *= diffuseColor;

    return color;
}

inline half3 GetHalfLambertEffectLight(float3 posWorld, half3 normalWorld, half3 diffuseColor)
{
    half3 color = half3(0.0, 0.0, 0.0);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, posWorld);
        half3 lightColor = light.color * light.distanceAttenuation;
        half nDotL = dot(light.direction, normalWorld);
        color += CalculateHalfLambertDiffuse(0, nDotL, lightColor);
    }

   // 物体接收的体积光照明
    color += GetVolumetricLight(posWorld, normalWorld);

    color *= diffuseColor;

    return color;
}


#endif