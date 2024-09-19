#if UNITY_EDITOR
namespace MightyTerrainMesh
{
    using System.Collections;
    using System.Collections.Generic;
    using System.IO;
    using UnityEngine;
    using UnityEditor;

    public static class MTMatUtils
    {
        public static Texture2D ExportAlphaMap(string path, string dataName, Terrain t, int matIdx)
        {
            if (matIdx >= t.terrainData.alphamapTextureCount)
                return null;
            //alpha map
            byte[] alphaMapData = t.terrainData.alphamapTextures[matIdx].EncodeToPNG();
            string alphaMapSavePath = string.Format("{0}/{1}_alpha{2}.png",
                path, dataName, matIdx);
            if (File.Exists(alphaMapSavePath))
                File.Delete(alphaMapSavePath);
            FileStream stream = File.Open(alphaMapSavePath, FileMode.Create);
            stream.Write(alphaMapData, 0, alphaMapData.Length);
            stream.Close();
            AssetDatabase.Refresh();
            string alphaMapPath = string.Format("{0}/{1}_alpha{2}.png", path,
                dataName, matIdx);
            //the alpha map texture has to be set to best compression quality, otherwise the black spot may
            //show on the ground
            TextureImporter importer = AssetImporter.GetAtPath(alphaMapPath) as TextureImporter;
            if (importer == null)
            {
                MTLog.LogError("export terrain alpha map failed");
                return null;
            }
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.sRGBTexture = false; //数据贴图，千万别srgb
            importer.mipmapEnabled = false;
            importer.textureType = TextureImporterType.Default;
            importer.wrapMode = TextureWrapMode.Clamp;
            EditorUtility.SetDirty(importer);
            importer.SaveAndReimport();
            return AssetDatabase.LoadAssetAtPath<Texture2D>(alphaMapPath);
        }

