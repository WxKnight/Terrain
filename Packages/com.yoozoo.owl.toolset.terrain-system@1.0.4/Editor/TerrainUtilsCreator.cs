using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Text;
using System.IO;

public class TerrainUtilsCreator : EditorWindow
{
    private int controlNum = 4;

    [MenuItem("HRPTerrain/模板化shader (TA)")]
    private static void Open()
    {
        GetWindow<TerrainUtilsCreator>();
    }

    private void OnGUI()
    {
        controlNum = EditorGUILayout.IntField("Control Count", controlNum);
        if (GUILayout.Button("创建"))
        {
            CreateAutoTerrainLitInput();
            CreateTerrianLitPassesTemplate();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }

    private void CreateTerrianLitPassesTemplate()
    {
        StringBuilder sb = new StringBuilder();
        sb.AppendLine(@"#ifndef TERRAIN_SYSTEM_HRP_TERRAIN_LIT_PASSES_INCLUDED");
        sb.AppendLine(@"#define TERRAIN_SYSTEM_HRP_TERRAIN_LIT_PASSES_INCLUDED");

        string[] splitor = new string[] { "####" };
        string[] templates = File.ReadAllText("Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitPassesTemplate.txt").Split(splitor, System.StringSplitOptions.None);

        int searchIndex = 0;
        /*******************************************************/
        string textureNoTile = templates[searchIndex++];
        sb.AppendLine(textureNoTile);

        /*******************************************************/
        string splatMixFunc = templates[searchIndex++];
        for (int i = 0; i < controlNum; i++)
        {
            string output = "";
            output = splatMixFunc.Replace("SplatmapMix", $"SplatmapMix{i}");
            for (int j = 0; j < 4; j++)
            {
                output = output.Replace("{_Splat" + j + "}", $"_Splat{i * 4 + j}");
                output = output.Replace("{_DiffuseRemapScale" + j + "}", $"_DiffuseRemapScale{i * 4 + j}");
                output = output.Replace("{_Normal" + j + "}", $"_Normal{i * 4 + j}");
                output = output.Replace("{_NormalScale" + j + "}", $"_NormalScale{i * 4 + j}");
                output = output.Replace("{_Smoothness" + j + "}", $"_Smoothness{i * 4 + j}");
                output = output.Replace("{_DiffuseHasAlpha" + j + "}", $"_DiffuseHasAlpha{i * 4 + j}");
            }
            sb.AppendLine(output);
        }

        /*******************************************************/
        string varingStr = ReplaceVaring(templates, searchIndex++);
        sb.AppendLine(varingStr);

        /*******************************************************/
        string heightBasedSplatModifyFunc = ReplaceHeightBasedModifyFunc(templates, searchIndex++);
        sb.AppendLine(heightBasedSplatModifyFunc);

        /*******************************************************/
        string computeMaskTemp = templates[searchIndex++];
        for (int i = 0; i < controlNum; i++)
        {
            string computeMasks = computeMaskTemp;
            string index = i.ToString();
            string getMasks = "";
            getMasks += $"\tmasks[0] = lerp(masks[0], SampleTex(_Mask{i * 4 + 0}, sampler_Mask0, IN.uvSplat{i * 4 + 0}{i * 4 + 1}.xy), hasMask.x);\n";
            getMasks += $"\tmasks[1] = lerp(masks[1], SampleTex(_Mask{i * 4 + 1}, sampler_Mask0, IN.uvSplat{i * 4 + 0}{i * 4 + 1}.zw), hasMask.y);\n";
            getMasks += $"\tmasks[2] = lerp(masks[2], SampleTex(_Mask{i * 4 + 2}, sampler_Mask0, IN.uvSplat{i * 4 + 2}{i * 4 + 3}.xy), hasMask.z);\n";
            getMasks += $"\tmasks[3] = lerp(masks[3], SampleTex(_Mask{i * 4 + 3}, sampler_Mask0, IN.uvSplat{i * 4 + 2}{i * 4 + 3}.zw), hasMask.w);\n";

            string rescaleMasks = "";
            for (int j = 0; j < 4; j++)
            {
                rescaleMasks += $"\tmasks[{j}] *= _MaskMapRemapScale{i * 4 + j}.rgba;\n";
                rescaleMasks += $"\tmasks[{j}] += _MaskMapRemapOffset{i * 4 + j}.rgba;\n";
            }

            computeMasks = computeMasks.Replace("{index}", index);
            computeMasks = computeMasks.Replace("{getMasks}", getMasks);
            computeMasks = computeMasks.Replace("{rescaleMasks}", rescaleMasks);
            sb.AppendLine(computeMasks);
        }

        /*******************************************************/
        string fetchSplat = ReplaceFecthSplat(templates, searchIndex++);
        sb.AppendLine(fetchSplat);

        /*******************************************************/
        string transformLayerUV = templates[searchIndex++];
        string getLayerUV = "";
        for (int i = 0; i < controlNum; i++)
        {
            getLayerUV += $"\to.uvSplat{i * 4 + 0}{i * 4 + 1}.xy = TRANSFORM_TEX(texcoord, _Splat{i * 4 + 0});\n";
            getLayerUV += $"\to.uvSplat{i * 4 + 0}{i * 4 + 1}.zw = TRANSFORM_TEX(texcoord, _Splat{i * 4 + 1});\n";
            getLayerUV += $"\to.uvSplat{i * 4 + 2}{i * 4 + 3}.xy = TRANSFORM_TEX(texcoord, _Splat{i * 4 + 2});\n";
            getLayerUV += $"\to.uvSplat{i * 4 + 2}{i * 4 + 3}.zw = TRANSFORM_TEX(texcoord, _Splat{i * 4 + 3});\n";
        }
        transformLayerUV = transformLayerUV.Replace("{getLayerUV}", getLayerUV);
        sb.Append(transformLayerUV);

        /*******************************************************/
        string fetchMos = templates[searchIndex++];
        for (int i = 0; i < controlNum; i++)
        {
            string output = "";
            output = fetchMos.Replace("FetchMOS", $"FetchMOS{i}");
            for (int j = 0; j < 4; j++)
            {
                output = output.Replace("{_Metallic" + j + "}", $"_Metallic{i * 4 + j}");
                output = output.Replace("{_MaskMapRemapScale" + j + "}", $"_MaskMapRemapScale{i * 4 + j}");
                output = output.Replace("{_MaskMapRemapOffset" + j + "}", $"_MaskMapRemapOffset{i * 4 + j}");
            }
            sb.AppendLine(output);
        }
        sb.AppendLine(@"#endif");
        File.WriteAllText("Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/AutoTerainLitPasses.hlsl", sb.ToString());
    }

    private string ReplaceFecthSplat(string[] templates, int index)
    {
        string fetchSplat = templates[index];
        string splatVar = $"inout half4 splatControl[{controlNum}]";
        string masksVar = $"inout half4 masks[{controlNum}][4]";
        string hasMaskVar = $"inout half4 hasMask[{controlNum}]";

        string getSplatControl = "";
        for (int i = 0; i < controlNum; i++)
        {
            string str = i == 0 ? "" : i.ToString();
            getSplatControl += $"\tsplatControl[{i}] = SAMPLE_TEXTURE2D(_Control{str}, sampler_Control, splatUV);\n";
        }

        string computeMask = "";
        for (int i = 0; i < controlNum; i++)
        {
            computeMask += $"\thasMask[{i}] = half4(_LayerHasMask{i * 4 + 0}, _LayerHasMask{i * 4 + 1}, _LayerHasMask{i * 4 + 2}, _LayerHasMask{i * 4 + 3});\n";
            // computeMask += $"\thalf4 masks{i}[4];\n";
            computeMask += $"\tComputeMasks{i}(masks[{i}], hasMask[{i}], IN);\n";
        }

        string heightBasedSplatModify = "";
        heightBasedSplatModify += $"\tHeightBasedSplatModify(";
        for (int i = 0; i < controlNum; i++)
        {
            heightBasedSplatModify += $"splatControl[{i}], ";
        }
        for (int i = 0; i < controlNum; i++)
        {
            if (i < controlNum - 1)
            {
                heightBasedSplatModify += $"masks[{i}], ";
            }
            else
            {
                heightBasedSplatModify += $"masks[{i}]);";
            }
        }
        fetchSplat = fetchSplat.Replace("{splatVar}", splatVar);
        fetchSplat = fetchSplat.Replace("{masksVar}", masksVar);
        fetchSplat = fetchSplat.Replace("{hasMaskVar}", hasMaskVar);
        fetchSplat = fetchSplat.Replace("{getSplatControl}", getSplatControl);
        fetchSplat = fetchSplat.Replace("{computeMask}", computeMask);
        fetchSplat = fetchSplat.Replace("{heightBasedSplatModify}", heightBasedSplatModify);
        return fetchSplat;
    }

    private string ReplaceVaring(string[] templates, int index)
    {
        string varingStr = templates[index];
        string varingReplace = "";
        for (int i = 1; i < controlNum; i++)
        {
            varingReplace += $"\tfloat4 uvSplat{i * 4}{i * 4 + 1}      : TEXCOORD{8 + i * 2};\n";
            varingReplace += $"\tfloat4 uvSplat{i * 4 + 2}{i * 4 + 3}      : TEXCOORD{8 + i * 2 + 1};\n";
        }
        varingStr = varingStr.Replace("{uvSplat}", varingReplace);
        return varingStr;
    }

    private string ReplaceHeightBasedModifyFunc(string[] templates, int index)
    {
        string heightBasedSplatModify = templates[index];
        string splatControlVar = "";
        for (int i = 0; i < controlNum; i++)
        {
            if (i < controlNum - 1)
            {
                splatControlVar += $"inout half4 splatControl{i}, ";
            }
            else
            {
                splatControlVar += $"inout half4 splatControl{i}";
            }
        }
        string masksVar = "";
        for (int i = 0; i < controlNum; i++)
        {
            if (i < controlNum - 1)
            {
                masksVar += $"in half4 masks{i}[4], ";
            }
            else
            {
                masksVar += $"in half4 masks{i}[4]";
            }
        }
        string getSplatHeight = "";
        for (int i = 0; i < controlNum; i++)
        {
            getSplatHeight += $"\thalf4 splatHeight{i} = half4(masks{i}[0].b, masks{i}[1].b, masks{i}[2].b, masks{i}[3].b) * splatControl{i}.rgba;\n";
        }
        string getMaxHeight = "\thalf maxHeight = 0;\n";
        for (int i = 0; i < controlNum; i++)
        {
            getMaxHeight += $"\tmaxHeight = max(maxHeight, max(splatHeight{i}.r, max(splatHeight{i}.g, max(splatHeight{i}.b, splatHeight{i}.a))));\n";
        }
        string getWeightedHeights = "";
        for (int i = 0; i < controlNum; i++)
        {
            getWeightedHeights += $"\thalf4 weightedHeights{i} = splatHeight{i} + transition - maxHeight.xxxx;\n";
            getWeightedHeights += $"\tweightedHeights{i} = max(0, weightedHeights{i});\n";
            getWeightedHeights += $"\tweightedHeights{i} = (weightedHeights{i} + 1e-6) * splatControl{i};\n";
        }
        string getSumHeight = "\thalf sumHeight = 1e-6;\n";
        for (int i = 0; i < controlNum; i++)
        {
            getSumHeight += $"\tsumHeight += max(dot(weightedHeights{i}, half4(1,1,1,1)), 0);\n";
        }
        string modifySplatControl = "";
        for (int i = 0; i < controlNum; i++)
        {
            modifySplatControl += $"\tsplatControl{i} = weightedHeights{i} / sumHeight.xxxx;\n";
        }
        heightBasedSplatModify = heightBasedSplatModify.Replace("{splatControlVar}", splatControlVar);
        heightBasedSplatModify = heightBasedSplatModify.Replace("{masksVar}", masksVar);
        heightBasedSplatModify = heightBasedSplatModify.Replace("{getSplatHeight}", getSplatHeight);
        heightBasedSplatModify = heightBasedSplatModify.Replace("{getMaxHeight}", getMaxHeight);
        heightBasedSplatModify = heightBasedSplatModify.Replace("{getWeightedHeights}", getWeightedHeights);
        heightBasedSplatModify = heightBasedSplatModify.Replace("{getSumHeight}", getSumHeight);
        heightBasedSplatModify = heightBasedSplatModify.Replace("{modifySplatControl}", modifySplatControl);
        return heightBasedSplatModify;
    }

    private void CreateAutoTerrainLitInput()
    {
        StringBuilder sb = new StringBuilder();
        sb.AppendLine(@"#ifndef TERRAIN_SYSTEM_HRP_TERRAIN_LIT_INPUT_INCLUDED");
        sb.AppendLine(@"#define TERRAIN_SYSTEM_HRP_TERRAIN_LIT_INPUT_INCLUDED");
        for (int i = 0; i < controlNum; i++)
        {
            if (i == 0)
            {
                AddTexture2D(sb, $"_Control", true);
            }
            else
            {
                AddTexture2D(sb, $"_Control{i}");
            }

            for (int j = 0; j < 4; j++)
            {
                if (i == 0 && j == 0)
                {
                    AddTexture2D(sb, "_Splat" + (i * 4 + j), true);
                }
                else
                {
                    AddTexture2D(sb, "_Splat" + (i * 4 + j));
                }
            }

            for (int j = 0; j < 4; j++)
            {
                if (i == 0 && j == 0)
                {
                    AddTexture2D(sb, "_Normal" + (i * 4 + j), true);
                }
                else
                {
                    AddTexture2D(sb, "_Normal" + (i * 4 + j));
                }
            }

            for (int j = 0; j < 4; j++)
            {
                if (i == 0 && j == 0)
                {
                    AddTexture2D(sb, "_Mask" + (i * 4 + j), true);
                }
                else
                {
                    AddTexture2D(sb, "_Mask" + (i * 4 + j));
                }
            }
        }

        string[] splitor = new string[] { "####" };
        string[] templates = File.ReadAllText("Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/TerrainLitInputTemplate.txt").Split(splitor, System.StringSplitOptions.None);
        string cbufferTerrain = templates[0];
        string normalScale = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                normalScale += $"_NormalScale{i}, ";
            }
            else
            {
                normalScale += $"_NormalScale{i};";
            }
        }
        string metallic = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                metallic += $"_Metallic{i}, ";
            }
            else
            {
                metallic += $"_Metallic{i};";
            }
        }
        string diffuseRemapScale = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                diffuseRemapScale += $"_DiffuseRemapScale{i}, ";
            }
            else
            {
                diffuseRemapScale += $"_DiffuseRemapScale{i};";
            }
        }
        string maskRemapOffset = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                maskRemapOffset += $"_MaskMapRemapOffset{i}, ";
            }
            else
            {
                maskRemapOffset += $"_MaskMapRemapOffset{i};";
            }
        }
        string maskRemapScale = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                maskRemapScale += $"_MaskMapRemapScale{i}, ";
            }
            else
            {
                maskRemapScale += $"_MaskMapRemapScale{i};";
            }
        }
        string layerHasMask = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if(i < controlNum * 4 - 1)
            {
                layerHasMask += $"_LayerHasMask{i}, ";
            }
            else
            {
                layerHasMask += $"_LayerHasMask{i};";
            }
        }
        string splatST = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                splatST += $"_Splat{i}_ST, ";
            }
            else
            {
                splatST += $"_Splat{i}_ST;";
            }
        }
        string smoothness = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                smoothness += $"_Smoothness{i}, ";
            }
            else
            {
                smoothness += $"_Smoothness{i};";
            }
        }
        string diffuseHasMask = "";
        for (int i = 0; i < controlNum * 4; i++)
        {
            if (i < controlNum * 4 - 1)
            {
                diffuseHasMask += $"_DiffuseHasAlpha{i}, ";
            }
            else
            {
                diffuseHasMask += $"_DiffuseHasAlpha{i};";
            }
        }
        cbufferTerrain = cbufferTerrain.Replace("{normalScale}", normalScale);
        cbufferTerrain = cbufferTerrain.Replace("{metallic}", metallic);
        cbufferTerrain = cbufferTerrain.Replace("{maskRemapOffset}", maskRemapOffset);
        cbufferTerrain = cbufferTerrain.Replace("{maskRemapScale}", maskRemapScale);
        cbufferTerrain = cbufferTerrain.Replace("{layerHasMask}", layerHasMask);
        cbufferTerrain = cbufferTerrain.Replace("{splatST}", splatST);
        cbufferTerrain = cbufferTerrain.Replace("{diffuseRemapScale}", diffuseRemapScale);
        cbufferTerrain = cbufferTerrain.Replace("{smoothness}", smoothness);
        cbufferTerrain = cbufferTerrain.Replace("{diffuseHasMask}", diffuseHasMask);
        sb.AppendLine(cbufferTerrain);

        sb.AppendLine(@"#endif");
        File.WriteAllText("Packages/com.yoozoo.owl.toolset.terrain-system/Runtime/HRP/ShaderLibrary/AutoTerainLitInput.hlsl", sb.ToString());
    }

    private void AddTexture2D(StringBuilder sb, string variable, bool addSampler = false)
    {
        if (addSampler)
        {
            sb.Append($@"TEXTURE2D({variable});     ");
            AddSampler(sb, variable);
        }
        else
        {
            sb.AppendLine($@"TEXTURE2D({variable});");
        }
    }

    private void AddSampler(StringBuilder sb, string variable)
    {
        sb.AppendLine($@"SAMPLER(sampler{variable});");
    }
}
