#ifndef HRP_GRAPHICS_SETTING_MACRO_INCLUDED
#define HRP_GRAPHICS_SETTING_MACRO_INCLUDED

// 画质：极低，低，中，高，极致

// _CHARACTER_GRAPHIC_MINIMAL, _CHARACTER_GRAPHIC_LOW, _CHARACTER_GRAPHIC_MEDIUM, _CHARACTER_GRAPHIC_HIGH, _CHARACTER_GRAPHIC_SUPREME
// _SCENE_GRAPHIC_MINIMAL, _SCENE_GRAPHIC_LOW, _SCENE_GRAPHIC_MEDIUM, _SCENE_GRAPHIC_HIGH, _SCENE_GRAPHIC_SUPREME

// _CHARACTER_LODS, _CHARACTER_LOD0, _CHARACTER_LOD1, _CHARACTER_LOD2
// _SCENE_LOD0, _SCENE_LOD1

// _CHARACTER_INTERNAL_GRAPHIC_MINIMAL, _CHARACTER_INTERNAL_GRAPHIC_LOW, _CHARACTER_INTERNAL_GRAPHIC_MEDIUM, _CHARACTER_INTERNAL_GRAPHIC_HIGH, _CHARACTER_INTERNAL_GRAPHIC_SUPREME
// _SCENE_INTERNAL_GRAPHIC_MINIMAL, _SCENE_INTERNAL_GRAPHIC_LOW, _SCENE_INTERNAL_GRAPHIC_MEDIUM, _SCENE_INTERNAL_GRAPHIC_HIGH, _SCENE_INTERNAL_GRAPHIC_SUPREME


#ifdef _SET_DEFAULT_CHARACTER_GRAPHIC_LEVEL
    #ifndef _CHARACTER_GRAPHIC_LOW
        #ifndef _CHARACTER_GRAPHIC_MEDIUM
            #ifndef _CHARACTER_GRAPHIC_HIGH
                #ifndef _CHARACTER_GRAPHIC_SUPREME
                    #define _CHARACTER_GRAPHIC_SUPREME 1
                #endif
            #endif
        #endif
    #endif
#endif

#ifdef _SET_DEFAULT_CHARACTER_LOD_LEVEL
    #ifndef _CHARACTER_LODS
        #ifndef _CHARACTER_LOD0
            #ifndef _CHARACTER_LOD1
                #ifndef _CHARACTER_LOD2
                    #define _CHARACTER_LOD0 1
                #endif
            #endif
        #endif
    #endif
#endif

#ifdef _SET_DEFAULT_SCENE_GRAPHIC_LEVEL
    #ifndef _SCENE_GRAPHIC_LOW
        #ifndef _SCENE_GRAPHIC_MEDIUM
            #ifndef _SCENE_GRAPHIC_HIGH
                #ifndef _SCENE_GRAPHIC_SUPREME
                    #define _SCENE_GRAPHIC_HIGH 1
                #endif
            #endif
        #endif
    #endif
#endif

#ifdef _SET_DEFAULT_SCENE_LOD_LEVEL
    #ifndef _SCENE_LOD0
        #ifndef _SCENE_LOD1
            #define _SCENE_LOD0 1
        #endif
    #endif
#endif


// 人物性能分级
#if defined(_CHARACTER_IMPORTANT_SHADER)

    #if defined(_CHARACTER_GRAPHIC_SUPREME)

        #if defined(_CHARACTER_LODS) || defined(_CHARACTER_LOD0)
            #define _CHARACTER_INTERNAL_GRAPHIC_SUPREME     1
        #elif defined(_CHARACTER_LOD1)
            #define _CHARACTER_INTERNAL_GRAPHIC_MEDIUM      1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #elif defined(_CHARACTER_GRAPHIC_HIGH) || defined(_CHARACTER_GRAPHIC_MEDIUM)

        #if defined(_CHARACTER_LODS)
            #define _CHARACTER_INTERNAL_GRAPHIC_SUPREME     1
        #elif defined(_CHARACTER_LOD0)
            #define _CHARACTER_INTERNAL_GRAPHIC_HIGH        1
        #elif defined(_CHARACTER_LOD1)
            #define _CHARACTER_INTERNAL_GRAPHIC_MEDIUM      1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #else

        #if defined(_CHARACTER_LODS)
            #define _CHARACTER_INTERNAL_GRAPHIC_SUPREME     1
        #elif defined(_CHARACTER_LOD0)
            #define _CHARACTER_INTERNAL_GRAPHIC_HIGH        1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #endif

