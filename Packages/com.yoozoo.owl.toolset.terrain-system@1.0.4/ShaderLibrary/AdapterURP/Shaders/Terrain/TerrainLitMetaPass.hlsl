#ifndef OWL_SHADER_LIBRARY_ADAPTER_URP_TERRAINLITMETAPASS
#define OWL_SHADER_LIBRARY_ADAPTER_URP_TERRAINLITMETAPASS

#if SHADER_LIB_VERSION == 2021
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2021/Shaders/Terrain/TerrainLitMetaPass.hlsl"
#elif SHADER_LIB_VERSION == 2020
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2020/Shaders/Terrain/TerrainLitMetaPass.hlsl"
#elif SHADER_LIB_VERSION == 2019
#include "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary/LibURP/2019/Shaders/Terrain/TerrainLitMetaPass.hlsl"
#endif

#endif