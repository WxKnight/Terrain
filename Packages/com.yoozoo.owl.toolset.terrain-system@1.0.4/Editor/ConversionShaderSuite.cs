using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CreateAssetMenu(menuName = "TerrainSystem/ConversioShaderSuite")]
public class ConversionShaderSuite : ScriptableObject
{
    [SerializeField]
    private Shader bakeAlbedoShader;
    [SerializeField]
    private Shader bakeBumpShader;

    [SerializeField]
    private Shader terrainBasemapShader;
    [SerializeField]
    private Shader terrainSplatmapShader;
    [SerializeField]
    private Shader terrainSplatmapAddShader;
    [SerializeField]
    private Shader terrainSplatmapAtlasShader;

    private void CopyKeyword(Material from, Material to,string keyword)
    {
        if (from.IsKeywordEnabled(keyword))
        {
            to.EnableKeyword(keyword);
        }
        else
        {
            to.DisableKeyword(keyword);
        }
    }

    public void InitBakeMaterial(Material mat, Terrain t)
    {
        TerrainData terrainData = t.terrainData;
        mat.CopyPropertiesFromMaterial(t.materialTemplate);

        CopyKeyword(t.materialTemplate, mat, "_TERRAIN_BLEND_HEIGHT");
        CopyKeyword(t.materialTemplate, mat, "_TERRAIN_BLEND_TRIPLANAR");
        CopyKeyword(t.materialTemplate, mat, "_TERRAIN_ANTI_TILING");


        Texture2D[] alphamapTextures = terrainData.alphamapTextures;
        for (int i = 0; i < alphamapTextures.Length; i++)
        {
            string controlIndex = i == 0 ? "" : i.ToString();
            mat.SetTexture("_Control" + controlIndex, alphamapTextures[i]);
        }

        mat.SetTexture("_HeightMap", terrainData.heightmapTexture);
        mat.SetVector("_TerrainDimension", terrainData.size);

        TerrainLayer[] terrainLayers = terrainData.terrainLayers;
        for (int i = 0; i < terrainLayers.Length; i++)
        {
            TerrainLayer terrainLayer = terrainLayers[i];
            Vector2 tiling = new Vector2(terrainData.size.x / terrainLayer.tileSize.x, terrainData.size.z / terrainLayer.tileSize.y);
            mat.SetTexture("_Splat" + i, terrainLayer.diffuseTexture);
            mat.SetTexture("_Normal" + i, terrainLayer.normalMapTexture);
            mat.SetTexture("_Mask" + i, terrainLayer.maskMapTexture);
            mat.SetTextureScale("_Splat" + i, tiling);
            mat.SetTextureOffset("_Splat" + i, terrainLayer.tileOffset);
            mat.SetVector("_DiffuseRemapScale" + i, Vector4.one);
            mat.SetFloat("_NormalScale" + i, terrainLayer.normalScale);
            mat.SetFloat("_Smoothness" + i, terrainLayer.smoothness);
            //很神奇，地形的Metallic竟然需要gamma转换到线性
            mat.SetFloat("_Metallic" + i, Mathf.GammaToLinearSpace(terrainLayer.metallic));

            mat.SetFloat("_LayerHasMask" + i, terrainLayer.maskMapTexture == null ? 0 : 1);
            Vector4 max = terrainLayer.maskMapRemapMax;
            Vector4 min = terrainLayer.maskMapRemapMin;
            Vector4 maskRemapScale = Vector4.one;
            Vector4 maskRemapOffset = Vector4.zero;
            for (int j = 0; j < 4; j++)
            {
                float minValue = min[j];
                float maxValue = max[j];
                maskRemapScale[j] = maxValue - minValue;
                maskRemapOffset[j]= minValue;
            }
            mat.SetVector("_MaskMapRemapScale" + i, maskRemapScale);
            mat.SetVector("_MaskMapRemapOffset" + i, maskRemapOffset);

            Texture2D diffuseTexture = terrainLayer.diffuseTexture;
            if (diffuseTexture.format == TextureFormat.ARGB32 || diffuseTexture.format == TextureFormat.RGBA32)
            {
                mat.SetFloat("_DiffuseHasAlpha" + i, 1);
            }
            else
            {
                mat.SetFloat("_DiffuseHasAlpha" + i, 0);
            }
        }
    }

    public Material GetBakeAlbedo(Terrain t)
    {
        Material mat = new Material(bakeAlbedoShader);
        InitBakeMaterial(mat, t);
        return mat;
    }

    public Material GetBakeNormal(Terrain t)
    {
        Material mat = new Material(bakeBumpShader);
        InitBakeMaterial(mat, t);
        return mat;
    }

