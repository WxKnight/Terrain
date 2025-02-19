#ifndef TERRAIN_SYSTEM_HRP_TERRAIN_LIT_PASSES_INCLUDED
#define TERRAIN_SYSTEM_HRP_TERRAIN_LIT_PASSES_INCLUDED
float4 Hash4(float2 p) {
	return frac(sin(float4(1.0 + dot(p, float2(37.0, 17.0)),
		2.0 + dot(p, float2(11.0, 47.0)),
		3.0 + dot(p, float2(41.0, 29.0)),
		4.0 + dot(p, float2(23.0, 31.0))))*103.0);
}

half4 TextureNoTile(TEXTURE2D(tex), SAMPLER(samp), in half2 uv)
{
	half2 iuv = half2(floor(uv));
	half2 fuv = frac(uv);

	// generate per-tile transform
	half4 ofa = Hash4(iuv + half2(0, 0));
	half4 ofb = Hash4(iuv + half2(1, 0));
	half4 ofc = Hash4(iuv + half2(0, 1));
	half4 ofd = Hash4(iuv + half2(1, 1));

	half2 ddxUV = ddx(uv);
	half2 ddyUV = ddy(uv);

	// transform per-tile uvs
	ofa.zw = sign(ofa.zw - 0.5);
	ofb.zw = sign(ofb.zw - 0.5);
	ofc.zw = sign(ofc.zw - 0.5);
	ofd.zw = sign(ofd.zw - 0.5);

	// uv's, and derivatives (for correct mipmapping)
	half2 uva = uv * ofa.zw + ofa.xy, ddxa = ddxUV * ofa.zw, ddya = ddyUV * ofa.zw;
	half2 uvb = uv * ofb.zw + ofb.xy, ddxb = ddxUV * ofb.zw, ddyb = ddyUV * ofb.zw;
	half2 uvc = uv * ofc.zw + ofc.xy, ddxc = ddxUV * ofc.zw, ddyc = ddyUV * ofc.zw;
	half2 uvd = uv * ofd.zw + ofd.xy, ddxd = ddxUV * ofd.zw, ddyd = ddyUV * ofd.zw;

	// fetch and blend
	half2 b = smoothstep(0, 1, fuv);

	return lerp(lerp(SAMPLE_TEXTURE2D_GRAD(tex, samp, uva , ddxa , ddya),
		SAMPLE_TEXTURE2D_GRAD(tex, samp, uvb , ddxb , ddyb), b.x),
		lerp(SAMPLE_TEXTURE2D_GRAD(tex, samp, uvc , ddxc , ddyc),
			SAMPLE_TEXTURE2D_GRAD(tex, samp, uvd , ddxd, ddyd), b.x), b.y);
}

half4 SampleTex(TEXTURE2D(tex), SAMPLER(samp), in half2 uv) {
#ifdef _TERRAIN_ANTI_TILING
	return TextureNoTile(tex, samp, uv);
#else
	return SAMPLE_TEXTURE2D(tex, samp, uv);
#endif
}


#ifndef TERRAIN_SPLAT_BASEPASS
void SplatmapMix0(float4 uvSplat01, float4 uvSplat23, inout half4 splatControl, inout half4 mixedDiffuse, inout half3 mixedNormal, inout half4 defaultSmoothness)
{
	half4 diffAlbedo[4];
    diffAlbedo[0] = SampleTex(_Splat0, sampler_Splat0, uvSplat01.xy);
    diffAlbedo[1] = SampleTex(_Splat1, sampler_Splat0, uvSplat01.zw);
    diffAlbedo[2] = SampleTex(_Splat2, sampler_Splat0, uvSplat23.xy);
    diffAlbedo[3] = SampleTex(_Splat3, sampler_Splat0, uvSplat23.zw);

    mixedDiffuse += diffAlbedo[0] * half4(_DiffuseRemapScale0.rgb * splatControl.rrr, 1.0h);
    mixedDiffuse += diffAlbedo[1] * half4(_DiffuseRemapScale1.rgb * splatControl.ggg, 1.0h);
    mixedDiffuse += diffAlbedo[2] * half4(_DiffuseRemapScale2.rgb * splatControl.bbb, 1.0h);
    mixedDiffuse += diffAlbedo[3] * half4(_DiffuseRemapScale3.rgb * splatControl.aaa, 1.0h);

    // This might be a bit of a gamble -- the assumption here is that if the diffuseMap has no
    // alpha channel, then diffAlbedo[n].a = 1.0 (and _DiffuseHasAlphaN = 0.0)
    // Prior to coming in, _SmoothnessN is actually set to max(_DiffuseHasAlphaN, _SmoothnessN)
    // This means that if we have an alpha channel, _SmoothnessN is locked to 1.0 and
    // otherwise, the true slider value is passed down and diffAlbedo[n].a == 1.0.
    defaultSmoothness = half4(diffAlbedo[0].a, diffAlbedo[1].a, diffAlbedo[2].a, diffAlbedo[3].a);
    defaultSmoothness *= half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);

