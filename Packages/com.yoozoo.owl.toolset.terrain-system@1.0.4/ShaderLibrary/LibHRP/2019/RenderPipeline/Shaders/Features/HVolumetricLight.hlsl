/***************************************************************************************************
*
* Volumetic Light 相关代码
*

 

 * 参考 https://software.intel.com/en-us/articles/ivb-atmospheric-light-scattering
 *     https://www.shadertoy.com/view/XlBSRz
 *  
 *
 * 算法: 微分，逐步累加空间中介质散射出的光强
 *
 * 参数意义说明
 * _VolumetricLightForward          xyz 为体积光源照射的世界方向， w 为体积光源照射方向的张角
 * _VolumetricLightPos              xyz 为体积光源的世界坐标位置，w 为被照亮物体上的光强
 * _VolumetricLightColor            为体积光源发出的颜色

 * 用法
 * GetVolumetricLight(float3 hitPos, half3 normal)          用于接收体积光发出的光，使自身被照亮， hitPos 为物体逐像素（逐顶点）的世界位置， normal 为该点的世界法线
 *                                                          函数内会判断该点是否在体积光照射方向的区域内，是则被点亮
 *
 * MieScatter(float cosTheta, float g, float3 betaM)        米氏散射，计算介质相对于入射光，沿某个方向散射出光线的程度。
 *                                                          cosTheta 为入射方向于出射方向的夹角余弦，g 为介质的散射特性，betaM 为米氏散射的散射系数。 （当前效果不好，没有加入到最终结果中）
 *
 * BeerLambert(float density, float dist, float inLight)    比尔兰伯特消光定律，计算介质吸收与透光的比例
 *                                                          density 为介质密度， dist 为出射光传播的距离， inLight 为入射的光强。 （当前效果不好，没有加入到最终结果中）
 *
 * RayMarch(float3 startPos, float3 viewDir, float lightIntensity, float3 betaM, float g, half3 normal)
 *                                                          微分累加计算出体积光，从观察到的点为起点，观察相机为终点步进，判断途中每个点是否在体积光照射范围内，是则计入最终光照计算。途中每点的光强与该点到体积光源的距离平方成反比
 *                                                          startPos为观察到的点，viewDir是观察方向，lightIntensity为体积光源的光强，betaM为米氏散射系数，g为介质散射特性，normal为观察到的点的世界法线（目前无用）

***************************************************************************************************/


#ifndef HRP_VOLUMETRIC_LIGHT_INCLUDED
#define HRP_VOLUMETRIC_LIGHT_INCLUDED

uniform float4 _VolumetricLightForward; 
uniform float4 _VolumetricLightPos;
uniform float4 _VolumetricLightColor;


inline half3 GetVolumetricLight(float3 hitPos, half3 normal)
{
    half3 color = half3(0.0, 0.0, 0.0);

    float3 hit2vlightDir = hitPos - _VolumetricLightPos.xyz;
    float hit2vlightDist = length(hit2vlightDir) + 1;
    float hit2vlightDistInv = 1.0 / hit2vlightDist;
    half3 hit2vlightDirNorm = normalize(hit2vlightDir);
    half nDotVl = saturate(dot(normal, -hit2vlightDirNorm));

    // return nDotVl;
    half  h2lDotlitfrwrd = dot(hit2vlightDirNorm, _VolumetricLightForward.xyz);
    color = _VolumetricLightColor.xyz * _VolumetricLightPos.w * smoothstep(cos(_VolumetricLightForward.w), 1, h2lDotlitfrwrd)  * hit2vlightDistInv;

    return color * nDotVl;
}

float3 MieScatter(float cosTheta, float g, float3 betaM)
{
    float temp1 = (1.0 - g) * (1.0 - g);
    float temp2 = 4 * 3.1415 * pow(1 + g * g - 2 * g * cosTheta, 1.5);
    return temp1 * betaM / temp2;
}

float BeerLambert(float density, float dist, float inLight)
{
    float result = inLight * exp(-density * dist);
    return result;
}

float3 RayMarch(float3 startPos, float3 viewDir, float lightIntensity, float3 betaM, float g, half3 normal)
{
    // 观察到的点与观察位置之间的向量
    float3 view2DestDir = startPos - _WorldSpaceCameraPos.xyz;

    // 观察到的点与观察位置之间的距离
    float view2DestDist= length(view2DestDir);

    // 以观察点与观察位置之间的距离为总的循环次数，每次递进 距离的倒数
    // 两种步进规则
    const int stepNum = 30;    //floor(view2DestDist)+1;
    float oneStep = view2DestDist / stepNum;    // 1 / stepNum

    float3 finalLight = 0;
    for (int k = 0; k < stepNum; k++)
    {
        // 采样的位置点
        float3 samplePos = startPos + viewDir * oneStep * k;     // * k ;

        // 累计递进的距离
        float stepDist = length(viewDir * oneStep * k);
        // 采样点到体积光源的位置的向量  指向光源
        float3 sample2Light = samplePos - _VolumetricLightPos.xyz;
        float3 sample2LightNorm = normalize(sample2Light);

        // 体积光源的照射方向和采样点到体积光源的方向的点积
        float litfrwdDotSmp2lit = dot(sample2LightNorm, _VolumetricLightForward.xyz);
        
        // angle为体积光的张角的一半，如果 litfrwdDotSmp2lit 大于 cos(angle) ，则表示该采样点在体积光范围内
        float isInLight = smoothstep(cos(_VolumetricLightForward.w), 1, litfrwdDotSmp2lit);

        // 采样点到体积光源的距离
        float sample2LightDist = length(sample2Light) + 1;
        // 当距离小于于1 时 取倒数后光强会非常大，因此将得到得距离+1
        float sample2LightDistInv = 1.0 / sample2LightDist;
        
        // 采样点的光强， 与采样点到体积光源的距离平方成反比
        float sampleLigheIntensity = sample2LightDistInv * sample2LightDistInv * lightIntensity;

        // final
        finalLight += _VolumetricLightColor.xyz * sampleLigheIntensity * isInLight; //sampleLigheIntensity * isInLight * mie * pBeerLambert;
        // 采样点处的米氏散射 角度余弦
        // float cosTheta = dot(sample2LightNorm, viewDir);
        // float3 mie = MieScatter(cosTheta, g, betaM);

        // 透光率
        // float pBeerLambert = BeerLambert(0.5, view2DestDist - stepDist, sampleLigheIntensity);

        // shadow
        // todo

    }

    return finalLight ;
}





#endif