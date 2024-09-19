#ifndef OWL_SHADER_LIBRARY_ADAPTER_CORERP_IMAGEBASEDLIGHTING
#define OWL_SHADER_LIBRARY_ADAPTER_CORERP_IMAGEBASEDLIGHTING

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibCoreRP/2021/ShaderLibrary/ImageBasedLighting.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibCoreRP/2020/ShaderLibrary/ImageBasedLighting.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibCoreRP/2019/ShaderLibrary/ImageBasedLighting.hlsl"
#endif

#endif