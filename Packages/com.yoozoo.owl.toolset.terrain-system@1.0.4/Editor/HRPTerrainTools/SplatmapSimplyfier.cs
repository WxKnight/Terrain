using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Experimental.TerrainAPI;
using UnityEngine;

public class SplitTerrainQuadTree : TerrainQuadTree<SplitTerrainQuadTree>
{
    public static int maxControlMapCount = 1;

    public SplitTerrainQuadTree(Terrain terrain, int depth, bool isFirstNode) : base(terrain, depth, isFirstNode)
    {

    }

    protected override void HandleSplatmap()
    {
        //实际切割的第一个节点不需要处理
        if (isFirstNode)
            return;

        if (terrain.terrainData.alphamapTextureCount <= 1)
            return;

        RefreshSplatmapLayerInfo(new RectInt(0, 0, terrain.terrainData.alphamapWidth, terrain.terrainData.alphamapHeight));

        if (validChannelNum <= maxControlMapCount * 4 || depth >= maxDepth)
        {
            int layer = validChannelNum;

            TerrainLayer[] originTerrainLayers = terrain.terrainData.terrainLayers;
            TerrainLayer[] newTerrainLayers = new TerrainLayer[layer];

            float[,,] newMaps = new float[terrain.terrainData.alphamapWidth, terrain.terrainData.alphamapHeight, layer];
            for (int i = 0; i < layer; i++)
            {
                var splatmapLayerInfo = splatmapLayerInfos[i];
                newTerrainLayers[i] = originTerrainLayers[splatmapLayerInfo.channelId];

                for (int x = 0; x < terrain.terrainData.alphamapWidth; x++)
                {
                    for (int y = 0; y < terrain.terrainData.alphamapHeight; y++)
                    {
                        newMaps[x, y, i] = splatmapLayerInfo.values[x, y];
                    }
                }
            }

            terrain.terrainData.terrainLayers = newTerrainLayers;
            terrain.terrainData.SetAlphamaps(0, 0, newMaps);
            EditorUtility.SetDirty(terrain.terrainData);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }

    protected override bool NeedSplit()
    {
        return terrain.terrainData.alphamapTextureCount > maxControlMapCount && terrain.terrainData.heightmapResolution >= 64 && depth < maxDepth;
    }

    protected override void Split()
    {
        Selection.activeObject = terrain;
        TerrainToolboxUtilities m_TerrainUtilitiesMode = new TerrainToolboxUtilities();
        m_TerrainUtilitiesMode.m_Settings.TileXAxis = 2;
        m_TerrainUtilitiesMode.m_Settings.TileZAxis = 2;
        m_TerrainUtilitiesMode.m_Settings.KeepOldTerrains = isFirstNode;
        m_TerrainUtilitiesMode.SplitTerrains(removeTerrainData: !isFirstNode);
        for (int i = 0; i < m_TerrainUtilitiesMode.m_SplitTerrains.Length; i++)
        {
            nodes[i] = new SplitTerrainQuadTree(m_TerrainUtilitiesMode.m_SplitTerrains[i], depth + 1, false);
        }
    }
}

public class SplatmapSimplifier : EditorWindow
{
    [SerializeField]
    private Terrain terrainTarget;
    [SerializeField]
    private TerrainSplitErrorShower errorShower;
    [SerializeField]
    private int splitCount = 16;
    [SerializeField]
    private List<SplatmapLayerInfo> selectedTerrainLayers = new List<SplatmapLayerInfo>();
    [SerializeField]
    private bool realtimeRefresh;
    private bool isControlDown;

    private int maximumSplitCount = 128;

    private Terrain prevTerrainTarget;
    private Stack<float[,,]> originAlphaMaps = new Stack<float[,,]>();
    [SerializeField]
    private int controlSize = 1024;
    [SerializeField]
    private int texturePieceSize = 256;

    [MenuItem("HRPTerrain/SplatmapSimplifier", priority = 0)]
    private static void ShowWindow()
    {
        EditorWindow.CreateWindow<SplatmapSimplifier>();
    }

    private void OnEnable()
    {
        AddErrorShower();
        // first add your function to be called on redraw
        SceneView.duringSceneGui += UpdateRaycast;
        if (terrainTarget == null)
        {
            Terrain[] terrains = FindObjectsOfType<Terrain>(true);
            if (terrains != null && terrains.Length == 1)
            {
                terrainTarget = terrains[0];
                CheckTerrainTarget();
            }
        }
    }

    private void RefreshErrorShower()
    {
        RefreshMaxDepth();
        errorShower?.RefreshSplitInfo();
    }

