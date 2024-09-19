/***************************************************************************************************
 *
 * 软粒子
 *
***************************************************************************************************/


#ifndef HRP_SOFT_PARTICLE_INCLUDED
#define HRP_SOFT_PARTICLE_INCLUDED


/***************************************************************************************************
 * Region : AlphaTest Get Surf Data Related Functions
 ***************************************************************************************************/

#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"


sampler2D _CameraDepthTexture;

inline float4 CalculateProjectPos(float4 clipPos, float4 vertexPos) {
    float4 projPos = ComputeScreenPos(clipPos);
    projPos.z = -TransformWorldToView(TransformObjectToWorld(vertexPos.xyz)).z;    // COMPUTE_EYEDEPTH
    return projPos;
}


inline float CalculateFade(float4 projPos, float invFaceScale) {
    float depth  = tex2Dproj(_CameraDepthTexture, projPos).r;
    float sceneZ = LinearEyeDepth(depth, _ZBufferParams);
    return saturate(invFaceScale * (sceneZ - projPos.z));
}

#endif
