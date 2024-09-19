using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StreamingTerrainNode
{
    public int tilePosX;
    public int tilePosZ;
}

[System.Serializable]
public abstract class ResourceStreamer
{
    [SerializeField]
    public bool enable = true;
    [SerializeField]
    public float minLoadSize;
    [SerializeField]
    public int maxUnloadSize;

    protected float minLoadExtent;
    protected TerrainLODManager terrainLodManager;
    protected StreamingTerrainNode[,] nodeCache;

    public void Init(TerrainLODManager terrainLodManager)
    {
        this.terrainLodManager = terrainLodManager;
        minLoadExtent = minLoadSize / 2f;
        nodeCache = new StreamingTerrainNode[maxUnloadSize, maxUnloadSize];
    }

    public void OnDestroy()
    {
        for (int i = 0; i < nodeCache.GetLength(0); i++)
        {
            for (int j = 0; j < nodeCache.GetLength(1); j++)
            {
                var node = nodeCache[i, j];
                if (node == null)
                    continue;

                var unloadLodInfo = terrainLodManager.GetLODInfo(node.tilePosX, node.tilePosZ);
                StreamingResourceMsgCenter.Instance.AddResourceReq(new ResourceReq(
                new ResourceMsg() { msgId = ResourceMsgId.Unload, assetPath = unloadLodInfo.materiaAssetPath },
                null));
            }
        }
    }

    public void Update(float originToTerrainTilePosFloatX, float originToTerrainTilePosFloatZ)
    {
        if (!enable)
            return;

        int leftTilePos = Mathf.FloorToInt(originToTerrainTilePosFloatX - minLoadExtent);
        int topTilePos = Mathf.FloorToInt(originToTerrainTilePosFloatZ + minLoadExtent);
        int rightTilePos = Mathf.FloorToInt(originToTerrainTilePosFloatX + minLoadExtent);
        int bottomTilePos = Mathf.FloorToInt(originToTerrainTilePosFloatZ - minLoadExtent);
        int originTilePosX = Mathf.FloorToInt(originToTerrainTilePosFloatX);
        int originTilePosZ = Mathf.FloorToInt(originToTerrainTilePosFloatZ);

        for (int tilePosX = leftTilePos; tilePosX <= rightTilePos; tilePosX++)
        {
            for (int tilePosZ = bottomTilePos; tilePosZ <= topTilePos; tilePosZ++)
            {
                if (tilePosX < 0 || tilePosZ < 0 || tilePosX >= terrainLodManager.xSegment || tilePosZ >= terrainLodManager.zSegment)
                    continue;

                int xIndex = tilePosX % maxUnloadSize;
                int zIndex = tilePosZ % maxUnloadSize;

                StreamingTerrainNode node = nodeCache[xIndex, zIndex];
                var lodInfo = terrainLodManager.GetLODInfo(tilePosX, tilePosZ);

                if (node == null)
                {
                    node = new StreamingTerrainNode();
                    nodeCache[xIndex, zIndex] = node;
                    LoadRes(tilePosX, tilePosZ, node, lodInfo);
                    continue;
                }

                if (node.tilePosX < leftTilePos || node.tilePosX > rightTilePos || node.tilePosZ < bottomTilePos || node.tilePosZ > topTilePos)
                {
                    var unloadLodInfo = terrainLodManager.GetLODInfo(node.tilePosX, node.tilePosZ);
                    UnloadRes(unloadLodInfo);
                    LoadRes(tilePosX, tilePosZ, node, lodInfo);
                }
            }
        }
    }

    private void UnloadRes(LODInfo lodInfo)
    {
        StreamingResourceMsgCenter.Instance.AddResourceReq(new ResourceReq(
        new ResourceMsg() { msgId = ResourceMsgId.Unload, assetPath = lodInfo.materiaAssetPath },
            (streamingResource) =>
            {
                if(streamingResource.Res == null)
                {
                    Debug.Log("Res is null for: " + lodInfo.materiaAssetPath);
                }

                OnUnloadSuccess(streamingResource, lodInfo);
            }));
    }

    private void LoadRes(int tilePosX, int tilePosZ, StreamingTerrainNode node, LODInfo lodInfo)
    {
        node.tilePosX = tilePosX;
        node.tilePosZ = tilePosZ;
        StreamingResourceMsgCenter.Instance.AddResourceReq(new ResourceReq(
            new ResourceMsg() { msgId = ResourceMsgId.Load, assetPath = lodInfo.materiaAssetPath },
            (streamingResource) =>
            {
                OnLoadSuccess(streamingResource, lodInfo);
            }));
    }

    protected abstract void OnLoadSuccess(StreamingResource streamingResource, LODInfo lodInfo);

    protected abstract void OnUnloadSuccess(StreamingResource streamingResource, LODInfo lodInfo);
}