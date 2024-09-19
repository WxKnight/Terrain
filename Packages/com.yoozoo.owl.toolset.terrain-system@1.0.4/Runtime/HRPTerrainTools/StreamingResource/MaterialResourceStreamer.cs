using System;
using UnityEngine;

[System.Serializable]
public class MaterialResourceStreamer : ResourceStreamer
{
    public MaterialResourceStreamer()
    {
        minLoadSize = 0.8f;
        maxUnloadSize = 2;
    }

    protected override void OnLoadSuccess(StreamingResource streamingResource, LODInfo lodInfo)
    {
        Material mat = (Material)streamingResource.Res;
        if (mat == null)
            return;

#if UNITY_EDITOR
        string shaderNamme = mat.shader.name;
        Shader shader = Shader.Find(shaderNamme);
        mat.shader = shader;
#endif

        MeshRenderer[] foundRenderers = lodInfo.meshRenderers;
        foreach (var foundRenderer in foundRenderers)
        {
            foundRenderer.sharedMaterial = mat;
        }
    }

    protected override void OnUnloadSuccess(StreamingResource streamingResource, LODInfo lodInfo)
    {
        Material mat = (Material)streamingResource.Res;
        if (mat == null)
            return;

        Resources.UnloadAsset(mat.GetTexture("_Diffuse"));
        Resources.UnloadAsset(mat.GetTexture("_Normal"));
        Resources.UnloadAsset(mat);

        MeshRenderer[] foundRenderers = lodInfo.meshRenderers;
        foreach (var foundRenderer in foundRenderers)
        {
            foundRenderer.sharedMaterial = terrainLodManager.BaseMat;
        }
    }
}