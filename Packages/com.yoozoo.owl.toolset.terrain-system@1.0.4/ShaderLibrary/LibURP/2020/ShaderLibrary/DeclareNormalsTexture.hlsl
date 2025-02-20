#ifndef UNITY_DECLARE_NORMALS_TEXTURE_INCLUDED
#define UNITY_DECLARE_NORMALS_TEXTURE_INCLUDED
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/AdapterURP/ShaderLibrary/Core.hlsl"

TEXTURE2D_X_FLOAT(_CameraNormalsTexture);
SAMPLER(sampler_CameraNormalsTexture);

float3 SampleSceneNormals(float2 uv)
{
    return UnpackNormalOctRectEncode(SAMPLE_TEXTURE2D_X(_CameraNormalsTexture, sampler_CameraNormalsTexture, UnityStereoTransformScreenSpaceTex(uv)).xy) * float3(1.0, 1.0, -1.0);
}

float3 LoadSceneNormals(uint2 uv)
{
    return UnpackNormalOctRectEncode(LOAD_TEXTURE2D_X(_CameraNormalsTexture, uv).xy) * float3(1.0, 1.0, -1.0);
}
#endif
