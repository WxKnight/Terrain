/***************************************************************************************************
 * 
 * 提供数学工具
 * 包含常用数学工具，和矩阵向量运算工具（ 如果后续矩阵太多，可以考虑移出单列 ）
 *
 ***************************************************************************************************/


#ifndef HRP_MATH_UTILS_INCLUDED
#define HRP_MATH_UTILS_INCLUDED


#define E 2.71828f

inline half Pow3(half x)
{
    return x*x*x;
}

inline half Pow5(half x)
{
    return x*x*x*x*x;
}

inline half3 PerPixelWorldNormal(half3 normalTangent, half4 tangentToWorld[3])
{
    half3 tangent  = normalize(tangentToWorld[0].xyz);
    half3 binormal = normalize(tangentToWorld[1].xyz);
    half3 normal   = normalize(tangentToWorld[2].xyz);

    tangent = normalize(tangent - normal * dot(tangent, normal));
    float3 newB = cross(tangent, normal);
    binormal = newB * sign(dot(newB, binormal));

    return normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);
}

inline float N(float x) 
{
    return frac(sin(x*12345.564)*7658.76);
}

inline float Saw(float b, float x) 
{
    return smoothstep(0, b, x) * smoothstep(1, b, x);
}

inline float3 N13(float x) 
{
    float3 p3 = frac(float3(x, x, x) * float3(.1031, .11369, .13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac(float3((p3.x + p3.y)*p3.z, (p3.x + p3.z)*p3.y, (p3.y + p3.z)*p3.x));
}

#endif