#else

    #if defined(_CHARACTER_GRAPHIC_SUPREME)

        #if defined(_CHARACTER_LODS) || defined(_CHARACTER_LOD0)
            #define _CHARACTER_INTERNAL_GRAPHIC_SUPREME     1
        #elif defined(_CHARACTER_LOD1)
            #define _CHARACTER_INTERNAL_GRAPHIC_MEDIUM      1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #elif defined(_CHARACTER_GRAPHIC_HIGH)

        #if defined(_CHARACTER_LODS)
            #define _CHARACTER_INTERNAL_GRAPHIC_SUPREME     1
        #elif defined(_CHARACTER_LOD0)
            #define _CHARACTER_INTERNAL_GRAPHIC_HIGH        1
        #elif defined(_CHARACTER_LOD1)
            #define _CHARACTER_INTERNAL_GRAPHIC_MEDIUM      1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #elif defined(_CHARACTER_GRAPHIC_MEDIUM)

        #if defined(_CHARACTER_LODS)
            #define _CHARACTER_INTERNAL_GRAPHIC_HIGH        1
        #elif defined(_CHARACTER_LOD0)
            #define _CHARACTER_INTERNAL_GRAPHIC_MEDIUM      1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #else

        #if defined(_CHARACTER_LODS)
            #define _CHARACTER_INTERNAL_GRAPHIC_HIGH        1
        #else
            #define _CHARACTER_INTERNAL_GRAPHIC_LOW         1
        #endif

    #endif

#endif



//场景性能分级

//场景性能分级，策略1：不考虑LOD
// 应用：TA/Realtime/Water
#ifdef _SCENE_QUARLITY_GRAPHIC_FOUR_STEP

    #if defined (_SCENE_GRAPHIC_SUPREME)
        #define _SCENE_INTERNAL_GRAPHIC_SUPREME         1
    #elif defined (_SCENE_GRAPHIC_HIGH)
        #define _SCENE_INTERNAL_GRAPHIC_HIGH            1
    #elif defined(_SCENE_GRAPHIC_MEDIUM)
        #define _SCENE_INTERNAL_GRAPHIC_MEDIUM          1
    #else
        #define _SCENE_INTERNAL_GRAPHIC_LOW             1
    #endif

#endif

//场景性能分级，策略2：阶梯状
//应用：TA/Lightmap/Terrain
#ifdef _SCENE_QUARLITY_PATTERN_STEP

    #if defined (_SCENE_LOD0)
        #if defined(_SCENE_GRAPHIC_SUPREME)
            #define _SCENE_INTERNAL_GRAPHIC_SUPREME     1
        #elif defined(_SCENE_GRAPHIC_HIGH)
            #define _SCENE_INTERNAL_GRAPHIC_HIGH        1
        #elif defined(_SCENE_GRAPHIC_MEDIUM)
            #define _SCENE_INTERNAL_GRAPHIC_MEDIUM      1
        #else
            #define _SCENE_INTERNAL_GRAPHIC_LOW         1
        #endif

    #else

        #if defined(_SCENE_GRAPHIC_SUPREME)
            #define _SCENE_INTERNAL_GRAPHIC_MEDIUM      1
        #elif defined(_SCENE_GRAPHIC_HIGH)
            #define _SCENE_INTERNAL_GRAPHIC_MEDIUM      1
        #elif defined(_SCENE_GRAPHIC_MEDIUM)
            #define _SCENE_INTERNAL_GRAPHIC_LOW         1
        #else
            #define _SCENE_INTERNAL_GRAPHIC_LOW         1
        #endif

    #endif

#endif



#ifdef _SCENE_GRAPHIC_LOW
    #define _LOW_LIGHTMAP_TO_AHD 1
    #define _VERTEXFOG_ON 1
#endif


#if !defined(_VERY_PRECISE_TBN) && !defined(_SCENE_GRAPHIC_LOW)
    #define _PRECISE_TBN 1
#endif


#endif