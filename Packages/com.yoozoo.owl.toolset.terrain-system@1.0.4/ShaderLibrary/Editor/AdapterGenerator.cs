using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

public class AdapterGenerator : Editor
{
    class AdapterData
    {
        public string macroName = "";
        public string path2019 = "";
        public string path2020 = "";
        public string path2021 = "";
    }

    enum AdapterType
    {
        CoreRP,
        URP,
        HRP,
    }

    class SearchData
    {
        public AdapterType adapterType;
        public int version;
    }

    private static string OriginCoreRPPath = "Packages/com.unity.render-pipelines.core";
    private static string OriginURPPath = "Packages/com.unity.render-pipelines.universal";
    private static string OriginHRP_URPPath = "Packages/com.yoozoo.owl.rendering.hrp/RenderPipeline/URP";
    private static string OriginHRP_CoreRPPath = "Packages/com.yoozoo.owl.rendering.hrp/RenderPipeline/CoreRP";
    private static string OriginHRP_Path = "Packages/com.yoozoo.owl.rendering.hrp";
    private static string PackagePath = "Packages/com.yoozoo.owl.toolset.terrain-system/ShaderLibrary";

    [MenuItem(itemName: "HRP/GenerateShaderAdapter")]
    static void GenerateAdapter()
    {
        string templateStr = AssetDatabase.LoadAssetAtPath<TextAsset>($"{PackagePath}/Editor/AdapterTemplate.txt").text;
        Dictionary<string, AdapterData> adapterDatas = new Dictionary<string, AdapterData>();
        List<SearchData> searchDatas = new List<SearchData>() {
            new SearchData { adapterType = AdapterType.CoreRP, version = 2019},
            new SearchData { adapterType = AdapterType.CoreRP, version = 2020},
            new SearchData { adapterType = AdapterType.CoreRP, version = 2021},
            new SearchData { adapterType = AdapterType.URP, version = 2019},
            new SearchData { adapterType = AdapterType.URP, version = 2020},
            new SearchData { adapterType = AdapterType.URP, version = 2021},
            new SearchData { adapterType = AdapterType.HRP, version = 2019},
            new SearchData { adapterType = AdapterType.HRP, version = 2020},
            new SearchData { adapterType = AdapterType.HRP, version = 2021}
        };

        //遍历所有corerp和urp的hlsl，用于生成adapter的hlsl
        foreach (var searchData in searchDatas)
        {
            string specificPath = GetSpecificPath(searchData);
            string searchPath = $"{PackagePath}/" + specificPath;
            string[] guids = AssetDatabase.FindAssets("", new string[] { searchPath });
            foreach (var guid in guids)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(guid);
                if (assetPath.EndsWith(".hlsl"))
                {
                    string adapterPath = "";
                    switch (searchData.adapterType)
                    {
                        case AdapterType.CoreRP:
                            adapterPath = assetPath.Replace(specificPath, "AdapterCoreRP");
                            break;
                        case AdapterType.URP:
                            adapterPath = assetPath.Replace(specificPath, "AdapterURP");
                            break;
                        case AdapterType.HRP:
                            adapterPath = assetPath.Replace(specificPath, "AdapterHRP");
                            break;
                        default:
                            break;
                    }

                    if (!adapterDatas.ContainsKey(adapterPath))
                    {
                        AdapterData adapterData = new AdapterData();
                        adapterData.macroName = "OWL_SHADER_LIBRARY_ADAPTER_";
                        switch (searchData.adapterType)
                        {
                            case AdapterType.CoreRP:
                                adapterData.macroName += "CORERP_";
                                break;
                            case AdapterType.URP:
                                adapterData.macroName += "URP_";
                                break;
                            case AdapterType.HRP:
                                adapterData.macroName += "HRP_";
                                break;
                            default:
                                break;
                        }

                        string fileName = Path.GetFileNameWithoutExtension(assetPath);

                        //处理一些特殊情况
                        adapterData.macroName += fileName.Replace(".cs", "_cs").ToUpper();
                        adapterDatas.Add(adapterPath, adapterData);
                    }

                    if (searchData.version == 2019)
                    {
                        adapterDatas[adapterPath].path2019 = assetPath;
                    }
                    else if (searchData.version == 2020)
                    {
                        adapterDatas[adapterPath].path2020 = assetPath;
                    }
                    else if (searchData.version == 2021)
                    {
                        adapterDatas[adapterPath].path2021 = assetPath;
                    }
                }
            }
        }