    public Material GetSplatmapAtlasMat(Texture2D controlMap, Texture2D diffuseAtlas, Texture2D normalAtlas)
    {
        Material mat = new Material(terrainSplatmapAtlasShader);
        mat.SetTexture("_Control", controlMap);
        mat.SetTexture("_Splat0", diffuseAtlas);
        mat.SetTexture("_Normal0", normalAtlas);

        if(diffuseAtlas != null)
        {
            Vector4 scaleFactor = mat.GetVector("_ScaleFactor");
            scaleFactor.x = (diffuseAtlas.width / diffuseAtlas.height * 0.25f);
            mat.SetVector("_ScaleFactor", scaleFactor);
        }
        return mat;
    }

    public Material SaveBakedMaterial(string path, Texture2D albeto, Texture2D normal, Texture hole, Vector2 size, Vector2 localOffset)
    {
        var scale = new Vector2(1f / size.x, 1f / size.y);
        var offset = -new Vector2(localOffset.x * scale.x, localOffset.y * scale.y);
        Material tMat = new Material(terrainBasemapShader);
        tMat.SetTexture("_Diffuse", albeto);
        tMat.SetTextureScale("_Diffuse", scale);
        tMat.SetTextureOffset("_Diffuse", offset);
        tMat.SetTexture("_Normal", normal);
        tMat.SetTextureScale("_Normal", scale);
        tMat.SetTextureOffset("_Normal", offset);
        tMat.EnableKeyword("_NORMALMAP");
        tMat.SetTexture("_TerrainHolesTexture", hole);
        if (hole != null)
        {
            tMat.EnableKeyword("_ALPHATEST_ON");
        }
        else
        {
            tMat.DisableKeyword("_ALPHATEST_ON");
        }
        AssetDatabase.CreateAsset(tMat, path);
        return tMat;
    }

    private static void SaveMixMaterail(string path, string dataName, Terrain t, int matIdx, int layerStart, Shader shader, List<string> assetPath)
    {
        Texture2D alphaMap = MatUtils.ExportAlphaMap(path, dataName, t, matIdx);
        if (alphaMap == null)
            return;
        //
        string mathPath = string.Format("{0}/{1}_{2}.mat", path, dataName, matIdx);
        Material mat = AssetDatabase.LoadAssetAtPath<Material>(mathPath);
        if (mat != null)
            AssetDatabase.DeleteAsset(mathPath);
        Material tMat = new Material(shader);
        tMat.SetTexture("_Control", alphaMap);
        if (tMat == null)
        {
            Debug.LogError("export terrain material failed");
            return;
        }
        for (int l = layerStart; l < layerStart + 4 && l < t.terrainData.terrainLayers.Length; ++l)
        {
            int idx = l - layerStart;
            TerrainLayer layer = t.terrainData.terrainLayers[l];
            Vector2 tiling = new Vector2(t.terrainData.size.x / layer.tileSize.x,
                t.terrainData.size.z / layer.tileSize.y);
            tMat.SetTexture(string.Format("_Splat{0}", idx), layer.diffuseTexture);
            tMat.SetTextureOffset(string.Format("_Splat{0}", idx), layer.tileOffset);
            tMat.SetTextureScale(string.Format("_Splat{0}", idx), tiling);
            tMat.SetTexture(string.Format("_Normal{0}", idx), layer.normalMapTexture);
            tMat.SetFloat(string.Format("_NormalScale{0}", idx), layer.normalScale);
            tMat.SetFloat(string.Format("_Metallic{0}", idx), layer.metallic);
            tMat.SetFloat(string.Format("_Smoothness{0}", idx), layer.smoothness);
            tMat.EnableKeyword("_NORMALMAP");
            if (layer.maskMapTexture != null)
            {
                tMat.EnableKeyword("_MASKMAP");
                tMat.SetFloat(string.Format("_LayerHasMask{0}", idx), 1f);
                tMat.SetTexture(string.Format("_Mask{0}", idx), layer.maskMapTexture);
            }
            else
            {
                tMat.SetFloat(string.Format("_LayerHasMask{0}", idx), 0f);
            }
        }
        AssetDatabase.CreateAsset(tMat, mathPath);
        if (assetPath != null)
            assetPath.Add(mathPath);
    }

    public void SaveMixMaterials(string path, string dataName, Terrain t, List<string> assetPath)
    {
        if (t.terrainData == null)
        {
            Debug.LogError("terrain data doesn't exist");
            return;
        }
        int matCount = t.terrainData.alphamapTextureCount;
        if (matCount <= 0)
            return;
        //base pass
        SaveMixMaterail(path, dataName, t, 0, 0, terrainSplatmapShader, assetPath);
        for (int i = 1; i < matCount; ++i)
        {
            SaveMixMaterail(path, dataName, t, i, i * 4, terrainSplatmapAddShader, assetPath);
        }
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
}