#ifdef _NORMALMAP
    mixedNormal += splatControl.r * UnpackNormalScale(SampleTex(_Normal0, sampler_Normal0, uvSplat01.xy), _NormalScale0);
    mixedNormal += splatControl.g * UnpackNormalScale(SampleTex(_Normal1, sampler_Normal0, uvSplat01.zw), _NormalScale1);
    mixedNormal += splatControl.b * UnpackNormalScale(SampleTex(_Normal2, sampler_Normal0, uvSplat23.xy), _NormalScale2);
    mixedNormal += splatControl.a * UnpackNormalScale(SampleTex(_Normal3, sampler_Normal0, uvSplat23.zw), _NormalScale3);
#endif
}

void SplatmapMix0Triplanar(float4 uvTriplanar, float3 normal, float4 uvSplat01, float4 uvSplat23, inout half4 splatControl, inout half4 mixedDiffuse, inout half3 mixedNormal, inout half4 defaultSmoothness)
{
	half4 diffAlbedoXZ[4];
	diffAlbedoXZ[0] = SampleTex(_Splat0, sampler_Splat0, uvSplat01.xy);
	diffAlbedoXZ[1] = SampleTex(_Splat1, sampler_Splat0, uvSplat01.zw);
	diffAlbedoXZ[2] = SampleTex(_Splat2, sampler_Splat0, uvSplat23.xy);
	diffAlbedoXZ[3] = SampleTex(_Splat3, sampler_Splat0, uvSplat23.zw);

	half4 diffAlbedoXY[4];
	diffAlbedoXY[0] = SampleTex(_Splat0, sampler_Splat0, uvSplat01.xy * uvTriplanar.xy * float2(1, -sign(normal.z)));
	diffAlbedoXY[1] = SampleTex(_Splat1, sampler_Splat0, uvSplat01.zw * uvTriplanar.xy * float2(1, -sign(normal.z)));
	diffAlbedoXY[2] = SampleTex(_Splat2, sampler_Splat0, uvSplat23.xy * uvTriplanar.xy * float2(1, -sign(normal.z)));
	diffAlbedoXY[3] = SampleTex(_Splat3, sampler_Splat0, uvSplat23.zw * uvTriplanar.xy * float2(1, -sign(normal.z)));
                                                                                                               
	half4 diffAlbedoYZ[4];                                                                                     
	diffAlbedoYZ[0] = SampleTex(_Splat0, sampler_Splat0, uvSplat01.xy * uvTriplanar.yz * float2(-sign(normal.x), 1));
	diffAlbedoYZ[1] = SampleTex(_Splat1, sampler_Splat0, uvSplat01.zw * uvTriplanar.yz * float2(-sign(normal.x), 1));
	diffAlbedoYZ[2] = SampleTex(_Splat2, sampler_Splat0, uvSplat23.xy * uvTriplanar.yz * float2(-sign(normal.x), 1));
	diffAlbedoYZ[3] = SampleTex(_Splat3, sampler_Splat0, uvSplat23.zw * uvTriplanar.yz * float2(-sign(normal.x), 1));

    //float3 absNormal = abs(normal);
    //half tripWeight = dot(absNormal, float3(1,1,1));
    //half tripWeightX = absNormal.x / tripWeight;
    //half tripWeightY = absNormal.y / tripWeight;
    //half tripWeightZ = absNormal.z / tripWeight;
    
    half tripWeightX = dot(normal.x, normal.x);
    half tripWeightY = dot(normal.y, normal.y);
    half tripWeightZ = dot(normal.z, normal.z);

	half4 diffAlbedo[4];
	diffAlbedo[0] = tripWeightX * diffAlbedoYZ[0] + tripWeightY * diffAlbedoXZ[0] + tripWeightZ * diffAlbedoXY[0];
	diffAlbedo[1] = tripWeightX * diffAlbedoYZ[1] + tripWeightY * diffAlbedoXZ[1] + tripWeightZ * diffAlbedoXY[1];
	diffAlbedo[2] = tripWeightX * diffAlbedoYZ[2] + tripWeightY * diffAlbedoXZ[2] + tripWeightZ * diffAlbedoXY[2];
	diffAlbedo[3] = tripWeightX * diffAlbedoYZ[3] + tripWeightY * diffAlbedoXZ[3] + tripWeightZ * diffAlbedoXY[3];

    mixedDiffuse += diffAlbedo[0] * half4(_DiffuseRemapScale0.rgb * splatControl.rrr, 1.0h);
    mixedDiffuse += diffAlbedo[1] * half4(_DiffuseRemapScale1.rgb * splatControl.ggg, 1.0h);
    mixedDiffuse += diffAlbedo[2] * half4(_DiffuseRemapScale2.rgb * splatControl.bbb, 1.0h);
    mixedDiffuse += diffAlbedo[3] * half4(_DiffuseRemapScale3.rgb * splatControl.aaa, 1.0h);

    // This might be a bit of a gamble -- the assumption here is that if the diffuseMap has no
    // alpha channel, then diffAlbedo[n].a = 1.0 (and _DiffuseHasAlphaN = 0.0)
    // Prior to coming in, _SmoothnessN is actually set to max(_DiffuseHasAlphaN, _SmoothnessN)
    // This means that if we have an alpha channel, _SmoothnessN is locked to 1.0 and
    // otherwise, the true slider value is passed down and diffAlbedo[n].a == 1.0.
    defaultSmoothness = half4(diffAlbedo[0].a, diffAlbedo[1].a, diffAlbedo[2].a, diffAlbedo[3].a);
    defaultSmoothness *= half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);

