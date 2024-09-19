/***************************************************************************************************
 *
 * 特效合批后，由于 ParticleSystem CustomData 的带宽限制，会进行参数的合并压缩
 * 需要在使用的时候进行解压
 *
 * rely:
 *
 ***************************************************************************************************/


#ifndef HRP_EFFECT_PARAM_DECODE_INCLUDED
#define HRP_EFFECT_PARAM_DECODE_INCLUDED


/*************************
 * 单个贴图相关的数据
 *************************/
struct SimpleTexParam {
    float4 spriteRect;
    float4 scaleOffset;
};


/*************************
 * 简单参数解码, 配合 EffectOptimizeCompUtils 中的压缩方式
 *************************/
inline SimpleTexParam DecodeSimpleTexParam(float4 data) {
    float4 fracPartData = frac(data);
    float4 numPartData  = data - fracPartData;

    SimpleTexParam param = (SimpleTexParam)0;
    param.spriteRect = fracPartData * 2000.0 / 1024.0;
    param.scaleOffset = numPartData / 100;
    return param;
}



/*************************
 * 解码出来的较完整版数据
 *************************/
struct DecodedParam {
    // Tint Color
    float4 color;

    // mainTex 的图集相对位置和 scaleOffset
    float4 mainSpriteRect;
    float4 mainScaleOffset;

    // 第二张贴图（通常是 maskTex）的图集相对位置和 scaleOffset
    float4 secondarySpriteRect;
    float4 secondaryScaleOffset;

    // 是否有第二张贴图
    float  hasSecondary;

    // 混合方式
    // 0: Add       : SrcAlpha, One
    // 1: Blend     : SrcAlpha, OneMinusSrcAlpha
    // 2: ZeroAlpha : SrcAlpha One, Zero One
    float  blendOp;
};




/*************************
 * 常用解码, 从两个 float4 customData 中解压出 DecodedParam
 * 和上面的 DecodeSimpleTexParam 不同, float4 中的前2位还包含了 color bit, 后两位算法则相同
 *************************/
inline DecodedParam Decode(float4 data1, float4 data2) {
    DecodedParam param = (DecodedParam)0;

    // set blendOp
    if (data1.x < 0 && data1.y < 0)
        param.blendOp = 2;      // BlendOp.ZeroAlpha
    else if (data1.x < 0)
        param.blendOp = 1;
    // else param.blendOp = 0;  // default is 0


    data1 = abs(data1);

    float4 fracPartData = frac(data1);
    float4 numPartData  = data1 - fracPartData;

    // 小数部分是 sprite rect
    param.mainSpriteRect = fracPartData * 2000.0 / 1024.0;

    // 对 scale,   整数 100 以上部分是 scale
    // 对 offset， 整数部分都是 offset
    param.mainScaleOffset = numPartData / 100;
    param.mainScaleOffset.xy = floor(param.mainScaleOffset.xy);
    param.color.xy = (numPartData.xy - param.mainScaleOffset.xy * 100) / 16.0;


    fracPartData = frac(data2);
    numPartData  = data2 - fracPartData;

    // 小数部分是 sprite rect
    param.secondarySpriteRect = fracPartData * 2000.0 / 1024.0;

    // 对 scale,   整数 100 以上部分是 scale
    // 对 offset， 整数部分都是 offset
    param.secondaryScaleOffset = numPartData / 100;
    param.secondaryScaleOffset.xy = floor(param.secondaryScaleOffset.xy);
    param.color.zw = (numPartData.xy - param.secondaryScaleOffset.xy * 100) / 16.0;

    if (param.secondarySpriteRect.x > 0.001)
        param.hasSecondary = 1;
    // else param.hasSecondary = 0;  // default is 0

    return param;
}





inline float2 CalculateUV(float2 uv, float4 spriteRect) {
    uv = frac(uv) * spriteRect.xy + spriteRect.zw;
    return uv;
}


// 为 Blend One OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha 模式工作
// 可以保证 Blend 和 ZeroAlpha 是正确的
// 也可以保证 ColorMask RGB 的 ADD 模式是正确的
// 但带 A 通道的 Add 的 alpha 通道是不正确的，在多次 blend 之后会错误
inline float4 GetFinalColorInMode_One_OneMinusSrcAlpha(float blendOp, float4 finalColor)
{
    finalColor.a = saturate(finalColor.a);

    finalColor.rgb *= finalColor.a;

    if (blendOp > 2 - 0.1)
        finalColor.a = 0;
    else if (blendOp > 1 - 0.1)
        finalColor.a = finalColor.a;
    else
        finalColor.a = 0;

    return finalColor;
}



#endif
