/***************************************************************************************************
*
* IncludeVertexColor 相关代码, 包含顶点色时的相关计算
*
*使用示例
*       #include "../../Features/HIncludeVertexColor.hlsl"
*
*
*       HV2F vert(HAppData appdata)
*       {
*           HV2F o = BFP_CreateV2FData(...);
*           o.color = PackV2FIncludeVertCol(appdata.color, _Color);
*           return o;
*       }
*
*
*       float4 frag(HV2F i) : SV_Target
*      {
*           ...
*           SurfaceParam surface = ExtractPBRSurfaceParam(...);
*           surface.diffuseColor = SurfDataIncludeVertCol(surface.diffuseColor, i.color);
*           ...
*       }

***************************************************************************************************/


#ifndef HRP_INCLUDE_VERTEX_COLOR_INCLUDED
#define HRP_INCLUDE_VERTEX_COLOR_INCLUDED

inline half4 PackV2FIncludeVertCol(half4 appDataCol, half4 colorProp) {
    half4 vcolor = appDataCol * appDataCol * colorProp;
    vcolor.xyz = vcolor.xyz * appDataCol.xyz;

    return vcolor;
}

inline half3 SurfDataIncludeVertCol(half3 diffCol, half4 v2fCol)
{
    return diffCol * v2fCol.rgb;

}

#endif