#ifdef _NORMALMAP
	half3 normalXZ[4];
	normalXZ[0] = UnpackNormalScale(SampleTex(_Normal0, sampler_Normal0, uvSplat01.xy), _NormalScale0);
	normalXZ[1] = UnpackNormalScale(SampleTex(_Normal1, sampler_Normal0, uvSplat01.zw), _NormalScale1);
	normalXZ[2] = UnpackNormalScale(SampleTex(_Normal2, sampler_Normal0, uvSplat23.xy), _NormalScale2);
	normalXZ[3] = UnpackNormalScale(SampleTex(_Normal3, sampler_Normal0, uvSplat23.zw), _NormalScale3);
                                                              
	half3 normalXY[4];                                        
	normalXY[0] = UnpackNormalScale(SampleTex(_Normal0, sampler_Normal0, uvSplat01.xy * uvTriplanar.xy * float2(1, -sign(normal.z))), _NormalScale0);
	normalXY[1] = UnpackNormalScale(SampleTex(_Normal1, sampler_Normal0, uvSplat01.zw * uvTriplanar.xy * float2(1, -sign(normal.z))), _NormalScale1);
	normalXY[2] = UnpackNormalScale(SampleTex(_Normal2, sampler_Normal0, uvSplat23.xy * uvTriplanar.xy * float2(1, -sign(normal.z))), _NormalScale2);
	normalXY[3] = UnpackNormalScale(SampleTex(_Normal3, sampler_Normal0, uvSplat23.zw * uvTriplanar.xy * float2(1, -sign(normal.z))), _NormalScale3);
                                                                                                                               
	half3 normalYZ[4];                                                                                                         
	normalYZ[0] = UnpackNormalScale(SampleTex(_Normal0, sampler_Normal0, uvSplat01.xy * uvTriplanar.yz * float2(-sign(normal.x), 1)), _NormalScale0);
	normalYZ[1] = UnpackNormalScale(SampleTex(_Normal1, sampler_Normal0, uvSplat01.zw * uvTriplanar.yz * float2(-sign(normal.x), 1)), _NormalScale1);
	normalYZ[2] = UnpackNormalScale(SampleTex(_Normal2, sampler_Normal0, uvSplat23.xy * uvTriplanar.yz * float2(-sign(normal.x), 1)), _NormalScale2);
	normalYZ[3] = UnpackNormalScale(SampleTex(_Normal3, sampler_Normal0, uvSplat23.zw * uvTriplanar.yz * float2(-sign(normal.x), 1)), _NormalScale3);

	half3 normals[4];
	normals[0] = tripWeightX * normalYZ[0] + tripWeightY * normalXZ[0] + tripWeightZ * normalXY[0];
	normals[1] = tripWeightX * normalYZ[1] + tripWeightY * normalXZ[1] + tripWeightZ * normalXY[1];
	normals[2] = tripWeightX * normalYZ[2] + tripWeightY * normalXZ[2] + tripWeightZ * normalXY[2];
	normals[3] = tripWeightX * normalYZ[3] + tripWeightY * normalXZ[3] + tripWeightZ * normalXY[3];

    mixedNormal += splatControl.r * normals[0];
    mixedNormal += splatControl.g * normals[1];
    mixedNormal += splatControl.b * normals[2];
    mixedNormal += splatControl.a * normals[3];
