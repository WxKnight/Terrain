#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_DECLAREOPAQUETEXTURE
#define OWL_SHADER_LIBRARY_ADAPTER_URP_DECLAREOPAQUETEXTURE

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#endif

#endif