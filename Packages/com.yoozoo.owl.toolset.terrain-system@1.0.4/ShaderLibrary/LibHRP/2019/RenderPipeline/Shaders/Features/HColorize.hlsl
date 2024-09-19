/***************************************************************************************************
*
* 分ID着色相关代码
* 
* 原算法                                 采样mask贴图，r通道用来和原色彩插值，g通道用来筛选哪些部分要被染色
*
*                                       采用ps中的“颜色”混合模式算法,染色的明度用来对原颜色和染色进行插值，使得当染色明度为0时，染色结果为原结果；mask贴图的r通道用于筛选哪些部分被染色
*                                       https://webdesign.tutsplus.com/tutorials/blending-modes-in-css-color-theory-and-practical-application--cms-25201
*
* 现算法                                RGB通道分别对应衣服染色的三个部位
*
* 额外参数的意义说明
* _ColorizeID0Color                     前染色方案 用于上色的第一个色彩
* _ColorizeID1Color                     前染色方案 用于上色的第二个色彩
* _ColorizeID2Color                     前染色方案 用于上色的第三个色彩
* _ColorizeID3Color                     前染色方案 用于上色的第四个色彩
* _ColorizeID4Color                     前染色方案 用于上色的第五个色彩
* 
* _ColorizeH0                           现染色方案 第一个色彩 的 色相
* _ColorizeS0                           现染色方案 第一个色彩 的 饱和度
* _ColorizeV0                           现染色方案 第一个色彩 的 明度
* _ColorizeH1                           现染色方案 第二个色彩 的 色相
* _ColorizeS1                           现染色方案 第二个色彩 的 饱和度
* _ColorizeV1                           现染色方案 第二个色彩 的 明度
* _ColorizeH2                           现染色方案 第三个色彩 的 色相
* _ColorizeS2                           现染色方案 第三个色彩 的 饱和度
* _ColorizeV2                           现染色方案 第三个色彩 的 明度
* 
* 
* 用法
* CalculateDissolve()                   原染色方案 函数传入原颜色，采样uv，遮罩图和5个用于染色的颜色; 原染色基本为使用新颜色替换旧颜色
* 
* Luminance()                           计算明度
* ClipColor()                           颜色分割
* SetLum()                              "颜色"混合模式
* EnhanceColor()                        人为调整饱和度和明度，提亮颜色
* 
* ColorizeCloth()                       原衣服染色方案 函数传入原颜色，采样uv，遮罩图和3个用于染色的hsv; 现染色为使用新颜色和原颜色进行“颜色”混合
* ColorizeClothRGB()                    现衣服染色方案：原衣服染色方案ColorizeCloth()在两个值交界处会有颜色跳跃的情况，改为用mask的RGB通道分别对应衣服染色的三个部位
                                        R G B A
                                        1 0 0 0     部位1
                                        0 1 0 0     部位2
                                        0 0 1 0     部位3
                                        0 0 0 0     不染色部位
* ColorizeClothOptimized()              备用衣服染色方案：在ColorizeClothRGB基础上压缩成2通道，可以放在normal的BA通道，这样省一张mask
                                        B       A 
                                        0       0       不染色部位
                                        0       0.5     部位1
                                        0.5     0       部位2
                                        1       1       部位3
* ColorizeHair()                        现头发染色方案 函数传入原颜色，用于染色的hsv
***************************************************************************************************/

#ifndef HRP_COLORIZE_INCLUDED
#define HRP_COLORIZE_INCLUDED

#define DECLARE_COLORIZE_PARAM   \
    half4       _ColorizeID0Color;          \
    half4       _ColorizeID1Color;          \
    half4       _ColorizeID2Color;          \
    half4       _ColorizeID3Color;          \
    half4       _ColorizeID4Color;          \
    half        _ColorizeH0;                \
    half        _ColorizeS0;                \
    half        _ColorizeV0;                \
    half        _ColorizeH1;                \
    half        _ColorizeS1;                \
    half        _ColorizeV1;                \
    half        _ColorizeH2;                \
    half        _ColorizeS2;                \
    half        _ColorizeV2;                \
    half4       _ColorizeRGBColor0;         \
    half4       _ColorizeRGBColor1;         \
    half4       _ColorizeRGBColor2;         \

float Luminance(float3 color)
{
    return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
}

