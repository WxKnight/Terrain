/************************************************************************
*
* Author :	Cheng Gong
* Date   :	2019/11/12 18:29
* Description :
*			Subsurface Scatter 相关代码

* rely:
*		ExtractSubsurfaceParam;
*		CreateSubsurfaceScatterDir;
*		SubsurfaceScatterDefineLighting;
*		ApproximatePreintegrateCurveScatter;
*		ApproximateWrapLightScatter;
*		ThicknessTransmittance;
*		IndirectThicknessTransmittance;
*		SubsurfaceScatter;
*		IndirectSubsurfaceScatter;

需要按照如下方式使用：
*
*      HLSLPROGRAM
*      #include "../../Features/HSubsurfaceScatter.hlsl"
*      ...
*		...
*		}
*     
***************************************************************************************************/


#ifndef HRP_SUBSURFACE_SCATTER_INCLUDED
#define HRP_SUBSURFACE_SCATTER_INCLUDED

#include "../../ShaderLibrary/HLighting.hlsl"

struct SubsurfaceParam
{
	//scatter
	half3 scatterCol;
	half scatterRange;
	
	//transmittance
	half depth;
	half phase;
	half transLerp;

	//inner 
	half thick;
	half curve;
};

struct SubsurfaceDirs
{	
	half nDotL;
	half vDotL;
};

/***************************************************************************************************
 * Region :  bsdf parameters function
 ***************************************************************************************************/

inline SubsurfaceParam ExtractSubsurfaceParam(	sampler2D thickAndCurveTex, float2 uv, half3 scatterCol, 
												half scatterRange,half depth, half phase, half transLerp)
{
	SubsurfaceParam subsurface = (SubsurfaceParam)0;

	half4 thickAndCurve = tex2D(thickAndCurveTex, uv);

	subsurface.curve = saturate((thickAndCurve.g - 0.5 + scatterRange) * 2);
	subsurface.thick = max(1.0 - thickAndCurve.r + depth, 0.0);

	subsurface.scatterCol = scatterCol;
	subsurface.scatterRange = scatterRange;

	subsurface.depth = depth;
	subsurface.phase = phase;
	subsurface.transLerp = transLerp;

	return subsurface;
}

inline SubsurfaceDirs CreateSubsurfaceScatterDir(half3 lightDir, half3 worldNormal, half3 viewDir)
{	
	SubsurfaceDirs dirs = (SubsurfaceDirs)0;

	dirs.nDotL = dot(worldNormal, lightDir);
	dirs.vDotL = dot(-lightDir, viewDir);

	return dirs;
}

/***************************************************************************************************
 * Region : Scatter function
 ***************************************************************************************************/

// Pre-Integrated curvature and nDotL by a LUT tex : <realtime render 4th>, 634 page.
inline half3 ApproximatePreintegrateCurveScatter(half curve, half nDotL, half3 scatterCol, half thick)
{	
	// fitting the sss 2D tex (x - nDotL, y - curve, tex value: scatter(RGB))
	
	// 1, compute wrap light nDotL by curve
	half wrap = pow(curve, 4.0);
	half wrapNDotL = (nDotL + wrap) / (1.0 + wrap);
	wrapNDotL = clamp(wrapNDotL, 0.0, 1.0);
	
	// 2, get the back part scatter in sss tex
	half3 backScatter = scatterCol * wrapNDotL;
	
	// 3, compute thick influence
	backScatter *= 1 - thick * 0.5;
	
	// 4, get the front part diffuse 
	half3 frontDiffuse = 1.0 - (curve * 0.5 - 0.1);
	frontDiffuse = min(frontDiffuse, 1.0);
	frontDiffuse = nDotL * frontDiffuse;

	// 5, combine front part diffuse and back part scatter, produce a LUT result.
	half3 scatter = max(frontDiffuse, backScatter);
	
	return scatter;
}

//approximate for Pre-Integrated method
inline half3 ApproximateWrapLightScatter(half curve, half3 scatterCol, half thick)
{
	// 1, get wrap by curve
	half wrap = pow(curve, 4.0);
	wrap = wrap / (1.0 + wrap);
	wrap = clamp(wrap, 0.0, 1.0);

	// 2, get scatter by wrap
	half3 backScatter = scatterCol * wrap;

	// 3, compute thick influence
	backScatter *= 1 - thick * 0.5;

	return backScatter;
}

 /***************************************************************************************************
  * Region : transmittance function
  ***************************************************************************************************/

// Barre-BriseBois's Approximating Translucency by the "averaged local thickness": <real-time render 4th>, 640 page.
inline half3 ThicknessTransmittance(half thick, half3 vDotL, half phaseRange, half3 scatterCol)
{	
	// simple light transport phase function in the transmittance material
	half phase = (1.0 - phaseRange * phaseRange) / pow(1.0 + phaseRange * vDotL, 2.0);
	phase = min(phase, 1.0);

	//get transmittance
	half3 tansmittance = phase * thick * scatterCol;

	return tansmittance;
}

// approximate for Barre-BriseBois's method
inline half3 IndirectThicknessTransmittance(half thick, half phaseRange, half3 scatterCol)
{
	// simple light transport phase function in the transmittance material
	half phase = (1.0 - phaseRange * phaseRange) / pow(1.0 + phaseRange, 2.0);
	phase = min(phase, 1.0);

	//get transmittance
	half3 tansmittance = phase * thick * scatterCol;

	return tansmittance;
}

/***************************************************************************************************
 * Region : bsdf function
 ***************************************************************************************************/

inline half3 SubsurfaceScatter(	PBSSurfaceParam surface, PBSDirections dirs,
									half3 lightCol, SubsurfaceParam subsurface, SubsurfaceDirs subsurfaceDirs)
{	
	//scatter
	half3 scatter = ApproximatePreintegrateCurveScatter(subsurface.curve, subsurfaceDirs.nDotL, subsurface.scatterCol, subsurface.thick);

	//transmittance
	half3 transmittance = ThicknessTransmittance(subsurface.thick, subsurfaceDirs.vDotL, subsurface.phase, subsurface.scatterCol);

	//control scatter and transmittance lerp
	float3 final = lerp(scatter, transmittance, subsurface.transLerp);
	final *= surface.diffuseColor * lightCol;

	return final;
}

inline half3 IndirectSubsurfaceScatter(	PBSSurfaceParam surface, PBSDirections dirs,
									half3 ambientLightCol, SubsurfaceParam subsurface, SubsurfaceDirs subsurfaceDirs)
{
	half3 scatter = ApproximateWrapLightScatter(subsurface.curve, subsurface.scatterCol, subsurface.thick);

	scatter = lerp(1, scatter, subsurface.scatterRange);
	
	half3 transmittance = IndirectThicknessTransmittance(subsurface.thick, subsurface.phase, subsurface.scatterCol);

	scatter = lerp(scatter, transmittance, subsurface.transLerp);

	return scatter * ambientLightCol * surface.diffuseColor * surface.AO;
}


#endif
