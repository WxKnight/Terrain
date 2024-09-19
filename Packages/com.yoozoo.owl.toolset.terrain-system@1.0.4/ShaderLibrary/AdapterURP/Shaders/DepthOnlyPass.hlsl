#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_DEPTHONLYPASS
#define OWL_SHADER_LIBRARY_ADAPTER_URP_DEPTHONLYPASS

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/Shaders/DepthOnlyPass.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/Shaders/DepthOnlyPass.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/Shaders/DepthOnlyPass.hlsl"
#endif

#endif