#endif
}

#endif


struct Varyings
{
    float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
    float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
	float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3

#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    float4 normal                   : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangent                  : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangent                : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    float3 normal                   : TEXCOORD3;
    float3 viewDir                  : TEXCOORD4;
    half3 vertexSH                  : TEXCOORD5; // SH
#endif

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
    float3 positionWS               : TEXCOORD7;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD8;
#endif
#ifdef _TERRAIN_BLEND_TRIPLANAR
    float4 uvTriplanar              : TEXCOORD9;
#endif


    float4 clipPos                  : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};


void HeightBasedSplatModify(inout half4 splatControl0, in half4 masks0[4])
{
#ifndef _TERRAIN_BLEND_HEIGHT
    return;
#else
    // heights are in mask blue channel, we multiply by the splat Control weights to get combined height
    //half4 splatHeight = half4(masks[0].b, masks[1].b, masks[2].b, masks[3].b) * splatControl.rgba;
	half4 splatHeight0 = half4(masks0[0].b, masks0[1].b, masks0[2].b, masks0[3].b) * splatControl0.rgba;

    
    //half maxHeight = max(splatHeight.r, max(splatHeight.g, max(splatHeight.b, splatHeight.a)));
	half maxHeight = 0;
	maxHeight = max(maxHeight, max(splatHeight0.r, max(splatHeight0.g, max(splatHeight0.b, splatHeight0.a))));


    // Ensure that the transition height is not zero.
    half transition = max(_HeightTransition, 1e-5);

    // This sets the highest splat to "transition", and everything else to a lower value relative to that, clamping to zero
    // Then we clamp this to zero and normalize everything
    //half4 weightedHeights = splatHeight + transition - maxHeight.xxxx;
    //weightedHeights = max(0, weightedHeights);
    // We need to add an epsilon here for active layers (hence the blendMask again)
    // so that at least a layer shows up if everything's too low.
    //weightedHeights = (weightedHeights + 1e-6) * splatControl;
	half4 weightedHeights0 = splatHeight0 + transition - maxHeight.xxxx;
	weightedHeights0 = max(0, weightedHeights0);
	weightedHeights0 = (weightedHeights0 + 1e-6) * splatControl0;



    // Normalize (and clamp to epsilon to keep from dividing by zero)
    //half sumHeight = max(dot(weightedHeights, half4(1, 1, 1, 1)), 1e-6);
	half sumHeight = 1e-6;
	sumHeight += max(dot(weightedHeights0, half4(1,1,1,1)), 0);


    //splatControl = weightedHeights / sumHeight.xxxx;
	splatControl0 = weightedHeights0 / sumHeight.xxxx;

#endif
}


