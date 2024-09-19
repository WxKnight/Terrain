// Copy From PluginPackages/SoftMaskForUGUI/Shaders/SoftMask.cginc

#ifndef HRP_SOFT_MASK_INCLUDED
#define HRP_SOFT_MASK_INCLUDED

sampler2D   _SoftMaskTex;
float       _Stencil;
half4       _MaskInteraction;

half Approximately(float4x4 a, float4x4 b)
{
    float4x4 d = abs(a - b);
    return step(
        max(d._m00, max(d._m01, max(d._m02, max(d._m03,
        max(d._m10, max(d._m11, max(d._m12, max(d._m13,
        max(d._m20, max(d._m21, max(d._m22,//max(d._m23,
        max(d._m30, max(d._m31, max(d._m32, d._m33)))))))))))))),
        0.01);
}

float GetMaskAlpha(float alpha, int stencilId, float interaction)
{
    half onStencil = step(stencilId, _Stencil);
    alpha = lerp(1, alpha, onStencil * step(1, interaction));
    return lerp(alpha, 1 - alpha, onStencil * step(2, interaction));
}


float SoftMaskInternal(float4 clipPos)
{
    half2 view = clipPos.xy / _ScreenParams.xy;

#if UNITY_UV_STARTS_AT_TOP
    view.y = lerp(view.y, 1 - view.y, step(0, _ProjectionParams.x));
#endif

    half4 mask = tex2D(_SoftMaskTex, view);
    half alpha = GetMaskAlpha(mask.x, 1, _MaskInteraction.x)
        * GetMaskAlpha(mask.y, 3, _MaskInteraction.y)
        * GetMaskAlpha(mask.z, 7, _MaskInteraction.z)
        * GetMaskAlpha(mask.w, 15, _MaskInteraction.w);

    return alpha;
}


#define SOFTMASK_EDITOR_ONLY(x) 
#define SoftMask(clipPos, worldPosition) SoftMaskInternal(clipPos)


#endif // UI_SOFTMASK_INCLUDED