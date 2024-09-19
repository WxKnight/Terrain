#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_SIMPLELITINPUT
#define OWL_SHADER_LIBRARY_ADAPTER_URP_SIMPLELITINPUT

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/Shaders/SimpleLitInput.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/Shaders/SimpleLitInput.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/Shaders/SimpleLitInput.hlsl"
#endif

#endif