float3 ClipColor(float3 color)
{
    float l = Luminance(color);
    float n = min(min(color.x, color.y), color.z);
    float m = max(max(color.x, color.y), color.z);

    if (n < 0.0)
    {
		color = l + (((color - l) * l) / (l - n));
    }
    if (m > 1.0)
    {
		color = l + (((color - l) * (1 - l)) / (m - l));
    }
    return color;
}

float3 SetLum(float3 color, float l)
{
    float d = l - Luminance(color);
	color = color + d;
    return ClipColor(color);
}

float3 ColorBlendMode(float3 blendCol, float3 sourceCol)
{
    return SetLum(sourceCol, Luminance(blendCol));
}

float3 RGB2HSV(float3 rgb)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(rgb.bg, K.wz), float4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    float4 q = lerp(float4(p.xyw, rgb.r), float4(rgb.r, p.yzx), step(p.x, rgb.r));


    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSV2RGB(half3 hsv)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * lerp(K.xxx, saturate(p - K.xxx), hsv.y);
}

half3 EnhanceColor(half3 sourceCol, half s, half v)
{
    half3 sourceCol_HSV = RGB2HSV(sourceCol.xyz);
    sourceCol_HSV.y = saturate(sourceCol_HSV.y + 0.3 * s);
    sourceCol_HSV.z = saturate(sourceCol_HSV.z + 0.1 * v);
    sourceCol.xyz = HSV2RGB(sourceCol_HSV);
    return sourceCol;
}


float3 CalculateColorize(float3 tBase, float2 uv,
            sampler2D ColorizeMask, half4 ColorizeID0Color, half4 ColorizeID1Color, half4 ColorizeID2Color, half4 ColorizeID3Color, half4 ColorizeID4Color)
{
    half3 tempColor;
    half2 colorizeMask = tex2D(ColorizeMask, uv).rg;
    //id 0
    tempColor = (tBase * (1 - colorizeMask.r) + ColorizeID0Color.rgb * colorizeMask.r) * step((colorizeMask.g - 0.3) * (colorizeMask.g - 0.1), 0);
    //id 1
    tempColor += (tBase * (1 - colorizeMask.r) + ColorizeID1Color.rgb * colorizeMask.r) * step((colorizeMask.g - 0.5) * (colorizeMask.g - 0.3), 0);
    //id 2
    tempColor += (tBase * (1 - colorizeMask.r) + ColorizeID2Color.rgb * colorizeMask.r) * step((colorizeMask.g - 0.7) * (colorizeMask.g - 0.5), 0);
    //id 3
    tempColor += (tBase * (1 - colorizeMask.r) + ColorizeID3Color.rgb * colorizeMask.r) * step((colorizeMask.g - 0.9) * (colorizeMask.g - 0.7), 0);
    //id 4
    tempColor += (tBase * (1 - colorizeMask.r) + ColorizeID4Color.rgb * colorizeMask.r) * step((colorizeMask.g - 1.1) * (colorizeMask.g - 0.9), 0);

    return tBase * step(colorizeMask.g, 0.1) + tempColor;
}
/*
float3 ColorizeCloth(half3 tBase, float2 uv, sampler2D ColorizeMask,
    half colorizeH0, half colorizeS0, half colorizeV0,
    half colorizeH1, half colorizeS1, half colorizeV1,
    half colorizeH2, half colorizeS2, half colorizeV2)
{
    half3 tempColor0;
    half3 tempColor1;
    half3 tempColor2;

    half colorizeMask = tex2D(ColorizeMask, uv).r;

    half3 hsv0 = half3(colorizeH0, colorizeS0, colorizeV0);
    half3 hsv1 = half3(colorizeH1, colorizeS1, colorizeV1);
    half3 hsv2 = half3(colorizeH2, colorizeS2, colorizeV2);

    half3 colorizeRGB0 = HSV2RGB(hsv0);
    half3 colorizeRGB1 = HSV2RGB(hsv1);
    half3 colorizeRGB2 = HSV2RGB(hsv2);

    colorizeRGB0 = lerp(tBase, colorizeRGB0, colorizeV0);
    colorizeRGB1 = lerp(tBase, colorizeRGB1, colorizeV1);
    colorizeRGB2 = lerp(tBase, colorizeRGB2, colorizeV2);

    tempColor0 = ColorBlendMode(tBase, colorizeRGB0.xyz);
    tempColor0 = EnhanceColor(tempColor0, colorizeS0, colorizeV0) * step((colorizeMask - 0.4) * (colorizeMask - 0.1), 0);

    tempColor1 = ColorBlendMode(tBase , colorizeRGB1.xyz);
    tempColor1 = EnhanceColor(tempColor1, colorizeS1, colorizeV1) * step((colorizeMask - 0.7) * (colorizeMask - 0.5), 0);

    tempColor2 = ColorBlendMode(tBase, colorizeRGB2.xyz);
    tempColor2 = EnhanceColor(tempColor2, colorizeS2, colorizeV2) * step((colorizeMask - 1.1) * (colorizeMask - 0.8), 0);

    return tBase * step(colorizeMask, 0.1) + tempColor0 + tempColor1 + tempColor2;
}
*/

