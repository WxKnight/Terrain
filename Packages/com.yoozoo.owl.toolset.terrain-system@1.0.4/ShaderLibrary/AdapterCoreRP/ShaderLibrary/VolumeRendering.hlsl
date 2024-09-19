#ifndef OWL_SHADER_LIBRARY_ADAPTER_CORERP_VOLUMERENDERING
#define OWL_SHADER_LIBRARY_ADAPTER_CORERP_VOLUMERENDERING

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibCoreRP/2021/ShaderLibrary/VolumeRendering.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibCoreRP/2020/ShaderLibrary/VolumeRendering.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibCoreRP/2019/ShaderLibrary/VolumeRendering.hlsl"
#endif

#endif