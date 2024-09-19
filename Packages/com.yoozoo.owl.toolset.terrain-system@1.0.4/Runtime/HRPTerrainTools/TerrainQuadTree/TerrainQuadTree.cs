
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;

public class SplatmapLayerInfo
{
    public int channelId;
    public int validValueNum;
    public float validWeight;
    public float[,] values;

    public SplatmapLayerInfo(int channelId, int width, int height)
    {
        this.channelId = channelId;
        values = new float[width, height];
    }

    public static int RefreshSplatmapLayerInfo(float[,,] terrainMaps, RectInt area, List<SplatmapLayerInfo> splatmapLayerInfos, bool saveValue)
    {
        int width = area.width;
        int height = area.height;

        int layers = terrainMaps.GetLength(2);
        splatmapLayerInfos.Clear();
        int validChannelNum = 0;

        Task[] tasks = new Task[layers];

        if (saveValue)
        {
            for (int l = 0; l < layers; l++)
            {
                SplatmapLayerInfo splatmapLayerInfo = new SplatmapLayerInfo(l, width, height);

                int index = l;
                tasks[index] = new Task(() =>
                {
                    for (int y = 0; y < height; y++)
                    {
                        for (int x = 0; x < width; x++)
                        {
                            float mapValue = terrainMaps[x, y, index];
                            if (mapValue > 0f)
                            {
                                splatmapLayerInfo.validValueNum++;
                                splatmapLayerInfo.validWeight += mapValue;
                            }
                            splatmapLayerInfo.values[x, y] = mapValue;
                        }
                    }

                    lock (splatmapLayerInfos)
                    {
                        splatmapLayerInfos.Add(splatmapLayerInfo);
                    }
                });

                tasks[index].Start();
            }
        }
        else
        {
            for (int l = 0; l < layers; l++)
            {
                SplatmapLayerInfo splatmapLayerInfo = new SplatmapLayerInfo(l, 0, 0);

                int index = l;
                tasks[index] = new Task(() =>
                {
                    for (int y = 0; y < height; y++)
                    {
                        for (int x = 0; x < width; x++)
                        {
                            float mapValue = terrainMaps[x, y, index];
                            if (mapValue > 0f)
                            {
                                splatmapLayerInfo.validValueNum++;
                                splatmapLayerInfo.validWeight += mapValue;
                            }
                        }
                    }

                    lock (splatmapLayerInfos)
                    {
                        splatmapLayerInfos.Add(splatmapLayerInfo);
                    }
                });

                tasks[index].Start();
            }
        }

        Task.WaitAll(tasks);

        splatmapLayerInfos.Sort((left, right) =>
        {
            float diff = right.validWeight - left.validWeight;
            int diffInt = (int)diff;
            if (diffInt == 0)
            {
                diffInt = (int)(diff * 10000f);
                if(diffInt == 0)
                    return right.validValueNum - left.validValueNum;
            }

            return diffInt;
        });

        for (int i = 0; i < splatmapLayerInfos.Count; i++)
        {
            if (splatmapLayerInfos[i].validValueNum <= 0)
                break;
            validChannelNum++;
        }

        return validChannelNum;
    }
}

public abstract class TerrainQuadTree
{
    public static int maxDepth = 4;

    public bool isFirstNode;
    public bool hasChild { get; protected set; }

    public abstract TerrainQuadTree[] Nodes { get; }

    protected Terrain terrain;
    protected int depth;

    public abstract void AutoSplit();

    public abstract void Clear();
}

public abstract class TerrainQuadTree<T> : TerrainQuadTree where T : TerrainQuadTree
{
    public List<SplatmapLayerInfo> splatmapLayerInfos = new List<SplatmapLayerInfo>();
    public int validChannelNum = 0;

    protected T[] nodes = new T[4];

    public override TerrainQuadTree[] Nodes
    {
        get
        {
            return (TerrainQuadTree[])nodes;
        }
    }

    public TerrainQuadTree(Terrain terrain, int depth, bool isFirstNode)
    {
        this.terrain = terrain;
        this.depth = depth;
        this.isFirstNode = isFirstNode;
    }

    public void BFIterate(Action<TerrainQuadTree> handler)
    {
        if (handler == null)
            return;

        Queue<TerrainQuadTree> nodeQueue = new Queue<TerrainQuadTree>();
        nodeQueue.Enqueue(this);
        while (nodeQueue.Count > 0)
        {
            var node = nodeQueue.Dequeue();
            handler(node);
            TerrainQuadTree[] childNodes = node.Nodes;
            for (int i = 0; i < childNodes.Length; i++)
            {
                if (childNodes[i] != null)
                {
                    nodeQueue.Enqueue(childNodes[i]);
                }
            }
        }
    }

    public sealed override void AutoSplit()
    {
        if (terrain == null)
            return;

        HandleSplatmap();

        if (NeedSplit())
        {
            hasChild = true;
            Split();
        }
    }

    public override void Clear()
    {
        splatmapLayerInfos.Clear();
        for (int i = 0; i < nodes.Length; i++)
        {
            if (nodes[i] == null)
                continue;

            nodes[i].Clear();
            nodes[i] = null;
        }
    }

    protected void RefreshSplatmapLayerInfo(RectInt area, bool saveValue = true)
    {
        validChannelNum = SplatmapLayerInfo.RefreshSplatmapLayerInfo(terrain.terrainData.GetAlphamaps(area.xMin, area.yMin, area.width, area.height), area, splatmapLayerInfos, saveValue);
    }

    protected void ArrangeAlphamap(RectInt area, float[,,] newMaps, int maxValidLayer)
    {
        if (hasChild)
            return;

        int validLayer = Mathf.Min(validChannelNum, maxValidLayer);
        //int validLayer = validChannelNum;

        //非常奇怪，newMaps的xMin和yMin正好是相反的，但是他们赋值还是按照正常的xy顺序进行赋值的
        //检查发现splatmapLayerInfo里面的值是正常的顺序
        //搞不懂是为什么，总之能跑就行
        int xMin = area.yMin;
        int yMin = area.xMin;

        int width = area.width;
        int height = area.height;

        for (int i = 0; i < splatmapLayerInfos.Count; i++)
        {
            var splatmapLayerInfo = splatmapLayerInfos[i];

            if (i < validLayer)
            {

                for (int x = xMin; x < xMin + width; x++)
                {
                    for (int y = yMin; y < yMin + height; y++)
                    {
                        newMaps[x, y, splatmapLayerInfo.channelId] = splatmapLayerInfo.values[x - xMin, y - yMin];
                    }
                }
            }
            else
            {
                for (int x = xMin; x < xMin + width; x++)
                {
                    for (int y = yMin; y < yMin + height; y++)
                    {
                        newMaps[x, y, splatmapLayerInfo.channelId] = 0;
                    }
                }
            }
        }
    }

    protected abstract bool NeedSplit();
    protected abstract void HandleSplatmap();
    protected abstract void Split();
}
