/***************************************************************************************************
*
* 溶解特效相关代码
* 
* 算法                    采样溶解贴图，和世界法线做运算
*                        计算 _Dissolve 和 _EdgeWidth 的差，和计算后的世界法线值比较，作为判断是否消融的依据（这种操作，似乎和贴图关系不大）
* 
* 额外参数的意义说明
* _DissolveTex;                      溶解纹理
* _Mask;                             遮罩纹理
* _TextureScale;                     纹理缩放值
* _TriplanarBlendSharpness;          ！！！用处不明    值为负数的时候可以使可见部分碎片化
* _Dissolve;                         溶解程度
* _EdgeWidth;                        溶解过渡边的宽度
* _EdgeColorScale;                   溶解过渡边的颜色缩放，调整光强
* _EdgeColor;                        溶解过渡边的颜色
* 
* 用法
* CalculateDissolve()     函数传入最终颜色、世界法线和世界坐标
***************************************************************************************************/


#ifndef HRP_DISSOLVE_INCLUDED
#define HRP_DISSOLVE_INCLUDED

#define DECLARE_DISSOLVE_PARAM   \
    sampler2D   _DissolveTex;               \
    half4       _DissolveParams;            \
    half        _Dissolve;                  \
    half4       _EdgeColor1;                \
    half4       _EdgeColor2;                \
    half        _BlendWidth1;               \
    half        _BlendWidth2;


// 2D Random
float RandomDissolve (float2 st) {
    return frac(sin(dot(st.xy,float2(12.9898,78.233)))* 43758.5453123);
}

float3 CalculateDissolve(float3 color,float4 vColor, float3 normalWorld, float3 posWorld, 
    sampler2D DissolveTex, half Dissolve, half TextureScale,half DissolveNormalStr,half DissolveVCStr, 
    half EdgeWidth, half4 EdgeColor1 ,half4 EdgeColor2, half BlendWidth1, half BlendWidth2)
{
    Dissolve = sqrt(Dissolve);
    half3 newWorldNormal = normalWorld * 0.5 + 0.5;

    float blendParams = saturate(newWorldNormal.r + DissolveNormalStr) + saturate(vColor.g + DissolveVCStr);

    blendParams *= 0.5;

    float4 noiseTex = tex2D(DissolveTex, posWorld.xy * TextureScale);
    //float noiseTex = 	RandomDissolve(posWorld.xy * TextureScale);

    float blendRange = blendParams - Dissolve - noiseTex.r * clamp((2-blendParams)* EdgeWidth,0,1);
    clip(blendRange);

    blendRange = clamp(blendRange,0,1);

    float blendW1 = clamp(blendRange * BlendWidth1,0,1);
    float blendW2 = clamp(blendRange * BlendWidth2,0,1);

    float3 c = color;

    c = lerp(EdgeColor1.xyz, c, blendW1);
    c = lerp(EdgeColor2.xyz, c, blendW2);

    return c;
}


// float3 zCalculateDissolve(float4 color, float3 normalWorld, float3 posWorld, float2 uv)
// {
//     half4 dissolve = tex2D(_DissolveTex, uv);
//     clip(dissolve.r - _Dissolve);

//     half threshod = 1 - smoothstep(0.0, _EdgeWidth, dissolve.r - _Dissolve);
//     half4 maskTex = tex2D(_Mask, half2(threshod, 0.5)) * _EdgeColorScale;
//     maskTex *= _EdgeColor;
//     half3 finalColor = lerp(color.xyz, maskTex.xyz, threshod * step(0.0001, _Dissolve));
//     return finalColor;
// }

#endif