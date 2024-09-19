/***************************************************************************************************
*
* 基于图像反射相关代码
* 
* 算法      以观察方向的反射方向为采样方向采样 cubemap ，并关联物体粗糙度和金属度 BRDF
* 
* 用法      StandardCubeMap（） 函数需要传入观察方向、法线方向，以及物体表面的粗糙度、金属度，同时传入 info 。输出反射颜色，
*           info.directionalLightCol.x 参数用于解决 未使用 lightmap 颜色采样而只使用 lightmap 方向采样时产生的 BUG  见第 27 行
***************************************************************************************************/

#ifndef HRP_IBR_INCLUDED
#define HRP_IBR_INCLUDED

#include "../../ShaderLibrary/HPipelineData.hlsl"
#include "../../ShaderLibrary/HPipelineDataUtils.hlsl"

// for standard
inline half3 StandardCubeMap(PBSDirections dirs, PBSSurfaceParam surface, AHDLightInfo info)
{
    half3 R = reflect(-dirs.viewDir, dirs.normal);
    half4 cube = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R.xyz, surface.perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS);
    cube.xyz = DecodeHDR(cube, unity_SpecCube0_HDR);
    cube.xyz *= (surface.metallic* 0.5 + 0.5);

    float temp = 1.0 / (surface.perceptualRoughness * surface.perceptualRoughness + 1.0);
    
    cube *= temp*(1 - (dirs.nDotH + info.directionalLightCol.x * 0.000000001) * (1 - surface.metallic));

    return  cube.xyz;
}

// todo
// for wet、 rain situation
// inline half3 WetCubeMap(v2f i, PBSDirections dirs, PBSSurfaceParam surface, float4 albedo)
// {
//     #ifdef _DYNAMIC_WEATHER_RAIN
//         half rainMaskTEX = HTEX2D(_WeatherMaskTex,i.uv1.xy).r;
//         half2 rainUV = RainUV(i.wPosuv,9,.5,15);
//         half4 rainTEX = (HTEX2D(_WeatherTex,rainUV)*2-1)*0.3*rainMaskTEX;
//         half rainnoise = RainLerp(0,rainTEX.r,rainTEX.g,_RainIntensity);
//     #else
//         half rainnoise = 0;
//     #endif

//     half3 R = reflect(-dirs.viewDir, dirs.normal);
//     half ndl = (1 - dirs.nDotV);
//     half4 cubeCol = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R.xyz+rainnoise, surface.roughness * UNITY_SPECCUBE_LOD_STEPS);
//     cubeCol.xyz = DecodeHDR(cubeCol, unity_SpecCube0_HDR);
//     cubeCol.xyz*=1.5;
//     float F=ndl*ndl;
//     F*=F*ndl;
//     //return	( F+0.1)*cubeCol.rgb*  albedo.w;
    
//     #ifdef _MIRROR_ON
//         half4 mirrorCol = HTEX2D(_RefTexture, i.screenPos.xy / i.screenPos.w);
//         float mirrorFactor = max((i.screenPos.y /i.screenPos.w- _MirrorRange)* _MirrorPower,0.0);
//         cubeCol.rgb += mirrorFactor* mirrorCol.rgb;
//     #endif	

//     half3 cube = lerp(0, cubeCol.rgb, 0.1 + 0.9 * ndl * ndl * ndl * ndl) *  albedo.w;

//     return cube.xyz;
// }

// todo 
// a funttion work for WetCubeMap
// inline half2 RainUV(half2 baseUV,half cellNUM,half tiling,half speed)     //half2 rainUV = RainUV(i.wPosuv,12,0.1,25);
// {
// 	half2 uv = baseUV*tiling;//_raintiling
//     half cellX = uv.x / cellNUM;
//     int SpriteIndex = fmod(_Time.y*speed,cellNUM);//_rainspeed
//     int SpriteColumnIndex = fmod(SpriteIndex,cellNUM);
//     uv.x = cellX + SpriteColumnIndex / cellNUM;
//     return uv;
// }


#endif