#ifdef _BAKE_VARYING
void ComputeMasks0(inout half4 masks[4], half4 hasMask, BakeVaryings IN)
#else
void ComputeMasks0(inout half4 masks[4], half4 hasMask, Varyings IN)
#endif
{
    masks[0] = 0.5h;
    masks[1] = 0.5h;
    masks[2] = 0.5h;
    masks[3] = 0.5h;

#ifdef _MASKMAP
    //masks[0] = lerp(masks[0], SampleTex(_Mask0, sampler_Mask0, IN.uvSplat01.xy), hasMask.x);
	masks[0] = lerp(masks[0], SampleTex(_Mask0, sampler_Mask0, IN.uvSplat01.xy), hasMask.x);
	masks[1] = lerp(masks[1], SampleTex(_Mask1, sampler_Mask0, IN.uvSplat01.zw), hasMask.y);
	masks[2] = lerp(masks[2], SampleTex(_Mask2, sampler_Mask0, IN.uvSplat23.xy), hasMask.z);
	masks[3] = lerp(masks[3], SampleTex(_Mask3, sampler_Mask0, IN.uvSplat23.zw), hasMask.w);

#endif

    //masks[0] *= _MaskMapRemapScale0.rgba;
    //masks[0] += _MaskMapRemapOffset0.rgba;
	masks[0] *= _MaskMapRemapScale0.rgba;
	masks[0] += _MaskMapRemapOffset0.rgba;
	masks[1] *= _MaskMapRemapScale1.rgba;
	masks[1] += _MaskMapRemapOffset1.rgba;
	masks[2] *= _MaskMapRemapScale2.rgba;
	masks[2] += _MaskMapRemapOffset2.rgba;
	masks[3] *= _MaskMapRemapScale3.rgba;
	masks[3] += _MaskMapRemapOffset3.rgba;

}


#ifdef _BAKE_VARYING
void FetchSplat(BakeVaryings IN, inout half4 splatControl[1], inout half4 masks[1][4], inout half4 hasMask[1])
#else
void FetchSplat(Varyings IN, inout half4 splatControl[1], inout half4 masks[1][4], inout half4 hasMask[1])
#endif
{
	//**Fetch splatControl
	float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
	//half4 splatControl0 = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);
	splatControl[0] = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);


	//**Compute masks
	//hasMask = half4(_LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3);
	//half4 masks0[4];
	//ComputeMasks(masks0, hasMask, IN);
	hasMask[0] = half4(_LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3);
	ComputeMasks0(masks[0], hasMask[0], IN);


	//**Modify splat by mask
	//HeightBasedSplatModify(splatControl0, splatControl1, masks0, masks1);
	HeightBasedSplatModify(splatControl[0], masks[0]);
}


#ifdef _BAKE_VARYING
void TransformLayerUV(float2 texcoord, inout BakeVaryings o)
#else
void TransformLayerUV(float2 texcoord, inout Varyings o)
#endif
{
#ifndef TERRAIN_SPLAT_BASEPASS
    //o.uvSplat01.xy = TRANSFORM_TEX(texcoord, _Splat0);
    //o.uvSplat01.zw = TRANSFORM_TEX(texcoord, _Splat1);
	o.uvSplat01.xy = TRANSFORM_TEX(texcoord, _Splat0);
	o.uvSplat01.zw = TRANSFORM_TEX(texcoord, _Splat1);
	o.uvSplat23.xy = TRANSFORM_TEX(texcoord, _Splat2);
	o.uvSplat23.zw = TRANSFORM_TEX(texcoord, _Splat3);

#endif
}

void FetchMOS0(inout half metallic, inout half occlusion, inout half smoothness, half4 defaultSmoothness, half4 splatControl, half4 hasMask, half4 masks[4]){
    half4 defaultMetallic = half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3);
    half4 maskMetallic = half4(masks[0].r, masks[1].r, masks[2].r, masks[3].r);
    defaultMetallic = lerp(defaultMetallic, maskMetallic, hasMask);
    metallic += dot(splatControl, defaultMetallic);

    half4 defaultOcclusion = half4(_MaskMapRemapScale0.g, _MaskMapRemapScale1.g, _MaskMapRemapScale2.g, _MaskMapRemapScale3.g) +
                            half4(_MaskMapRemapOffset0.g, _MaskMapRemapOffset1.g, _MaskMapRemapOffset2.g, _MaskMapRemapOffset3.g);
    half4 maskOcclusion = half4(masks[0].g, masks[1].g, masks[2].g, masks[3].g);
    defaultOcclusion = lerp(defaultOcclusion, maskOcclusion, hasMask);
	occlusion += dot(splatControl, defaultOcclusion);

    half4 maskSmoothness = half4(masks[0].a, masks[1].a, masks[2].a, masks[3].a);
    defaultSmoothness = lerp(defaultSmoothness, maskSmoothness, hasMask);
    smoothness += dot(splatControl, defaultSmoothness);
}

#endif
