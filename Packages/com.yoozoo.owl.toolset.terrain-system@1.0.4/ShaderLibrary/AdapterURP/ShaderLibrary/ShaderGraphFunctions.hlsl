#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_SHADERGRAPHFUNCTIONS
#define OWL_SHADER_LIBRARY_ADAPTER_URP_SHADERGRAPHFUNCTIONS

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/ShaderLibrary/ShaderGraphFunctions.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/ShaderLibrary/ShaderGraphFunctions.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/ShaderLibrary/ShaderGraphFunctions.hlsl"
#endif

#endif