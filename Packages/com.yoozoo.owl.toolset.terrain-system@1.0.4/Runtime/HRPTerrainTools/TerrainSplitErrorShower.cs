using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class BoundsInfo
{
    public Bounds bounds;
    public SimplifySplatmapQuadTree node;
}

[ExecuteInEditMode]
public class TerrainSplitErrorShower : MonoBehaviour
{
    [HideInInspector] public bool showGizmos = true;
    [HideInInspector] public float errorRange = 0f;

    private Terrain terrain;
    private SimplifySplatmapQuadTree root;
    private List<BoundsInfo> boundsInfos = new List<BoundsInfo>();
    private List<BoundsInfo> leafNodes = new List<BoundsInfo>();
    private Vector2 terrainSize;
    private int controlMapSize;
    private int maximumValidLayer;

    public void Init(Terrain terrainTarget)
    {
        if (terrainTarget == null)
            return;

        terrain = terrainTarget;
        TerrainData terrainData = terrainTarget.terrainData;
        root = new SimplifySplatmapQuadTree(terrainTarget, 0, true, new RectInt(0, 0, terrainData.alphamapWidth, terrainData.alphamapHeight));
        terrainSize = new Vector2(terrainData.size.x, terrainData.size.z);
        controlMapSize = terrainData.alphamapWidth;
    }

    private void OnDrawGizmos()
    {
        if (Application.isPlaying)
            return;

        if (terrain == null)
            return;

        if (!showGizmos)
            return;

        foreach (var leafNode in leafNodes)
        {
            bool error = false;

            if (leafNode.node.validChannelNum > SimplifySplatmapQuadTree.splatmapSimplifyMaxValidLayer)
            {
                float area = leafNode.node.area.width * leafNode.node.area.height;
                float factor = 0;
                for (int i = SimplifySplatmapQuadTree.splatmapSimplifyMaxValidLayer; i < leafNode.node.validChannelNum; i++)
                {
                    factor += leafNode.node.splatmapLayerInfos[i].validWeight / area;
                }

                if (factor > errorRange)
                {
                    error = true;
                }
            }

            if (!error)
                continue;

            Gizmos.color = error ? new Color(1, 0, 0, 0.8f) : Gizmos.color = new Color(0, 1, 0, 0.8f);
            Vector3 leafNodeSize = leafNode.bounds.size;
            Vector3 leafNodeCenter = leafNode.bounds.center;

            float errorHeight = error ? Mathf.Max(30f, leafNodeSize.y)  : leafNodeSize.y;
            Vector3 center = new Vector3(leafNodeCenter.x, errorHeight * 0.5f, leafNodeCenter.z) + terrain.transform.position;
            Vector3 size = new Vector3(leafNodeSize.x, errorHeight, leafNodeSize.z) - Vector3.one * Mathf.Min(0.4f, leafNodeSize.x * 0.1f);
            Gizmos.DrawWireCube(center, size);
        }
    }

    public void RefreshSplitInfo()
    {
        if (root == null)
            return;

        SimplifySplatmapQuadTree.splatmapSimplifyMaxValidLayer = 2;
        root.Clear();
        root.BFIterate((node) =>
        {
            node.AutoSplit();
        });

        boundsInfos.Clear();
        root.BFIterate((node) =>
        {
            SimplifySplatmapQuadTree realNode = (SimplifySplatmapQuadTree)node;
            BoundsInfo boundsInfo = new BoundsInfo();
            Vector3 center = new Vector3(realNode.area.center.x * terrainSize.x, realNode.area.width * 0.5f * Mathf.Min(terrainSize.x, terrainSize.y), realNode.area.center.y * terrainSize.y) / controlMapSize;
            Vector3 size = new Vector3(terrainSize.x, Mathf.Min(terrainSize.x, terrainSize.y), terrainSize.y) * realNode.area.width / controlMapSize;
            boundsInfo.bounds = new Bounds(center, size);
            boundsInfo.node = realNode;
            boundsInfos.Add(boundsInfo);
        });

        leafNodes.Clear();
        foreach (var boundInfo in boundsInfos)
        {
            bool leafNode = true;
            TerrainQuadTree[] nodes = boundInfo.node.Nodes;
            for (int i = 0; i < nodes.Length; i++)
            {
                if (nodes[i] != null)
                {
                    leafNode = false;
                    break;
                }
            }

            if (!leafNode)
                continue;

            leafNodes.Add(boundInfo);
        }
    }

    public void Clear()
    {
        root = null;
        boundsInfos.Clear();
        leafNodes.Clear();
    }
}