half ColorChanelOverlay(half col1, half col2)
{
	half result;
	half value = 0;// step(col1, 0.5);
	result = (col1 * col2) * 2 * value + (1 - value)*(1 - (1 - col1)*(1 - col2) * 2);
	return result;
}

half4 ColorOverlay(half4 col1, half4 col2)
{
	half r = ColorChanelOverlay(col1.r, col2.r);
	half g = ColorChanelOverlay(col1.g, col2.g);
	half b = ColorChanelOverlay(col1.b, col2.b);
	half a = col1.a * col2.a;
	return half4(r, g, b, a);
}

half3 ColorOverlayRGB(half3 col1, half3 col2)
{
	half r = ColorChanelOverlay(col1.r, col2.r);
	half g = ColorChanelOverlay(col1.g, col2.g);
	half b = ColorChanelOverlay(col1.b, col2.b);
	return half3(r, g, b);
}

float3 ColorizeClothRGB(half3 tBase, float2 uv, sampler2D ColorizeMask,
    half colorizeH0, half colorizeS0, half colorizeV0,
    half colorizeH1, half colorizeS1, half colorizeV1,
    half colorizeH2, half colorizeS2, half colorizeV2)
{
    half3 tempColor0;
    half3 tempColor1;
    half3 tempColor2;

    half3 colorizeMask = tex2D(ColorizeMask, uv).rgb;

    half3 hsv0 = half3(colorizeH0, colorizeS0, colorizeV0);
    half3 hsv1 = half3(colorizeH1, colorizeS1, colorizeV1);
    half3 hsv2 = half3(colorizeH2, colorizeS2, colorizeV2);

    half3 colorizeRGB0 = HSV2RGB(hsv0);
    half3 colorizeRGB1 = HSV2RGB(hsv1);
    half3 colorizeRGB2 = HSV2RGB(hsv2);


    colorizeRGB0 = lerp(tBase, colorizeRGB0, colorizeV0);
    colorizeRGB1 = lerp(tBase, colorizeRGB1, colorizeV1);
    colorizeRGB2 = lerp(tBase, colorizeRGB2, colorizeV2);

    tempColor0 = ColorBlendMode(tBase, colorizeRGB0.xyz);
    tempColor0 = EnhanceColor(tempColor0, colorizeS0, colorizeV0) * colorizeMask.r;

    tempColor1 = ColorBlendMode(tBase, colorizeRGB1.xyz);
    tempColor1 = EnhanceColor(tempColor1, colorizeS1, colorizeV1) * colorizeMask.g;

    tempColor2 = ColorBlendMode(tBase, colorizeRGB2.xyz);
    tempColor2 = EnhanceColor(tempColor2, colorizeS2, colorizeV2) * colorizeMask.b;

    tBase = tBase * step(colorizeMask.r, 0.1) * step(colorizeMask.g, 0.1) * step(colorizeMask.b, 0.1);

    return tBase + tempColor0 + tempColor1 + tempColor2;
}