    private void RefreshMaxDepth()
    {
        splitCount = Mathf.Clamp(1, splitCount, maximumSplitCount);
        splitCount = splitCount == 1 ? 1 : Mathf.ClosestPowerOfTwo(splitCount);
        int maxDepth = Mathf.RoundToInt(Mathf.Log(splitCount, 2f));
        SimplifySplatmapQuadTree.maxDepth = maxDepth;
        SplitTerrainQuadTree.maxDepth = maxDepth;
    }

    private void OnDisable()
    {
        RemoveErrorShower();
        SceneView.duringSceneGui -= UpdateRaycast;
    }

    private void UpdateRaycast(SceneView sceneView)
    {
        Event current = Event.current;
        if (current.isKey && current.keyCode == KeyCode.LeftControl)
        {
            if (current.type == EventType.KeyDown)
            {
                isControlDown = true;
            }
            else if (current.type == EventType.KeyUp)
            {
                isControlDown = false;
            }
        }

        if (errorShower == null || (!realtimeRefresh && !isControlDown))
            return;

        if (current.type == EventType.MouseUp && current.isMouse)
        {
            // then in that function raycast
            Vector3 mousePosition = current.mousePosition;
            mousePosition.y = SceneView.currentDrawingSceneView.camera.pixelHeight - mousePosition.y;
            mousePosition = SceneView.currentDrawingSceneView.camera.ScreenToWorldPoint(mousePosition);
            mousePosition.y = -mousePosition.y;

            Ray mouseRay = HandleUtility.GUIPointToWorldRay(current.mousePosition);
            RaycastHit[] hits = Physics.RaycastAll(mouseRay);
            foreach (var hit in hits)
            {
                if (hit.collider is TerrainCollider && hit.collider.GetComponent<Terrain>() == terrainTarget)
                {
                    if (current.button == 0 && realtimeRefresh)
                    {
                        errorShower.RefreshSplitInfo();
                    }
                    else if (current.button == 1 && isControlDown)
                    {
                        selectedTerrainLayers.Clear();
                        Vector3 offset = hit.point - terrainTarget.transform.position;
                        TerrainData terrainData = terrainTarget.terrainData;
                        Vector2 uv = new Vector2(offset.x / terrainData.size.x, offset.z / terrainData.size.z);
                        float[,,] maps = terrainData.GetAlphamaps((int)(uv.x * terrainData.alphamapWidth), (int)(uv.y * terrainData.alphamapHeight), 1, 1);
                        int length = maps.GetLength(2);
                        for (int i = 0; i < length; i++)
                        {
                            if (maps[0, 0, i] > 0)
                            {
                                SplatmapLayerInfo splatmap = new SplatmapLayerInfo(i, 1, 1);
                                splatmap.validWeight += maps[0, 0, i];
                                selectedTerrainLayers.Add(splatmap);
                            }
                        }

                        selectedTerrainLayers.Sort((left, right) =>
                        {
                            return (int)((right.validWeight - left.validWeight) * 10000);
                        });

                        Repaint();
                    }
                    break;
                }
            }
        }
    }


    private void AddErrorShower()
    {
        RemoveErrorShower();
        errorShower = FindObjectOfType<TerrainSplitErrorShower>();
        if (errorShower == null)
        {
            errorShower = new GameObject("ErrorShower").AddComponent<TerrainSplitErrorShower>();
        }
        errorShower.Init(terrainTarget);
        errorShower.gameObject.hideFlags = HideFlags.DontSave;
    }

    private void RemoveErrorShower()
    {
        if (errorShower != null)
        {
            errorShower.showGizmos = false;
            DestroyImmediate(errorShower.gameObject);
            errorShower = null;
        }
    }

    private void CheckTerrainTarget()
    {
        if (terrainTarget != prevTerrainTarget)
        {
            if (terrainTarget != null)
            {
                maximumSplitCount = Math.Min(4096, terrainTarget.terrainData.alphamapWidth);
                AddErrorShower();
            }
            else
            {
                RemoveErrorShower();
            }
            selectedTerrainLayers.Clear();
        }

        prevTerrainTarget = terrainTarget;
    }

