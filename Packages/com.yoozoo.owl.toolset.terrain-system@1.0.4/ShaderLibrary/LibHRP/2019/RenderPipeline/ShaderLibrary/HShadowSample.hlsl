#ifndef HRP_SHADOW_SAMPLE_INCLUDED
#define HRP_SHADOW_SAMPLE_INCLUDED


#ifndef _P30PROTECT_SHADOW
    uniform float _Disable_Depth;
    uniform float _Disable_Shadow;
    uniform float _Disable_Uniq_Shadow;
    uniform float _Disable_Additional_Shadow;
    #define _P30PROTECT_SHADOW
#endif



#if defined(_SUPPORT_SHADOWMAP_FORMAT)

    inline float TASampleShadowmap__(Texture2D tex, SamplerComparisonState sam, float2 xy, float z) {
#ifdef _UNIQUE_CHAR_SHADOW
        if (_Disable_Uniq_Shadow > 0.1)
            return 1;
#else
        if (_Disable_Shadow > 0.1)
            return 1;
#endif
        return tex.SampleCmpLevelZero(sam, xy, z);
    }


    // DX11 & hlslcc platforms: built-in PCF
    #define TA_SHADOWMAP_TEX(tex)                               Texture2D tex
    #define TA_SHADOWMAP_SAMPLER(sam)                           SamplerComparisonState sam
    #define TA_SAMPLE_SHADOWMAP(tex, sam, coordXY, coordZ)      TASampleShadowmap__(tex, sam, (coordXY), (coordZ))
    #define TA_SHADOWMAP_ARGS(tex, sam)                         Texture2D tex, SamplerComparisonState sam
    #define TA_SHADOWMAP_ARGS_INPUT(tex, sam)                   tex, sam

#else
    // Fallback / No built-in shadowmap comparison sampling: regular texture sample and do manual depth comparison

    inline float TASampleShadowmap__(sampler2D tex, float2 xy, float z) {
#ifdef _UNIQUE_CHAR_SHADOW
        if (_Disable_Uniq_Shadow > 0.1)
            return 1;
#else
        if (_Disable_Shadow > 0.1)
            return 1;
#endif
        return tex2D(tex, xy).r < z ? 1.0 : 0.0;
    }

    #define TA_SHADOWMAP_TEX(tex)                               sampler2D tex
    #define TA_SHADOWMAP_SAMPLER(sam)
    #define TA_SAMPLE_SHADOWMAP(tex, sam, coordXY, coordZ)      TASampleShadowmap__(tex, (coordXY), (coordZ))
    #define TA_SHADOWMAP_ARGS(tex, sam)                         sampler2D tex
    #define TA_SHADOWMAP_ARGS_INPUT(tex, sam)                   tex

#endif




#endif  // __TA_SHADOW_SAMPLE_HLSL__