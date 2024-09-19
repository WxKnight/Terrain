using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class SimplifySplatmapQuadTree : TerrainQuadTree<SimplifySplatmapQuadTree>
{
    public RectInt area;
    public static int splatmapSimplifyMaxValidLayer = 2;

    public SimplifySplatmapQuadTree(Terrain terrain, int depth, bool isFirstNode, RectInt area) : base(terrain, depth, isFirstNode)
    {
        this.area = area;
        splatmapSimplifyMaxValidLayer = 2;
    }

    protected override void HandleSplatmap()
    {
        RefreshSplatmapLayerInfo(area, false);
    }

    protected override bool NeedSplit()
    {
        bool needSplit = validChannelNum > splatmapSimplifyMaxValidLayer && depth < maxDepth;
        if (!needSplit)
        {
            RefreshSplatmapLayerInfo(area, true);
        }
        return needSplit;
    }

    protected override void Split()
    {
        int width = area.width / 2;
        int height = area.height / 2;

        for (int j = 0; j < 2; j++)
        {
            for (int i = 0; i < 2; i++)
            {
                int xMin = area.xMin + width * i;
                int yMin = area.yMin + height * j;
                nodes[j * 2 + i] = new SimplifySplatmapQuadTree(terrain, depth + 1, false, new RectInt(xMin, yMin, width, height));
            }
        }
    }

    public void ArrangeAlphamap(float[,,] newMaps)
    {
        ArrangeAlphamap(area, newMaps, splatmapSimplifyMaxValidLayer);
    }

    public void RefreshColors(Texture2D[] terrainLayerTextures, Color[,] colors)
    {
        if (hasChild)
            return;

        int validLayer = Mathf.Min(validChannelNum, splatmapSimplifyMaxValidLayer);
        TerrainLayer[] terrainLayers = terrain.terrainData.terrainLayers;

        //非常奇怪，newMaps的xMin和yMin正好是相反的，但是他们赋值还是按照正常的xy顺序进行赋值的
        //检查发现splatmapLayerInfo里面的值是正常的顺序
        //搞不懂是为什么，总之能跑就行
        int xMin = area.yMin;
        int yMin = area.xMin;

        int width = area.width;
        int height = area.height;

        if (validChannelNum <= 0)
            return;

        for (int x = xMin; x < xMin + width; x++)
        {
            for (int y = yMin; y < yMin + height; y++)
            {
                float totalWeight = 0;
                float totalColorR = 0;
                float totalColorG = 0;
                float totalColorB = 0;

                for (int i = 0; i < validChannelNum; i++)
                {
                    var splatmapLayerInfo = splatmapLayerInfos[i];
                    TerrainLayer terrainLayer = terrainLayers[splatmapLayerInfo.channelId];
                    Vector2 uv = new Vector2(((float)x) / area.width, ((float)y) / area.height);
                    Vector2 tiling = new Vector2(terrain.terrainData.size.x / terrainLayer.tileSize.x, terrain.terrainData.size.z / terrainLayer.tileSize.y);
                    uv = uv * tiling;
                    float u = uv.x - (int)uv.x;
                    float v = uv.y - (int)uv.y;

                    Color color = terrainLayerTextures[splatmapLayerInfo.channelId].GetPixelBilinear(u, v);
                    totalColorR += color.r * splatmapLayerInfo.values[x - xMin, y - yMin];
                    totalColorG += color.g * splatmapLayerInfo.values[x - xMin, y - yMin];
                    totalColorB += color.b * splatmapLayerInfo.values[x - xMin, y - yMin];
                    totalWeight += splatmapLayerInfo.values[x - xMin, y - yMin];
                }

                totalColorR /= totalWeight;
                totalColorG /= totalWeight;
                totalColorB /= totalWeight;

                colors[x, y] = new Color(totalColorR, totalColorG, totalColorB);
            }
        }
    }

    public void MixLayers(Texture2D[] terrainLayerTextures, float[,,] mixedMaps, Color[,] colors, bool customBlend)
    {
        if (hasChild)
            return;

        int validLayer = Mathf.Min(validChannelNum, splatmapSimplifyMaxValidLayer);
        TerrainLayer[] terrainLayers = terrain.terrainData.terrainLayers;

        //非常奇怪，newMaps的xMin和yMin正好是相反的，但是他们赋值还是按照正常的xy顺序进行赋值的
        //检查发现splatmapLayerInfo里面的值是正常的顺序
        //搞不懂是为什么，总之能跑就行
        int xMin = area.yMin;
        int yMin = area.xMin;

        int width = area.width;
        int height = area.height;

        if (validChannelNum <= 0)
            return;

        if (customBlend)
        {
            if (validChannelNum == 1)
            {
                for (int x = xMin; x < xMin + width; x++)
                {
                    for (int y = yMin; y < yMin + height; y++)
                    {
                        mixedMaps[x, y, splatmapLayerInfos[0].channelId] = splatmapLayerInfos[0].values[x - xMin, y - yMin];
                    }
                }
            }
            else
            {
                for (int x = xMin; x < xMin + width; x++)
                {
                    for (int y = yMin; y < yMin + height; y++)
                    {
                        Color colorLayer1 = Color.black;
                        Color colorLayer2 = Color.black;
                        float weight1 = 0f;
                        float weight2 = 0f;
                        for (int i = 0; i < validChannelNum; i++)
                        {
                            var splatmapLayerInfo = splatmapLayerInfos[i];
                            TerrainLayer terrainLayer = terrainLayers[splatmapLayerInfo.channelId];
                            Vector2 uv = new Vector2(((float)x) / area.width, ((float)y) / area.height);
                            Vector2 tiling = new Vector2(terrain.terrainData.size.x / terrainLayer.tileSize.x, terrain.terrainData.size.z / terrainLayer.tileSize.y);
                            uv = uv * tiling;
                            float u = uv.x - (int)uv.x;
                            float v = uv.y - (int)uv.y;

                            Color color = terrainLayerTextures[splatmapLayerInfo.channelId].GetPixelBilinear(u, v);
                            if (i == 0)
                            {
                                colorLayer1 = color;
                                weight1 = splatmapLayerInfo.values[x - xMin, y - yMin];
                            }
                            else if (i == 1)
                            {
                                colorLayer2 = color;
                                weight2 = splatmapLayerInfo.values[x - xMin, y - yMin];
                            }
                        }

                        float totalColorR = 0f;
                        float totalColorG = 0f;
                        float totalColorB = 0f;

                        Color curColor = colors[x, y];
                        totalColorR += curColor.r;
                        totalColorG += curColor.g;
                        totalColorB += curColor.b;

                        float diffR = Mathf.Abs(colorLayer1.r - colorLayer2.r);
                        float diffG = Mathf.Abs(colorLayer1.g - colorLayer2.g);
                        float diffB = Mathf.Abs(colorLayer1.b - colorLayer2.b);


                        float weightR = Mathf.Clamp01(Mathf.InverseLerp(colorLayer2.r, colorLayer1.r, totalColorR)) * diffR;
                        float weightG = Mathf.Clamp01(Mathf.InverseLerp(colorLayer2.g, colorLayer1.g, totalColorG)) * diffG;
                        float weightB = Mathf.Clamp01(Mathf.InverseLerp(colorLayer2.b, colorLayer1.b, totalColorB)) * diffB;

                        //float averageWeight = Mathf.Max(weightR, weightG, weightB);
                        float averageWeight = Mathf.Clamp01((weightR + weightG + weightB) / (diffR + diffG + diffB + Mathf.Epsilon));

                        float factor = weight1 / (weight1 + weight2);

                        //mixedMaps[x, y, splatmapLayerInfos[0].channelId] = averageWeight;
                        mixedMaps[x, y, splatmapLayerInfos[0].channelId] = Mathf.Lerp(averageWeight, factor, factor);
                        mixedMaps[x, y, splatmapLayerInfos[1].channelId] = 1 - mixedMaps[x, y, splatmapLayerInfos[0].channelId];

                        for (int i = 2; i < validChannelNum; i++)
                        {
                            mixedMaps[x, y, splatmapLayerInfos[i].channelId] = 0;
                        }
                    }
                }
            }
        }
        else
        {
            for (int x = xMin; x < xMin + width; x++)
            {
                for (int y = yMin; y < yMin + height; y++)
                {
                    float totalWeight = 0f;
                    for (int i = 0; i < validChannelNum; i++)
                    {
                        totalWeight += splatmapLayerInfos[i].values[x - xMin, y - yMin];
                    }

                    for (int i = 0; i < validChannelNum; i++)
                    {
                        if(i < 4)
                        {
                            mixedMaps[x, y, splatmapLayerInfos[i].channelId] = splatmapLayerInfos[i].values[x - xMin, y - yMin] / totalWeight;
                        }
                        else
                        {
                            mixedMaps[x, y, splatmapLayerInfos[i].channelId] = 0;
                        }
                    }
                }
            }
        }
    }
}