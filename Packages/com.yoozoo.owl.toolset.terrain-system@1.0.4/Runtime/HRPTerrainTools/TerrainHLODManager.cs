using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainHLODManager : MonoBehaviour
{
    public Transform checkTransform;
    public Material splatmapAtlasMat;
    public float rangeFactor = 1;
    public float tilingFactor = 1;

    [SerializeField]
    private HLODNode root;
    [SerializeField]
    private List<Vector4> tilings = new List<Vector4>();
    private List<Renderer> curShowedRenderers = new List<Renderer>();
    private float elapsedTime;

    private void Awake()
    {
        if(splatmapAtlasMat != null)
        {
#if UNITY_EDITOR
            List<Vector4> newTilings = new List<Vector4>(16);
            for (int i = 0; i < tilings.Count; i++)
            {
                newTilings.Add(tilings[i] * tilingFactor);
            }
            splatmapAtlasMat.SetVectorArray("_TilingScales", newTilings);
#else
            splatmapAtlasMat.SetVectorArray("_TilingScales", tilings);
#endif
        }

        root.InitHLODNode(rangeFactor);
        UpdateHLOD();
    }

    private void Update()
    {
#if UNITY_EDITOR
        if (splatmapAtlasMat != null)
        {
            List<Vector4> newTilings = new List<Vector4>(16);
            for (int i = 0; i < tilings.Count; i++)
            {
                newTilings.Add(tilings[i] * tilingFactor);
            }
            splatmapAtlasMat.SetVectorArray("_TilingScales", newTilings);
        }
#endif

        if (checkTransform == null)
            return;

        elapsedTime += Time.deltaTime;
        if(elapsedTime > 0.5f)
        {
            UpdateHLOD();
            elapsedTime = 0f;
        }
    }

    private void UpdateHLOD()
    {
        foreach (var showdRenderer in curShowedRenderers)
        {
            showdRenderer.enabled = false;
        }
        curShowedRenderers.Clear();

        Vector3 checkPos = checkTransform.position;
        root.CheckHLOD(checkPos, ref curShowedRenderers);
    }

    public void InitHLODTree(Terrain terrain, List<List<Renderer>> depthRenderers)
    {
        var terrainData = terrain.terrainData;
        Vector3 size = terrainData.size;
        Vector3 terrainPos = terrain.transform.position;

        var rootCenterFacotr = new Vector2(0.5f, 0.5f);
        root = new HLODNode(depthRenderers[0][0], GetWorldCenter(size, terrainPos, rootCenterFacotr), size);

        //传入的renderers需要按照z-primary进行填充
        for (int i = 1; i < depthRenderers.Count; i++)
        {
            int zMax = 1 << i;
            float gap = 1f / zMax;

            var renderers = depthRenderers[i];
            for (int j = 0; j < renderers.Count; j++)
            {
                int x = j / zMax;
                int z = j % zMax;
                Vector2 centerFactor = new Vector2((x + 0.5f) * gap, (z + 0.5f) * gap);
                root.InsertNode(renderers[j], GetWorldCenter(size, terrainPos, centerFactor), new Vector3(size.x / zMax, size.y, size.z / zMax));
            }
        }
    }

    public void InitSplatmapInfo(TerrainData terrainData, Material splatmapAtlasMat, Texture2D diffuseAtlas)
    {
        this.tilings.Clear();
        TerrainLayer[] terrainLayers = terrainData.terrainLayers;
        Vector4 textureTiling = Vector4.one;
        if (diffuseAtlas != null)
        {
            textureTiling = new Vector4(2f, diffuseAtlas.height / (float)diffuseAtlas.width * 2f);
        }

        foreach (var terrainLayer in terrainLayers)
        {
            Vector4 tiling = new Vector4(terrainData.size.x / terrainLayer.tileSize.x * textureTiling.x, terrainData.size.z / terrainLayer.tileSize.y * textureTiling.y);
            this.tilings.Add(tiling);
        }
        this.splatmapAtlasMat = splatmapAtlasMat;
    }

    private Vector3 GetWorldCenter(Vector3 terrainSize, Vector3 terrainPos, Vector2 centerFactor)
    {
        Vector3 offset = new Vector3(centerFactor.x * terrainSize.x, 0, centerFactor.y * terrainSize.z);
        return terrainPos + offset;
    }
}

[System.Serializable]
class HLODNode
{
    [SerializeField]
    private Renderer renderer;
    [SerializeField]
    private HLODNode[] children;  //N-(x,z): 0-(0,0), 1-(0,1), 2-(1,0), 3-(1,1)
    [SerializeField]
    [HideInInspector]
    private Vector3 worldCenter;
    [SerializeField]
    [HideInInspector]
    private Vector3 size;
    [SerializeField]
    [HideInInspector]
    private float showDistanceSqr;

    public HLODNode(Renderer renderer, Vector3 center, Vector3 nodeSize)
    {
        this.renderer = renderer;
        worldCenter = center;
        size = nodeSize;
        showDistanceSqr = size.x * size.x;
    }

    public void InsertNode(Renderer otherRenderer, Vector3 otherCenter, Vector3 nodeSize)
    {
        if (children == null || children.Length == 0)
            children = new HLODNode[4];

        Vector3 offset = otherCenter - worldCenter;
        int index = 0;
        if(offset.x < 0)
        {
            index = offset.z < 0 ? 0 : 1;
        }
        else
        {
            index = offset.z < 0 ? 2 : 3;
        }

        if(children[index] == null)
        {
            children[index] = new HLODNode(otherRenderer, otherCenter,nodeSize);
        }
        else
        {
            children[index].InsertNode(otherRenderer, otherCenter, nodeSize);
        }
    }

    public void InitHLODNode(float rangeFactor)
    {
        renderer.enabled = false;
        showDistanceSqr *= rangeFactor;
        if (children == null || children.Length == 0)
            return;

        for (int i = 0; i < children.Length; i++)
        {
            children[i].InitHLODNode(rangeFactor);
        }
    }


    public void CheckHLOD(Vector3 checkPos, ref List<Renderer> showedRenderers)
    {
        Vector3 offset = worldCenter - checkPos;
        if(new Vector2(offset.x, offset.z).sqrMagnitude > showDistanceSqr)
        {
            renderer.enabled = true;
            showedRenderers.Add(renderer);
            return;
        }

        if (children == null || children.Length == 0)
        {
            renderer.enabled = true;
            showedRenderers.Add(renderer);
            return;
        }

        for (int i = 0; i < children.Length; i++)
        {
            children[i]?.CheckHLOD(checkPos, ref showedRenderers);
        }
    }
}
