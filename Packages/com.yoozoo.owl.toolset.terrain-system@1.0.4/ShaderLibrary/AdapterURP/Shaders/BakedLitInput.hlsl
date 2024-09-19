#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_BAKEDLITINPUT
#define OWL_SHADER_LIBRARY_ADAPTER_URP_BAKEDLITINPUT

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/Shaders/BakedLitInput.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/Shaders/BakedLitInput.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/Shaders/BakedLitInput.hlsl"
#endif

#endif