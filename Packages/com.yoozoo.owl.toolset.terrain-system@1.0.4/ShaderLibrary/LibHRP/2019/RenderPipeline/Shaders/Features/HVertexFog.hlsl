/***************************************************************************************************
*
* 雾效相关代码
* 
* 算法                  计算观察点到物体点的直线距离 以及观察点与物体点的垂直距离，根据观察点与物体点的垂直距离、直线距离和雾高度计算雾的权重 w 
*                       权重为 1 时没有雾，权重为 0 时只有雾
*                       观察点俯视时雾越淡
* 
* 全局参数的意义说明
* _m_FogHeight;         雾能达到的高度
* _m_FogDensity;        雾整体表现的强度
* _m_FogHeightFallOff;  雾在高度上的衰减
* _m_FogMaxOpacity;     最大透明度 为 0 时没有雾)
* _m_FogStartDistance;  开始计算雾的起点 为 0 时 计算雾的距离从相机开始
* _m_FogCutoffDistance; 雾在高度上的截断位置    截断时修改雾的权重为 0  即符合截断条件的点没有雾 (已删除)
* _m_FogColor;          雾的颜色
* 
* 用法
* CalculateVertexFog（） 函数传入模型空间的顶点坐标，用于计算相机到顶点的向量（为规避精度不足，不直接调用v2f的half3 viewDir); 返回一个四维向量，前三维为雾的颜色，第四维 w 用来控制插值，w 越大，雾的成分越少
* GetVertexFogFColor（） 函数传入一个物体本来计算好的三维颜色向量和 CalculateVertexFog（） 函数计算出的雾的四维颜色向量；返回插值后的最终三维颜色向量
***************************************************************************************************/


#ifndef HRP_VERTEX_FOG_INCLUDED
#define HRP_VERTEX_FOG_INCLUDED


// Parameter declare
// Passed in SetupVertexFogPass.cs
uniform float    _m_FogHeight;
uniform float    _m_FogDensity;
uniform float    _m_FogHeightFallOff;
uniform half    _m_FogMaxOpacity;
uniform float    _m_FogStartDistance;
//uniform float    _m_FogCutoffDistance;
uniform half4   _m_FogColor;


// for vs
inline half4 CalculateVertexFog(float3 objVertPos)
{
    half3 fogCol = _m_FogColor.rgb;
    float fogDensity = _m_FogDensity; //a
    float fogNear = _m_FogStartDistance; //tMin
    //float fogFar = _m_FogCutoffDistance;//tMax, unnecessary
    float fogFallOff = _m_FogHeightFallOff; //b
    float fogStartHeight = _m_FogHeight; //yMin
    half fogMinOpacity = 1.0 - _m_FogMaxOpacity;

    //Re-calculate (-viewDir) as float for more precision 
    float3 wPos = TransformObjectToWorld(objVertPos);
    float3 cameraToReceiver = wPos - _WorldSpaceCameraPos.xyz; 

    float cameraToReceiverY = cameraToReceiver.y;
    float cameraToReceiverLength = length(cameraToReceiver);

    float fogNearY = _WorldSpaceCameraPos.y;
    float fogNearToRecLength = cameraToReceiverLength;

    if (fogNear > 0)
    {
        float fogNearToReceiverY = fogNear / cameraToReceiverLength;
        float camToFogNearY = fogNearToReceiverY * cameraToReceiverY;
        float fogNearY = fogNearY/*cameraY*/ + camToFogNearY;

        fogNearToRecLength = (1.0 - fogNearToReceiverY) * fogNearToRecLength;
    }

    float bY = max(-127, fogFallOff * (fogNearY - fogStartHeight));
    float exponent = fogDensity * exp2(-bY * 0.1);

    float bKy = max(-127, fogFallOff * cameraToReceiverY + 0.001);
    float integral = (1 - exp2(-bKy * 0.1)) / bKy;

    //to flip & emphasize the curve at lower values, using Pow( Exp2(-exp), 2); 
    //VS: e = pow(2, -exp); => FSe: f = pow(1 - e, 2);
    float fogFac = max(saturate(exp2(-exponent * integral * fogNearToRecLength)), fogMinOpacity);

    return half4(fogCol, fogFac);
}

//for fs
inline half3 GetVertexFogFColor(half3 originCol, half4 fog)
{
    half3 color = lerp(originCol, half3(fog.xyz * (1 - fog.w)), (1 - fog.w));
    return color;
}


#endif
