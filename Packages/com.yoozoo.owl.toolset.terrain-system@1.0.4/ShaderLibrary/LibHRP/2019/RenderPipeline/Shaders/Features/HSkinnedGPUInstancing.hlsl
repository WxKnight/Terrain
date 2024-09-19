/***************************************************************************************************
*
* Skinned GPU Instancing 相关代码
*

rely

***************************************************************************************************/


#ifndef _TA_SKINNED_GPUINSTANCING_CGINC__
#define _TA_SKINNED_GPUINSTANCING_CGINC__

sampler2D _AnimationTex;
float4 _AnimationTex_ST;

float4 _AnimationTexSize;

#define DECLARE_SKINNED_MESH_INSTANCING_PARAM	\
UNITY_DEFINE_INSTANCED_PROP(float, _FrameIndex)


float4x4 GetSkinnedTransformMatrix(float frameIndex, float4 uv1, float4 uv2)
{
	float4x4 matrices0;
	matrices0._11_12_13_14 = tex2Dlod(_AnimationTex, float4(frameIndex, uv1.x * 4.0 / _AnimationTexSize.y + 0.5 / _AnimationTexSize.y, 0, 0));
	matrices0._21_22_23_24 = tex2Dlod(_AnimationTex, float4(frameIndex, uv1.x * 4.0 / _AnimationTexSize.y + 1.5 / _AnimationTexSize.y, 0, 0));
	matrices0._31_32_33_34 = tex2Dlod(_AnimationTex, float4(frameIndex, uv1.x * 4.0 / _AnimationTexSize.y + 2.5 / _AnimationTexSize.y, 0, 0));
	matrices0 = matrices0 * 2 - 1;
	matrices0._41_42_43_44 = float4(0, 0, 0, 1);

	float4x4 matrices1;
	matrices1._11_12_13_14 = tex2Dlod(_AnimationTex, float4(frameIndex, uv1.z * 4.0 / _AnimationTexSize.y + 0.5 / _AnimationTexSize.y, 0, 0));
	matrices1._21_22_23_24 = tex2Dlod(_AnimationTex, float4(frameIndex, uv1.z * 4.0 / _AnimationTexSize.y + 1.5 / _AnimationTexSize.y, 0, 0));
	matrices1._31_32_33_34 = tex2Dlod(_AnimationTex, float4(frameIndex, uv1.z * 4.0 / _AnimationTexSize.y + 2.5 / _AnimationTexSize.y, 0, 0));
	matrices1 = matrices1 * 2 - 1;
	matrices1._41_42_43_44 = float4(0, 0, 0, 1);

	float4x4 matrices2;
	matrices2._11_12_13_14 = tex2Dlod(_AnimationTex, float4(frameIndex, uv2.x * 4.0 / _AnimationTexSize.y + 0.5 / _AnimationTexSize.y, 0, 0));
	matrices2._21_22_23_24 = tex2Dlod(_AnimationTex, float4(frameIndex, uv2.x * 4.0 / _AnimationTexSize.y + 1.5 / _AnimationTexSize.y, 0, 0));
	matrices2._31_32_33_34 = tex2Dlod(_AnimationTex, float4(frameIndex, uv2.x * 4.0 / _AnimationTexSize.y + 2.5 / _AnimationTexSize.y, 0, 0));
	matrices2 = matrices2 * 2 - 1;
	matrices2._41_42_43_44 = float4(0, 0, 0, 1);

	float4x4 matrices3;
	matrices3._11_12_13_14 = tex2Dlod(_AnimationTex, float4(frameIndex, uv2.z * 4.0 / _AnimationTexSize.y + 0.5 / _AnimationTexSize.y, 0, 0));
	matrices3._21_22_23_24 = tex2Dlod(_AnimationTex, float4(frameIndex, uv2.z * 4.0 / _AnimationTexSize.y + 1.5 / _AnimationTexSize.y, 0, 0));
	matrices3._31_32_33_34 = tex2Dlod(_AnimationTex, float4(frameIndex, uv2.z * 4.0 / _AnimationTexSize.y + 2.5 / _AnimationTexSize.y, 0, 0));
	matrices3 = matrices3 * 2 - 1;
	matrices3._41_42_43_44 = float4(0, 0, 0, 1);


	float4x4 matrixFinal = matrices0 * uv1.y + matrices1 * uv1.w + matrices2 * uv2.y + matrices3 * uv2.w;
	matrixFinal._41_42_43_44 = float4(0, 0, 0, 1);
	return matrixFinal;
}

#endif
