#ifndef TERRAIN_SYSTEM_HRP_TERRAIN_LIT_INPUT_INCLUDED
#define TERRAIN_SYSTEM_HRP_TERRAIN_LIT_INPUT_INCLUDED
TEXTURE2D(_Control);     SAMPLER(sampler_Control);
TEXTURE2D(_Splat0);     SAMPLER(sampler_Splat0);
TEXTURE2D(_Splat1);
TEXTURE2D(_Splat2);
TEXTURE2D(_Splat3);
TEXTURE2D(_Normal0);     SAMPLER(sampler_Normal0);
TEXTURE2D(_Normal1);
TEXTURE2D(_Normal2);
TEXTURE2D(_Normal3);
TEXTURE2D(_Mask0);     SAMPLER(sampler_Mask0);
TEXTURE2D(_Mask1);
TEXTURE2D(_Mask2);
TEXTURE2D(_Mask3);
CBUFFER_START(_Terrain)
    //half _NormalScale0, _NormalScale1, _NormalScale2, _NormalScale3;
    half _NormalScale0, _NormalScale1, _NormalScale2, _NormalScale3;
    //half _Metallic0, _Metallic1, _Metallic2, _Metallic3;
    half _Metallic0, _Metallic1, _Metallic2, _Metallic3;
    //half _Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3;
    half _Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3;
    //half4 _DiffuseRemapScale0, _DiffuseRemapScale1, _DiffuseRemapScale2, _DiffuseRemapScale3;
    half4 _DiffuseRemapScale0, _DiffuseRemapScale1, _DiffuseRemapScale2, _DiffuseRemapScale3;
    //half4 _MaskMapRemapOffset0, _MaskMapRemapOffset1, _MaskMapRemapOffset2, _MaskMapRemapOffset3;
    half4 _MaskMapRemapOffset0, _MaskMapRemapOffset1, _MaskMapRemapOffset2, _MaskMapRemapOffset3;
    //half4 _MaskMapRemapScale0, _MaskMapRemapScale1, _MaskMapRemapScale2, _MaskMapRemapScale3;
    half4 _MaskMapRemapScale0, _MaskMapRemapScale1, _MaskMapRemapScale2, _MaskMapRemapScale3;

    float4 _Control_ST;
    float4 _Control_TexelSize;
    //half _DiffuseHasAlpha0, _DiffuseHasAlpha1, _DiffuseHasAlpha2, _DiffuseHasAlpha3;
    half _DiffuseHasAlpha0, _DiffuseHasAlpha1, _DiffuseHasAlpha2, _DiffuseHasAlpha3;
    //half _LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3;
    half _LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3;
    //half4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST, _Splat4_ST;
    half4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;

    #ifdef _TERRAIN_BLEND_TRIPLANAR
    half4 _TriplanarScale;
    #endif

    half _HeightTransition;
    half _NumLayersCount;

    #ifdef UNITY_INSTANCING_ENABLED
    float4 _TerrainHeightmapRecipSize;   // float4(1.0f/width, 1.0f/height, 1.0f/(width-1), 1.0f/(height-1))
    float4 _TerrainHeightmapScale;       // float4(hmScale.x, hmScale.y / (float)(kMaxHeight), hmScale.z, 0.0f)
    #endif
    #ifdef SCENESELECTIONPASS
    int _ObjectId;
    int _PassValue;
    #endif
CBUFFER_END

#endif