    public void OnGUI()
    {
        Event current = Event.current;
        if (current.isKey && current.keyCode == KeyCode.LeftControl)
        {
            if (current.type == EventType.KeyDown)
            {
                isControlDown = true;
            }
            else if (current.type == EventType.KeyUp)
            {
                isControlDown = false;
            }
        }

        terrainTarget = EditorGUILayout.ObjectField("Convert Target", terrainTarget, typeof(Terrain), true) as Terrain;
        CheckTerrainTarget();

        if (terrainTarget == null)
        {
            EditorGUILayout.LabelField("请先添加用于转换的地形");
            return;
        }

        TerrainData terrainData = terrainTarget.terrainData;
        TerrainLayer[] terrainLayers = terrainData.terrainLayers;

        EditorGUILayout.Space();
        EditorGUILayout.LabelField($"Splatmap贴图简化(原ControlMap Size: {terrainData.alphamapWidth}x{terrainData.alphamapHeight}，ControlMap越小简化速度越快)");

        EditorGUI.indentLevel++;
        EditorGUILayout.LabelField("分块简化Splatmap（每个分块将单独进行简化，N越大分的越细，但不要超过ControlMap大小");
        splitCount = EditorGUILayout.IntField("Simplify, N =", splitCount);
        RefreshMaxDepth();
        using (new EditorGUILayout.HorizontalScope())
        {
            EditorGUI.BeginChangeCheck();
            errorShower.showGizmos = EditorGUILayout.Toggle("显示预览", errorShower.showGizmos);
            float percent = errorShower.errorRange * 100;
            percent = EditorGUILayout.Slider("误差百分比(建议小于20%)", percent, 0f, 33f);
            errorShower.errorRange = percent * 0.01f;
            if (EditorGUI.EndChangeCheck())
            {
                SceneView.lastActiveSceneView.Repaint();
            }
            if (GUILayout.Button("预览"))
            {
                RefreshErrorShower();
                SceneView.lastActiveSceneView.Repaint();
            }
        }

        EditorGUILayout.LabelField("Splatmap简化");
        using (new EditorGUILayout.HorizontalScope())
        {
            GUILayout.Space(32f);
            if (GUILayout.Button("修改Splatmap（可还原）"))
            {
                ModifySplatmapWithSave(terrainData, terrainLayers, 2);
            }

            if (GUILayout.Button("还原"))
            {
                RevertSplatMap(terrainData);
            }
        }

        EditorGUILayout.LabelField("Splatmap图集生成");
        EditorGUI.indentLevel++;
        using (new EditorGUILayout.HorizontalScope())
        {
            controlSize = EditorGUILayout.IntField("简化控制图大小", controlSize);
            texturePieceSize = EditorGUILayout.IntField("每小块Diffuse/Normal大小", texturePieceSize);
            controlSize = Mathf.ClosestPowerOfTwo(controlSize);
            texturePieceSize = Mathf.ClosestPowerOfTwo(texturePieceSize);
        }
        EditorGUI.indentLevel--;

        using (new EditorGUILayout.HorizontalScope())
        {
            GUILayout.Space(32f);
            if (GUILayout.Button("创建Splatmap图集"))
            {
                if (EditorUtility.DisplayDialog("创建Splatmap图集", "请先确保Splatmap已经简化后再创建图集，否则结果可能会差异较大", "直接创建", "取消"))
                    CreateSplatmapAtlas();
            }
        }
        if (controlMap != null)
            EditorGUILayout.ObjectField("简化控制图结果", controlMap, typeof(UnityEngine.Object), false);
        EditorGUI.indentLevel--;

        ShowSplitTerrain(terrainData, terrainLayers);

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("其他");
        EditorGUI.indentLevel++;
        EditorGUILayout.LabelField("在地形上按住Ctrl并点击鼠标右键可以查看该处使用了哪些Layer进行混合，越靠前显示的Layer占比越大");
        if (selectedTerrainLayers.Count == 0)
        {
            EditorGUILayout.LabelField("没有可查看的Layer信息");
        }
        else
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                for (int i = 0; i < selectedTerrainLayers.Count; i++)
                {
                    EditorGUILayout.ObjectField(terrainLayers[selectedTerrainLayers[i].channelId], typeof(TerrainLayer), false);
                }
            }
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Space(20f);
                for (int i = 0; i < selectedTerrainLayers.Count; i++)
                {
                    GUILayout.Label(selectedTerrainLayers[i].validWeight.ToString());
                }
            }
        }
        EditorGUI.indentLevel--;
    }

    [SerializeField]
    private int maxControlmapCount = 1;
    private void ShowSplitTerrain(TerrainData terrainData, TerrainLayer[] terrainLayers)
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Splatmap地形切割");
        EditorGUI.indentLevel++;
        using (new EditorGUILayout.HorizontalScope())
        {
            GUILayout.Space(20f);
            GUILayout.Label("允许包含的Splatmap数量（1张对应4层Layer）");
            maxControlmapCount = EditorGUILayout.IntSlider(maxControlmapCount, 1, 4);
            if (GUILayout.Button("生成切割后的地形资源"))
            {
                if (EditorUtility.DisplayDialog("提示", "该操作将进行真正的地形切割，是否确定执行", "是", "否"))
                {
                    ModifySplatmapWithSave(terrainData, terrainLayers, maxControlmapCount * 4);
                    SplitTerrainQuadTree.maxControlMapCount = maxControlmapCount;
                    SplitTerrainQuadTree terrainSplitQuadTree = new SplitTerrainQuadTree(terrainTarget, 0, true);
                    terrainSplitQuadTree.BFIterate((node) =>
                    {
                        node.AutoSplit();
                    });
                    RevertSplatMap(terrainData);
                }
            }
        }
        EditorGUI.indentLevel--;
    }

    private Texture2D controlMap;

    private void CreateSplatmapAtlas()
    {
        TerrainLayer[] terrainLayers = terrainTarget.terrainData.terrainLayers;
        int hSegment = Mathf.Min(4, terrainLayers.Length);
        int vSegment = terrainLayers.Length / 4;
        CreateAtlas(terrainLayers, true, "Assets/Scenes/diffuseAtlas.tga", texturePieceSize, true, hSegment, vSegment);
        CreateAtlas(terrainLayers, true, "Assets/Scenes/normalAtlas.tga", texturePieceSize, false, hSegment, vSegment);
        float[,,] controlMapWeights = new float[controlSize, controlSize, 4];
        Array.Clear(controlMapWeights, 0, controlSize * controlSize * 4);
        Texture2D controlMap = EncodeControlMap(true, controlMapWeights);
        EncodeWeightMap(controlMap, controlMapWeights, false);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        this.controlMap = controlMap;
    }

    private void CreateAtlas(TerrainLayer[] terrainLayers, bool createTexture2DArray, string path, int blockSize, bool isDiffuse, int hSegment, int vSegment)
    {
        Texture2D[] textures = SplatmapSimplifier.CretaeTexture2Ds(terrainLayers, isDiffuse, blockSize, blockSize);
        if (!createTexture2DArray)
        {
            Texture2D atlas = isDiffuse ? new Texture2D(blockSize * hSegment, blockSize * vSegment, TextureFormat.ARGB32, true, true) : new Texture2D(blockSize * hSegment, blockSize * vSegment, TextureFormat.RGB24, true, true);
            atlas.wrapMode = TextureWrapMode.Clamp;
            atlas.filterMode = FilterMode.Point;
            atlas.anisoLevel = 0;
            for (int i = 0; i < textures.Length; i++)
            {
                int xMin = i % 4;
                int yMin = i / 4;
                Color[] colors = textures[i].GetPixels();
                atlas.SetPixels(xMin * blockSize, yMin * blockSize, blockSize, blockSize, colors);
            }
            atlas.Apply();
            byte[] data = atlas.EncodeToTGA();
            string filePath = Application.dataPath.Replace("Assets", path);
            File.WriteAllBytes(filePath, data);
        }
        else
        {
            Texture2DArray atlas = isDiffuse ? new Texture2DArray(blockSize, blockSize, textures.Length, TextureFormat.ARGB32, true, true) : new Texture2DArray(blockSize , blockSize, textures.Length, TextureFormat.RGB24, true, true);
            atlas.wrapMode = TextureWrapMode.Repeat;
            atlas.filterMode = FilterMode.Bilinear;
            atlas.anisoLevel = 0;
            for (int i = 0; i < textures.Length; i++)
            {
                Color[] colors = textures[i].GetPixels();
                atlas.SetPixels(colors, i);
            }
            atlas.Apply();
            string realPath = path.Replace(".tga", ".asset");
            AssetDatabase.DeleteAsset(realPath);
            AssetDatabase.CreateAsset(atlas, realPath);
        }

        AssetDatabase.Refresh();
    }

    class ActiveChannelInfo
    {
        public int channelId;
        public float weight;
    }

    private Texture2D EncodeControlMap(bool hasWeightmap, float[,,] controlMapWeights)
    {
        Texture2D controlMap = new Texture2D(controlSize, controlSize, TextureFormat.RGBA4444, false, true);
        controlMap.filterMode = FilterMode.Point;
        controlMap.anisoLevel = 0;
        controlMap.wrapMode = TextureWrapMode.Clamp;
        Texture2D[] alphaMapTextures = terrainTarget.terrainData.alphamapTextures;
        Color[] colors = new Color[alphaMapTextures.Length];
        List<ActiveChannelInfo> activeChannelInfos = new List<ActiveChannelInfo>();

        for (int x = 0; x < controlSize; x++)
        {
            for (int y = 0; y < controlSize; y++)
            {
                activeChannelInfos.Clear();
                Vector2 uv = new Vector2((x + 0.5f) / controlSize, (y + 0.5f) / controlSize);
                for (int i = 0; i < alphaMapTextures.Length; i++)
                {
                    colors[i] = alphaMapTextures[i].GetPixelBilinear(uv.x, uv.y);
                    colors[i] = alphaMapTextures[i].GetPixel(x, y);
                    for (int j = 0; j < 4; j++)
                    {
                        if (colors[i][j] > 0)
                        {
                            activeChannelInfos.Add(new ActiveChannelInfo() { channelId = i * 4 + j, weight = colors[i][j] });
                        }
                    }
                }

                activeChannelInfos.Sort((left, right) =>
                {
                    return (int)(left.weight - right.weight * 10000f);
                });

                if (!hasWeightmap)
                {
                    int validLayer = Mathf.Min(activeChannelInfos.Count, 2);
                    if (validLayer == 0)
                        continue;

                    //将ControlMap保存为R4G4B4A4
                    if (validLayer == 1)
                    {
                        float colorR = activeChannelInfos[0].channelId / 15f;
                        float colorG = 0f;
                        int weightValue = (int)(activeChannelInfos[0].weight * 255);
                        float colorB = (weightValue & 0xf) / 15f;
                        float colorA = (weightValue >> 4) / 15f;
                        controlMap.SetPixel(x, y, new Color(colorR, colorG, colorB, colorA));
                    }
                    else if (validLayer == 2)
                    {
                        float colorR = activeChannelInfos[0].channelId / 15f;
                        float colorG = activeChannelInfos[1].channelId / 15f;
                        int weightValue = (int)(activeChannelInfos[0].weight * 255);
                        float colorB = (weightValue & 0xf) / 15f;
                        float colorA = (weightValue >> 4) / 15f;
                        controlMap.SetPixel(x, y, new Color(colorR, colorG, colorB, colorA));
                    }
                }
                else
                {
                    int validLayer = Mathf.Min(activeChannelInfos.Count, 4);
                    if (validLayer == 0)
                        continue;

                    Color controlIndex = Color.clear;
                    for (int i = 0; i < validLayer; i++)
                    {
                        controlMapWeights[x, y, i] = activeChannelInfos[i].weight;
                        controlIndex[i] = activeChannelInfos[i].channelId / 15f;
                    }
                    controlMap.SetPixel(x, y, controlIndex);
                }
            }
        }

        controlMap.Apply();
        AssetDatabase.DeleteAsset("Assets/Scenes/atlasControlMap.asset");
        AssetDatabase.CreateAsset(controlMap, "Assets/Scenes/atlasControlMap.asset");
        return controlMap;
    }

    struct DecodedControlInfo
    {
        public int index1;
        public int index2;
        public int index3;
        public int index4;
        public float weight1;
        public float weight2;
        public float weight3;
        public float weight4;

        public DecodedControlInfo(int index1, int index2, int index3, int index4, float weight1, float weight2, float weight3, float weight4)
        {
            this.index1 = index1;
            this.index2 = index2;
            this.index3 = index3;
            this.index4 = index4;
            this.weight1 = weight1;
            this.weight2 = weight2;
            this.weight3 = weight3;
            this.weight4 = weight4;
        }

        public float GetWeightOf(int targetIndex)
        {
            if (targetIndex == index1)
                return weight1;

            if (targetIndex == index2)
                return weight2;

            if (targetIndex == index3)
                return weight3;

            if (targetIndex == index4)
                return weight4;

            return 0f;
        }
    }

    private DecodedControlInfo DecodeControlColor(Texture2D controlMap, int x, int y, float[,,] controlMapWeights, bool decodeWeightFromControlMap)
    {
        Color encodedControl = controlMap.GetPixel(x, y);
        int index1 = Mathf.RoundToInt(encodedControl.r * 15f);
        int index2 = Mathf.RoundToInt(encodedControl.g * 15f);
        int index3 = 0;
        int index4 = 0;
        float weight1 = 0;
        float weight2 = 0;
        float weight3 = 0;
        float weight4 = 0;
        if (!decodeWeightFromControlMap)
        {
            index3 = Mathf.RoundToInt(encodedControl.b * 15f);
            weight1 = controlMapWeights[x, y, 0];
            weight2 = controlMapWeights[x, y, 1];
            weight3 = controlMapWeights[x, y, 2];
            weight4 = controlMapWeights[x, y, 3];
        }
        else
        {
            weight1 = (Mathf.RoundToInt(encodedControl.b * 15f) + (Mathf.RoundToInt(encodedControl.a * 15f) << 4)) / 255f;
            weight2 = 1 - weight1;
        }

        return new DecodedControlInfo(index1, index2, index3, index4, weight1, weight2, weight3, weight4);
    }

    private Texture2D EncodeWeightMap(Texture2D controlMap, float[,,] controlMapWeights, bool decodeWeightFromControlMap)
    {
        Texture2D weightMap = new Texture2D(controlSize * 4, controlSize * 4, TextureFormat.RGBA32, false, true);
        weightMap.filterMode = FilterMode.Point;
        weightMap.anisoLevel = 0;
        weightMap.wrapMode = TextureWrapMode.Clamp;
        Texture2D[] alphaMapTextures = terrainTarget.terrainData.alphamapTextures;
        Color[] colors = new Color[alphaMapTextures.Length];

        for (int x = 0; x < controlSize; x++)
        {
            for (int y = 0; y < controlSize; y++)
            {
                int leftX = Mathf.Max(0, x - 1);
                int rightX = Mathf.Min(controlSize - 1, x + 1);
                int topY = Mathf.Min(controlSize - 1, y + 1);
                int bottomY = Mathf.Max(0, y - 1);

                DecodedControlInfo centerInfo = DecodeControlColor(controlMap, x, y, controlMapWeights, false);
                DecodedControlInfo leftInfo = DecodeControlColor(controlMap, leftX, y, controlMapWeights, false);
                DecodedControlInfo topLeftInfo = DecodeControlColor(controlMap, leftX, topY, controlMapWeights, false);
                DecodedControlInfo topInfo = DecodeControlColor(controlMap, x, topY, controlMapWeights, false);
                DecodedControlInfo topRightInfo = DecodeControlColor(controlMap, rightX, topY, controlMapWeights, false);
                DecodedControlInfo rightInfo = DecodeControlColor(controlMap, rightX, y, controlMapWeights, false);
                DecodedControlInfo bottomRightInfo = DecodeControlColor(controlMap, rightX, bottomY, controlMapWeights, false);
                DecodedControlInfo bottomInfo = DecodeControlColor(controlMap, x, bottomY, controlMapWeights, false);
                DecodedControlInfo bottomLeftInfo = DecodeControlColor(controlMap, leftX, bottomY, controlMapWeights, false);

                DecodedControlInfo[,] gridInfos = new DecodedControlInfo[3, 3];
                gridInfos[0, 0] = bottomLeftInfo;
                gridInfos[1, 0] = bottomInfo;
                gridInfos[2, 0] = bottomRightInfo;
                gridInfos[0, 1] = leftInfo;
                gridInfos[1, 1] = centerInfo;
                gridInfos[2, 1] = rightInfo;
                gridInfos[0, 2] = topLeftInfo;
                gridInfos[1, 2] = topLeftInfo;
                gridInfos[2, 2] = topRightInfo;


                for (int localX = 0; localX < 4; localX++)
                {
                    for (int localY = 0; localY < 4; localY++)
                    {
                        int globalX = x * 4 + localX;
                        int globalY = y * 4 + localY;

                        DecodedControlInfo lerpInfo;
                        if (localX < 2)
                        {
                            if (localY < 2)
                            {
                                lerpInfo = BilinearLerp(gridInfos, 0, 0, localX - 2, localY - 2);
                            }
                            else
                            {
                                lerpInfo = BilinearLerp(gridInfos, 0, 1, localX - 2, localY - 1);
                            }
                        }
                        else
                        {
                            if (localY < 2)
                            {
                                lerpInfo = BilinearLerp(gridInfos, 1, 0, localX - 1, localY - 2);
                            }
                            else
                            {
                                lerpInfo = BilinearLerp(gridInfos, 1, 1, localX - 1, localY - 1);
                            }
                        }

                        weightMap.SetPixel(globalX, globalY, new Color(lerpInfo.weight1, lerpInfo.weight2, lerpInfo.weight3, lerpInfo.weight4));
                    }
                }
            }
        }

        weightMap.Apply();
        AssetDatabase.DeleteAsset("Assets/Scenes/atlasWeightMap.asset");
        AssetDatabase.CreateAsset(weightMap, "Assets/Scenes/atlasWeightMap.asset");
        return weightMap;
    }

    private DecodedControlInfo BilinearLerp(DecodedControlInfo[,] gridInfos, int leftIndex, int bottomIndex, int offsetFromCenterX, int offsetFromCenterY)
    {
        DecodedControlInfo bottomLeft = gridInfos[leftIndex, bottomIndex];
        DecodedControlInfo topLeft = gridInfos[leftIndex, bottomIndex + 1];
        DecodedControlInfo topRight = gridInfos[leftIndex + 1, bottomIndex + 1];
        DecodedControlInfo bottomRight = gridInfos[leftIndex + 1, bottomIndex];

        DecodedControlInfo decodedControlInfo = new DecodedControlInfo();
        DecodedControlInfo targetInfo = topRight;
        if (offsetFromCenterX < 0)
        {
            if (offsetFromCenterY < 0)
            {
               targetInfo = topRight;
              
            }
            else
            {
                targetInfo = bottomRight;
            }
        }
        else
        {
            if (offsetFromCenterY < 0)
            {
                targetInfo = topLeft;
            }
            else
            {
                targetInfo = bottomLeft;
            }
        }

        decodedControlInfo = ResolveLerpInfo(offsetFromCenterX, offsetFromCenterY, bottomLeft, topLeft, topRight, bottomRight, decodedControlInfo, targetInfo);

        float total = decodedControlInfo.weight1 + decodedControlInfo.weight2 + decodedControlInfo.weight3 + decodedControlInfo.weight4;
        decodedControlInfo.weight4 /= Mathf.Max(total, Mathf.Epsilon);
        decodedControlInfo.weight3 /= Mathf.Max(total, Mathf.Epsilon);
        decodedControlInfo.weight2 /= Mathf.Max(total, Mathf.Epsilon);
        decodedControlInfo.weight1 = 1 - decodedControlInfo.weight2 - decodedControlInfo.weight3 - decodedControlInfo.weight4;

        return decodedControlInfo;
    }

    private DecodedControlInfo ResolveLerpInfo(int offsetFromCenterX, int offsetFromCenterY, DecodedControlInfo bottomLeft, DecodedControlInfo topLeft, DecodedControlInfo topRight, DecodedControlInfo bottomRight, DecodedControlInfo decodedControlInfo, DecodedControlInfo targetInfo)
    {
        decodedControlInfo.index1 = targetInfo.index1;
        decodedControlInfo.index2 = targetInfo.index2;
        decodedControlInfo.index3 = targetInfo.index3;
        decodedControlInfo.index4 = targetInfo.index4;

        decodedControlInfo.weight1 = GetLerpWeight(bottomLeft, topLeft, topRight, bottomRight, offsetFromCenterX, offsetFromCenterY, decodedControlInfo.index1);
        decodedControlInfo.weight2 = GetLerpWeight(bottomLeft, topLeft, topRight, bottomRight, offsetFromCenterX, offsetFromCenterY, decodedControlInfo.index2);
        decodedControlInfo.weight3 = GetLerpWeight(bottomLeft, topLeft, topRight, bottomRight, offsetFromCenterX, offsetFromCenterY, decodedControlInfo.index3);
        decodedControlInfo.weight4 = GetLerpWeight(bottomLeft, topLeft, topRight, bottomRight, offsetFromCenterX, offsetFromCenterY, decodedControlInfo.index4);

        if (InThreshold(targetInfo.weight2))
            decodedControlInfo.weight2 = 0;

        if (InThreshold(targetInfo.weight3))
            decodedControlInfo.weight3 = 0;

        if (InThreshold(targetInfo.weight4))
            decodedControlInfo.weight4 = 0;
        return decodedControlInfo;
    }

    private bool InThreshold(float value)
    {
        return value <= 0.0f;
    }

    private float ReduceWeight(float originWeight)
    {
        return originWeight * 1f;
    }

    private float GetLerpWeight(DecodedControlInfo bottomLeft, DecodedControlInfo topLeft, DecodedControlInfo topRight, DecodedControlInfo bottomRight, int offsetFromCenterX, int offsetFromCenterY, int index)
    {
        var bottomLeftWeight = bottomLeft.GetWeightOf(index);
        var topLeftWeight = topLeft.GetWeightOf(index);
        var topRightWeight = topRight.GetWeightOf(index);
        var bottomRighttWeight = bottomRight.GetWeightOf(index);
        float lerpWeight = 0f;


        var lerpHorizontal1 = Mathf.Clamp01(Mathf.Lerp(bottomLeftWeight, bottomRighttWeight, GetLerpFactor(offsetFromCenterX)));
        var lerpHorizontal2 = Mathf.Clamp01(Mathf.Lerp(topLeftWeight, topRightWeight, GetLerpFactor(offsetFromCenterX)));
        lerpWeight = Mathf.Lerp(lerpHorizontal1, lerpHorizontal2, GetLerpFactor(offsetFromCenterY));
        if (offsetFromCenterX == -1)
        {
            if (offsetFromCenterY == -2)
            {
                if (InThreshold(bottomRighttWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if(offsetFromCenterY == 2)
            {
                if (InThreshold(topRightWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
        }
        else if (offsetFromCenterX == 1)
        {
            if (offsetFromCenterY == -2)
            {
                if (InThreshold(bottomLeftWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if(offsetFromCenterY == 2)
            {
                if (InThreshold(topLeftWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
        }
        else  if(offsetFromCenterX == -2)
        {
            if(offsetFromCenterY == -2)
            {
                if (InThreshold(topLeftWeight)&& InThreshold(bottomRighttWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if(offsetFromCenterY == -1)
            {
                if (InThreshold(topLeftWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if(offsetFromCenterY == 1)
            {
                if (InThreshold(bottomLeftWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if(offsetFromCenterY == 2)
            {
                if (InThreshold(bottomLeftWeight) && InThreshold(topRightWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
        }
        else if(offsetFromCenterX == 2)
        {
            if (offsetFromCenterY == -2)
            {
                if (InThreshold(topRightWeight) && InThreshold(bottomLeftWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if (offsetFromCenterY == -1)
            {
                if (InThreshold(topRightWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if (offsetFromCenterY == 1)
            {
                if (InThreshold(bottomRighttWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
            else if (offsetFromCenterY == 2)
            {
                if (InThreshold(topLeftWeight) && InThreshold(bottomRighttWeight))
                    lerpWeight = ReduceWeight(lerpWeight);
            }
        }

        return lerpWeight;
    }

    private float GetLerpFactor(int offsetFromCenter)
    {
        if (offsetFromCenter == -1)
            return 5f / 6f;
        if (offsetFromCenter == -2 || offsetFromCenter == 2)
            return 0.5f;

        return 1f / 6f;
    }

    private void ModifySplatmapWithSave(TerrainData terrainData, TerrainLayer[] terrainLayers, int maxValidChannelNum)
    {
        SaveSplatmap(terrainData);
        errorShower.showGizmos = false;
        ModifySplatmap(terrainData, terrainLayers, maxValidChannelNum);
    }

    private void SaveSplatmap(TerrainData terrainData)
    {
        float[,,] savedAlphaMaps = terrainData.GetAlphamaps(0, 0, terrainData.alphamapWidth, terrainData.alphamapHeight);
        originAlphaMaps.Push(savedAlphaMaps);
    }

    private void RevertSplatMap(TerrainData terrainData)
    {
        if (originAlphaMaps.Count > 0)
        {
            terrainData.SetAlphamaps(0, 0, originAlphaMaps.Pop());
        }
    }

    public static Texture2D[] CretaeTexture2Ds(TerrainLayer[] terrainLayers, bool isDiffuse, int customWidth = 0, int customHeight = 0)
    {
        Texture2D[] terrainLayerTextures = new Texture2D[terrainLayers.Length];
        Texture2D texture;
        for (int i = 0; i < terrainLayers.Length; i++)
        {
            texture = isDiffuse ? terrainLayers[i].diffuseTexture : terrainLayers[i].normalMapTexture;

            customWidth = customWidth == 0 ? texture.width : customWidth;
            customHeight = customHeight == 0 ? texture.height : customHeight;

            RenderTexture temp = RenderTexture.GetTemporary(customWidth, customHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            Graphics.Blit(texture, temp);

            terrainLayerTextures[i] = isDiffuse ? new Texture2D(customWidth, customHeight, TextureFormat.ARGB32, true, true) : new Texture2D(customWidth, customHeight, TextureFormat.RGB24, true, true);
            terrainLayerTextures[i].ReadPixels(new Rect(0, 0, customWidth, customHeight), 0, 0);
            terrainLayerTextures[i].Apply();
            RenderTexture.ReleaseTemporary(temp);
        }
        return terrainLayerTextures;
    }

    private void ModifySplatmap(TerrainData terrainData, TerrainLayer[] terrainLayers, int maxValidChannelNum)
    {
        RefreshMaxDepth();
        SimplifySplatmapQuadTree.splatmapSimplifyMaxValidLayer = maxValidChannelNum;
        SimplifySplatmapQuadTree root = new SimplifySplatmapQuadTree(terrainTarget, 0, true, new RectInt(0, 0, terrainData.alphamapWidth, terrainData.alphamapHeight));
        root.BFIterate((node) =>
        {
            node.AutoSplit();
        });

        float[,,] mixedMaps = new float[terrainData.alphamapWidth, terrainData.alphamapHeight, terrainLayers.Length];
        Color[,] colors = new Color[terrainData.alphamapWidth, terrainData.alphamapHeight];

        Texture2D[] terrainLayerTextures = CretaeTexture2Ds(terrainLayers, true);

        root.BFIterate((node) =>
        {
            SimplifySplatmapQuadTree toBeSplitNode = (SimplifySplatmapQuadTree)node;
            toBeSplitNode.RefreshColors(terrainLayerTextures, colors);
        });

        root.BFIterate((node) =>
        {
            SimplifySplatmapQuadTree toBeSplitNode = (SimplifySplatmapQuadTree)node;
            toBeSplitNode.MixLayers(terrainLayerTextures, mixedMaps, colors, false);
        });
        terrainData.SetAlphamaps(0, 0, mixedMaps);
    }

    private void SmoothScene()
    {
        float[,,] originMaps = terrainTarget.terrainData.GetAlphamaps(0, 0, terrainTarget.terrainData.alphamapWidth, terrainTarget.terrainData.alphamapHeight);

        Dictionary<int, List<SplatmapLayerInfo>> splatMaps = new Dictionary<int, List<SplatmapLayerInfo>>();

        for (int x = 0; x < splitCount; x++)
        {
            for (int y = 0; y < splitCount; y++)
            {
            }
        }
    }
}
