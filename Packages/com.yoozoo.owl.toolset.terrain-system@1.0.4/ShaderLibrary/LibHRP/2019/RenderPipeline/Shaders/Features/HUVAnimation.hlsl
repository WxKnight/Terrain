/***************************************************************************************************
*
* UV 动画相关代码
*
***************************************************************************************************/


#ifndef HRP_UV_ANIMATION_INCLUDED
#define HRP_UV_ANIMATION_INCLUDED


/*********************************
* Anim Function
*********************************/

inline half2 UVAnimation(half2 originUV, float currentTime, half4 uvFactor)
{
    return originUV + sin(uvFactor.xy * currentTime) * uvFactor.zw;
}

inline half2 PackV2FForUVAnimation(half2 originUV, half4 uvFactor)
{
    half2 uvAni = UVAnimation(originUV, _Time.y, uvFactor); //UVAnimation(v, o.uv0);
    return uvAni;
}

float2 UVRotate(float theta,half2 originUV)
{
	float c = cos(theta);
	float s = sin(theta);
	return mul(float2x2(c,-s,s,c),originUV);
}

#endif