        private static void SaveVTMaterail(string path, string dataName, Terrain t, int matIdx, int layerStart, string shaderPostfix,
            List<string> albetoPath, List<string> bumpPath)
        {
            Texture2D alphaMap = ExportAlphaMap(path, dataName, t, matIdx);
            if (alphaMap == null)
                return;
            //
            string mathPath = string.Format("{0}/VTDiffuse_{1}.mat", path, matIdx);
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(mathPath);
            if (mat != null)
                AssetDatabase.DeleteAsset(mathPath);
            Material tMat = new Material(Shader.Find("MT/VTDiffuse" + shaderPostfix));
            tMat.SetTexture("_Control", alphaMap);
            if (tMat == null)
            {
                MTLog.LogError("export terrain vt diffuse material failed");
                return;
            }
            string bumpMatPath = string.Format("{0}/VTBump_{1}.mat", path, matIdx);
            Material bmat = AssetDatabase.LoadAssetAtPath<Material>(bumpMatPath);
            if (bmat != null)
                AssetDatabase.DeleteAsset(bumpMatPath);
            Material bumpmat = new Material(Shader.Find("MT/VTBump" + shaderPostfix));
            bumpmat.SetTexture("_Control", alphaMap);
            if (bumpmat == null)
            {
                MTLog.LogError("export terrain vt bump material failed");
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
                var diffuseRemapScale = layer.diffuseRemapMax - layer.diffuseRemapMin;
                if (diffuseRemapScale.magnitude > 0)
                    tMat.SetColor(string.Format("_DiffuseRemapScale{0}", idx), diffuseRemapScale);
                else
                    tMat.SetColor(string.Format("_DiffuseRemapScale{0}", idx), Color.white);
                if (layer.maskMapTexture != null)
                {
                    tMat.SetFloat(string.Format("_HasMask{0}", idx), 1f);
                    tMat.SetTexture(string.Format("_Mask{0}", idx), layer.maskMapTexture);
                }
                else
                {
                    tMat.SetFloat(string.Format("_HasMask{0}", idx), 0f);
                }
                tMat.SetFloat(string.Format("_Smoothness{0}", idx), layer.smoothness);

                bumpmat.SetTexture(string.Format("_Normal{0}", idx), layer.normalMapTexture);
                bumpmat.SetFloat(string.Format("_NormalScale{0}", idx), layer.normalScale);
                bumpmat.SetTextureOffset(string.Format("_Normal{0}", idx), layer.tileOffset);
                bumpmat.SetTextureScale(string.Format("_Normal{0}", idx), tiling);
                if (layer.maskMapTexture != null)
                {
                    bumpmat.SetFloat(string.Format("_HasMask{0}", idx), 1f);
                    bumpmat.SetTexture(string.Format("_Mask{0}", idx), layer.maskMapTexture);
                }
                else
                {
                    bumpmat.SetFloat(string.Format("_HasMask{0}", idx), 0f);
                }
                bumpmat.SetFloat(string.Format("_Metallic{0}", idx), layer.metallic);
            }
            AssetDatabase.CreateAsset(tMat, mathPath);
            if (albetoPath != null)
                albetoPath.Add(mathPath);
            AssetDatabase.CreateAsset(bumpmat, bumpMatPath);
            if (bumpPath != null)
                bumpPath.Add(bumpMatPath);
        }
        public static void SaveVTMaterials(string path, string dataName, Terrain t,
            List<string> albetoPath, List<string> bumpPath)
        {
            if (t.terrainData == null)
            {
                MTLog.LogError("terrain data doesn't exist");
                return;
            }
            int matCount = t.terrainData.alphamapTextureCount;
            if (matCount <= 0)
                return;
            //base pass
            SaveVTMaterail(path, dataName, t, 0, 0, "", albetoPath, bumpPath);
            for (int i = 1; i < matCount; ++i)
            {
                SaveVTMaterail(path, dataName, t, i, i * 4, "Add", albetoPath, bumpPath);
            }
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
 

        private static Material GetBakeNormal(Terrain t, int matIdx, int layerStart, Shader shader)
        {
            Material tMat = new Material(shader);
            if (matIdx < t.terrainData.alphamapTextureCount)
            {
                var alphaMap = t.terrainData.alphamapTextures[matIdx];
                tMat.SetTexture("_Control", alphaMap);
            }
            for (int l = layerStart; l < layerStart + 4 && l < t.terrainData.terrainLayers.Length; ++l)
            {
                int idx = l - layerStart;
                TerrainLayer layer = t.terrainData.terrainLayers[l];
                Vector2 tiling = new Vector2(t.terrainData.size.x / layer.tileSize.x,
                    t.terrainData.size.z / layer.tileSize.y);
                tMat.SetTexture(string.Format("_Normal{0}", idx), layer.normalMapTexture);
                tMat.SetFloat(string.Format("_NormalScale{0}", idx), layer.normalScale);
                tMat.SetTextureOffset(string.Format("_Normal{0}", idx), layer.tileOffset);
                tMat.SetTextureScale(string.Format("_Normal{0}", idx), tiling); 
                if (layer.maskMapTexture != null)
                {
                    tMat.SetFloat(string.Format("_HasMask{0}", idx), 1f);
                    tMat.SetTexture(string.Format("_Mask{0}", idx), layer.maskMapTexture);
                }
                else
                {
                    tMat.SetFloat(string.Format("_HasMask{0}", idx), 0f);
                }
                tMat.SetFloat(string.Format("_Metallic{0}", idx), layer.metallic);
            }
            return tMat;
        }

        public static void GetBakeMaterials(Terrain t, Material[] albetos, Material[] bumps, ConversionShaderSuite conversionShaderSuite)
        {
            if (t.terrainData == null)
            {
                MTLog.LogError("terrain data doesn't exist");
                return;
            }
            int matCount = t.terrainData.alphamapTextureCount;
            if (matCount <= 0 || albetos == null || albetos.Length < 1 || bumps == null || bumps.Length < 1)
                return;
            //base pass
            albetos[0] = conversionShaderSuite.GetBakeAlbedo(t); 
            bumps[0] = conversionShaderSuite.GetBakeNormal(t);
        }
    }
}
#endif
