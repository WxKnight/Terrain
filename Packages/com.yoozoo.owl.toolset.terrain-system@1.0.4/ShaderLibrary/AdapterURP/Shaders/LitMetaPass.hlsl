#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_LITMETAPASS
#define OWL_SHADER_LIBRARY_ADAPTER_URP_LITMETAPASS

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/Shaders/LitMetaPass.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/Shaders/LitMetaPass.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/Shaders/LitMetaPass.hlsl"
#endif

#endif