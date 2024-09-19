using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class LODInfo
{
    public string materiaAssetPath;
    public MeshRenderer[] meshRenderers;

    public LODInfo(string materiaAssetPath, MeshRenderer[] meshRenderers)
    {
        this.materiaAssetPath = materiaAssetPath;
        this.meshRenderers = meshRenderers;
    }
}

public class TerrainLODManager : MonoBehaviour
{
    public Transform origin;
    [SerializeField]
    private ResourceLoader resourceLoader;
    [SerializeField]
    private MaterialResourceStreamer materialResourceStreamer;

    public int xSegment;
    public int zSegment;
    public float segmentWidth;
    public float segmentLength;
    public string baseMaterialAssetPath = string.Empty;
    public List<LODInfo> lodInfos = new List<LODInfo>();

    public Material BaseMat { get; private set; }
    private List<ResourceStreamer> resourceStreamers = new List<ResourceStreamer>();
    private bool ready;

    private void Start()
    {
        resourceStreamers.Add(materialResourceStreamer);
        foreach (var resourceStreamer in resourceStreamers)
        {
            resourceStreamer.Init(this);
        }

        foreach (var lodInfo in lodInfos)
        {
            foreach (var renderer in lodInfo.meshRenderers)
            {
                renderer.enabled = false;
            }
        }

        StreamingResourceMsgCenter.Instance.SetResLoader(resourceLoader);
        StreamingResourceMsgCenter.Instance.AddResourceReq(new ResourceReq(
            new ResourceMsg() { msgId = ResourceMsgId.Load, assetPath = baseMaterialAssetPath },
            (streamingRes) =>
            {
                BaseMat = (Material)streamingRes.Res;

#if UNITY_EDITOR
                string shaderNamme = BaseMat.shader.name;
                Shader shader = Shader.Find(shaderNamme);
                BaseMat.shader = shader;
#endif

                foreach (var lodInfo in lodInfos)
                {
                    foreach (var renderer in lodInfo.meshRenderers)
                    {
                        renderer.sharedMaterial = BaseMat;
                        renderer.enabled = true;
                    }
                }

                ready = true;
            }));
    }

    private void Update()
    {
        if (!ready)
            return;

        UpdateOrigin();
    }

    private void OnDestroy()
    {
        foreach (var resourceStreamer in resourceStreamers)
        {
            resourceStreamer.OnDestroy();
        }

        StreamingResourceMsgCenter.Instance.AddResourceReq(new ResourceReq(
            new ResourceMsg() { msgId = ResourceMsgId.Unload, assetPath = baseMaterialAssetPath },
            null
            ));

        BaseMat = null;
        lodInfos.Clear();
    }

    public void InitDataInEditor(TerrainData terrainData, int xSegment, int zSegment, Transform rootTerrain, Material baseMat, ResourceLoader resourceLoader)
    {
        this.xSegment = xSegment;
        this.zSegment = zSegment;
        segmentWidth = terrainData.size.x / xSegment;
        segmentLength = terrainData.size.z / zSegment;

        if (resourceLoader != null)
        {
            baseMaterialAssetPath = resourceLoader.ProvidePath(baseMat);
        }

        lodInfos.Clear();
        for (int i = 0; i < rootTerrain.childCount; i++)
        {
            MeshRenderer[] meshRenderers = rootTerrain.GetChild(i).GetComponentsInChildren<MeshRenderer>();
            string materialAssetPath = string.Empty;
            if (resourceLoader != null && meshRenderers.Length > 0)
            {
                materialAssetPath = resourceLoader.ProvidePath(meshRenderers[0].sharedMaterial);
            }
            LODInfo lodInfo = new LODInfo(materialAssetPath, meshRenderers);
            lodInfos.Add(lodInfo);
        }

        this.resourceLoader = resourceLoader;
    }

    //z-primary filling
    private int GetArrayIndexInTerrain(int xPosInTerrain, int yPosInTerrain)
    {
        return xPosInTerrain * zSegment + yPosInTerrain;
    }

    public LODInfo GetLODInfo(int localTilePosX, int localTilePosZ)
    {
        if (localTilePosX < 0 || localTilePosZ < 0 || localTilePosX >= xSegment || localTilePosZ >= zSegment)
            return null;

        var index = GetArrayIndexInTerrain(localTilePosX, localTilePosZ);
        return lodInfos[index];
    }

    private void UpdateOrigin()
    {
        if (origin == null)
            return;

        Vector3 originToTerrainPos = origin.position - transform.position;
        float originToTerrainTilePosX = originToTerrainPos.x / segmentWidth;
        float originToTerrainTilePosZ = originToTerrainPos.z / segmentLength;

        for (int i = 0; i < resourceStreamers.Count; i++)
        {
            resourceStreamers[i].Update(originToTerrainTilePosX, originToTerrainTilePosZ);
        }
    }
}
