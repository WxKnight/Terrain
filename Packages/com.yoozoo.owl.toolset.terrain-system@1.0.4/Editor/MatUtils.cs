using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class MatUtils
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
            Debug.LogError("export terrain alpha map failed");
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
}