float3 ColorizeClothRGBOptimize(half3 tBase, float2 uv, sampler2D ColorizeMask,
	 half colorizeS0, half colorizeV0,
	 half colorizeS1, half colorizeV1,
	 half colorizeS2, half colorizeV2,
	half3 colorizeRGB0, half3 colorizeRGB1, half3 colorizeRGB2)
{
	half3 colorizeMask = tex2D(ColorizeMask, uv).rgb;

	float3 colorArr[5];
	colorArr[0] = float3(colorizeV0, colorizeV1, colorizeV2);
	colorArr[1] = colorizeRGB0;
	colorArr[2] = colorizeRGB1;
	colorArr[3] = colorizeRGB2;
	colorArr[4] = float3(colorizeS0, colorizeS1, colorizeS2);

    // index == 0 时保持原始颜色  其他通道按 1 、2 、3 代替分支
	half index = step(0.1, colorizeMask.r) * 1 + step(0.1, colorizeMask.g) * 2 + step(0.1, colorizeMask.b) * 3;
	index = clamp(floor(index), 0, 3);

    //动态分支影响性能
	//if (index < 0.1f)
	//	return tBase;
	
	half3 colorize = colorArr[index];

	colorize = lerp(tBase, colorize, colorArr[0][index - 1]);

    half3 tempColor0 = ColorBlendMode(tBase, colorize.xyz);
	tempColor0 = EnhanceColor(tempColor0, colorArr[4][index - 1], colorArr[0][index -1]);

	half weight = step(index, 0.1);
	return tBase * weight + tempColor0 * (1-weight);
}

//测试单通道染色效果测试代码
float3 ColorizeClothRGBOptimizeSingleChannel(half3 tBase, float2 uv, sampler2D ColorizeMask,
    half colorizeS0, half colorizeV0,
    half colorizeS1, half colorizeV1,
    half colorizeS2, half colorizeV2,
    half3 colorizeRGB0, half3 colorizeRGB1, half3 colorizeRGB2)
{
    half3 tempColor0;
    half3 tempColor1;
    half3 tempColor2;

    half colorizeMask = tex2D(ColorizeMask, uv).r;

    float3 colorArr[5];
    colorArr[0] = float3(colorizeV0, colorizeV1, colorizeV2);
    colorArr[1] = colorizeRGB0;
    colorArr[2] = colorizeRGB1;
    colorArr[3] = colorizeRGB2;
    colorArr[4] = float3(colorizeS0, colorizeS1, colorizeS2);

    half index = step(0.25, colorizeMask) * step(colorizeMask, 0.35) * 1 + step(0.55, colorizeMask)* step(colorizeMask, 0.65) * 2 + step(0.95, colorizeMask) * 3;
    
    half3 colorize = colorArr[index];


    colorize = lerp(tBase, colorize, colorArr[0][index - 1]);

    tempColor0 = ColorBlendMode(tBase, colorize.xyz);
    tempColor0 = EnhanceColor(tempColor0, colorArr[4][index - 1], colorArr[0][index - 1]);


    half weight = step(colorizeMask, 0.1);
    return tBase * weight + tempColor0 * (1 - weight);
}

//直接替换染色方法（测试用 待优化）
float3 ColorizeClothRGBOptimizeRGB(half3 tBase, float2 uv, sampler2D ColorizeMask,
	half colorizeH0, half colorizeS0, half colorizeV0,
	half colorizeH1, half colorizeS1, half colorizeV1,
	half colorizeH2, half colorizeS2, half colorizeV2,
	half3 colorizeRGB00, half3 colorizeRGB01, half3 colorizeRGB02)
{
	half3 tempColor0;
	half3 tempColor1;
	half3 tempColor2;

	half3 hsv0 = half3(colorizeH0, colorizeS0, colorizeV0);
	half3 hsv1 = half3(colorizeH1, colorizeS1, colorizeV1);
	half3 hsv2 = half3(colorizeH2, colorizeS2, colorizeV2);

	half3 colorizeRGB0 = HSV2RGB(hsv0);
	half3 colorizeRGB1 = HSV2RGB(hsv1);
	half3 colorizeRGB2 = HSV2RGB(hsv2);

	half3 colorizeMask = tex2D(ColorizeMask, uv).rgb;

	tBase = tBase * step(colorizeMask.r + colorizeMask.g + colorizeMask.b, 0.1);
	return tBase + colorizeRGB0 * colorizeMask.r + colorizeRGB1 * colorizeMask.g + colorizeRGB2 * colorizeMask.b;
}

float3 ColorizeHair(half3 tBase, float h, float s, float v)
{
    half3 tempColor;

    half3 hsv = half3(h, s, v);

    half3 colorizeRGB = HSV2RGB(hsv);

    colorizeRGB = lerp(tBase, colorizeRGB, v);

    tempColor = ColorBlendMode(tBase, colorizeRGB.xyz);
    tempColor = EnhanceColor(tempColor, s, v);

    return tempColor;
}



#endif