        foreach (var item in adapterDatas)
        {
            string resultStr = templateStr.Replace("{MarcroName}", item.Value.macroName);
            resultStr = ReplaceTemplatePath(resultStr, "{Path2019}", item.Value.path2019);
            resultStr = ReplaceTemplatePath(resultStr, "{Path2020}", item.Value.path2020);
            resultStr = ReplaceTemplatePath(resultStr, "{Path2021}", item.Value.path2021);

            if (!Directory.Exists(Path.GetDirectoryName(item.Key)))
            {
                Directory.CreateDirectory(Path.GetDirectoryName(item.Key));
            }
            File.WriteAllText(item.Key, resultStr);
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        //遍历所有corerp和urp的hlsl，将其中引用的路径替换为adapter的路径
        foreach (var searchData in searchDatas)
        {
            string specificPath = GetSpecificPath(searchData);

            string searchPath = $"{PackagePath}/" + specificPath;
            string[] guids = AssetDatabase.FindAssets("", new string[] { searchPath });
            foreach (var guid in guids)
            {
                string assetPath = AssetDatabase.GUIDToAssetPath(guid);
                if (assetPath.EndsWith(".hlsl"))
                {
                    string hlslStr = File.ReadAllText(assetPath);
                    bool needReplace = TryReplaceInclude(ref hlslStr); ;
                    if (needReplace)
                    {
                        File.WriteAllText(assetPath, hlslStr);
                    }
                }
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    private static string GetSpecificPath(SearchData searchData)
    {
        string specificPath = "";
        switch (searchData.adapterType)
        {
            case AdapterType.CoreRP:
                specificPath = "LibCoreRP/";
                break;
            case AdapterType.URP:
                specificPath = "LibURP/";
                break;
            case AdapterType.HRP:
                specificPath = "LibHRP/";
                break;
            default:
                break;
        }
        specificPath += searchData.version;
        return specificPath;
    }

    private static string ReplaceTemplatePath(string self, string pathName, string replaceStr)
    {
        if (string.IsNullOrEmpty(replaceStr))
        {
            return self.Replace(pathName, "");
        }
        else
        {
            return self.Replace(pathName, $"#include \"{replaceStr}\"");
        }
    }

    [MenuItem("Assets/TerrainSystem/转换urp及core依赖")]
    private static void TransferSelectedShaderInclude()
    {
        Object[] objects = Selection.objects;
        foreach (var obj in objects)
        {
            TransferShaderInclude(obj);
        }
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    private static void TransferShaderInclude(Object obj)
    {
        string assetPath = AssetDatabase.GetAssetPath(obj);
        if (!assetPath.EndsWith(".shader") && !assetPath.EndsWith(".hlsl"))
            return;

        string shaderStr = File.ReadAllText(assetPath);
        bool needReplace = TryReplaceInclude(ref shaderStr);

        if (needReplace)
        {
            File.WriteAllText(assetPath, shaderStr);
        }
    }

    private static bool TryReplaceInclude(ref string shaderStr)
    {
        bool needReplace = false;

        if (shaderStr.Contains(OriginCoreRPPath))
        {
            shaderStr = shaderStr.Replace(OriginCoreRPPath, $"{PackagePath}/AdapterCoreRP");
            needReplace = true;
        }
        if (shaderStr.Contains(OriginURPPath))
        {
            shaderStr = shaderStr.Replace(OriginURPPath, $"{PackagePath}/AdapterURP");
            needReplace = true;
        }
        if (shaderStr.Contains(OriginHRP_CoreRPPath))
        {
            shaderStr = shaderStr.Replace(OriginHRP_CoreRPPath, $"{PackagePath}/AdapterCoreRP");
            needReplace = true;
        }
        if (shaderStr.Contains(OriginHRP_URPPath))
        {
            shaderStr = shaderStr.Replace(OriginHRP_URPPath, $"{PackagePath}/AdapterURP");
            needReplace = true;
        }
        if (shaderStr.Contains(OriginHRP_Path))
        {
            shaderStr = shaderStr.Replace(OriginHRP_Path, $"{PackagePath}/AdapterHRP");
            needReplace = true;
        }

        return needReplace;
    }
}
