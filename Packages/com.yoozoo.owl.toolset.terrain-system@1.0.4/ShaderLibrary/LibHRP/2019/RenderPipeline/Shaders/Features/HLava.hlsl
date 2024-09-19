/***************************************************************************************************
*
* 熔岩相关代码
* 
* 算法      梯度算法，FBM算法，颜色转法线算法
*
*
* 额外参数的意义说明
* _NoiseParams			X:颜色噪声Tiling,Y:法线Tiling,Z:分型层数,W:扰动速度
* _DeltaScale			生成法线的梯度缩放
* _HeightScale			生成法线的高度缩放
* _MaskTex				噪声贴图
* _EmisCol				熔岩颜色
* _EmisMapPow			熔岩范围映射
* _EmisColIntensity		熔岩强度
* 
* 用法      
* Gradn()				计算梯度
* Flow()				产生Flow灰度图
* GetColor()			映射灰度图到颜色
* GetNormalByGray()		从颜色生成法线
***************************************************************************************************/

#ifndef HRP_LAVA_INCLUDED
#define HRP_LAVA_INCLUDED

float4 _NoiseParams,_EmisCol;
float _DeltaScale;
float _HeightScale,_EmisMapPow,_EmisColIntensity;
sampler2D  _MaskTex;

#define time _Time.y * _NoiseParams.w

float Noise(float2 uv)
{
	return tex2D(_MaskTex, uv*_NoiseParams.x).r;
}

float2 Gradn(float2 p)
{
	float ep = .09;
	float gradx = Noise(float2(p.x+ep,p.y))-Noise(float2(p.x-ep,p.y));
	float grady = Noise(float2(p.x,p.y+ep))-Noise(float2(p.x,p.y-ep));
	return float2(gradx,grady);
}

float FlowHigh(float2 p)
{
	float z=2.;
	float rz = 0.;
	float2 bp = p;
	for (float i= 1.;i < _NoiseParams.z;i++ )
	{
		p += time*.6;

		bp += time*1.9;

		float2 gr = Gradn(i*p*.34+time*1.);

		gr = UVRotate(time*60.-(0.05*p.x+0.03*p.y)*40.0 ,gr);

		p += gr * .5;

		rz+= (sin(Noise(p)*7.)*0.5+0.5)/z;

		p = lerp(bp,p,.77);

		z *= 1.4;
		p *= 2.;
		bp *= 1.9;
	}
	return rz;	
}

float Flow(float2 p,float octave)
{
	float z=2.;
	float rz = 0.;
	float2 bp = p;
	for (float i= 1.;i < octave;i++ )
	{
		p -= 0.5;

		p = UVRotate((time / (i * 100))-(0.05*p.x*0.03*p.y),p);

		p += 0.5;

		rz+= (sin(Noise(p)*7.)*0.5+0.5)/z;

		p = lerp(bp,p,.77);

		z *= 1.4;
		p *= 2.0;
		bp *= 1.9;
	}
	return rz;	
}


float3 GetColor(float2 uv,float3 col,float octave)
{
	float rz = Flow(uv.xy,octave);
    float3 deepCol = pow(abs(col.rgb / rz), _EmisMapPow) * _EmisColIntensity;

	return deepCol;
}

float3 GetNormalByGray(float2 uv,sampler2D _Tex)
{   
    float2 deltaU = float2(_DeltaScale, 0);
    float h1_u = Luminance(tex2D(_Tex,uv - deltaU).rgb);
    float h2_u = Luminance(tex2D(_Tex,uv + deltaU).rgb);

    float3 tangent_u = float3(deltaU.x, 0, _HeightScale * (h2_u - h1_u));

    float2 deltaV = float2(0, _DeltaScale);
    float h1_v = Luminance(tex2D(_Tex,uv - deltaV).rgb);
    float h2_v = Luminance(tex2D(_Tex,uv + deltaV).rgb);

    float3 tangent_v = float3(0, deltaV.y, _HeightScale * (h2_v - h1_v));

    float3 normal = normalize(cross(tangent_v, tangent_u));

	normal.z *= -1;

    return normal;
}
			

#endif
