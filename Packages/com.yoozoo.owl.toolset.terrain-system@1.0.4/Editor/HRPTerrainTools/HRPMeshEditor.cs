using MightyTerrainMesh;
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

[System.Serializable]
public class HRPLODSetting : MeshLODCreate
{
    public float screenRelativeTransitionHeight = 0.25f;

    public virtual bool OnGUIDraw(int idx, bool showLODIndex, bool showDivisionInfo, bool showScreenRelativeTransitionHeight)
    {
        if(showLODIndex)
            EditorGUILayout.LabelField("LOD " + idx);
        EditorGUI.indentLevel++;

        if(showScreenRelativeTransitionHeight)
            screenRelativeTransitionHeight = EditorGUILayout.Slider("大于该值显示该LOD", screenRelativeTransitionHeight, 0f, 1f);

        EditorGUI.BeginChangeCheck();
        if (!showDivisionInfo)
        {
            EditorGUI.indentLevel--;
            return false;
        }

        int curRate = Mathf.FloorToInt(Mathf.Pow(2, Subdivision));
        int sampleRate = EditorGUILayout.DelayedIntField("每块采样数量(NxN)", curRate);
        if (curRate != sampleRate)
        {
            curRate = Mathf.NextPowerOfTwo(sampleRate);
            Subdivision = Mathf.FloorToInt(Mathf.Log(curRate, 2));
        }
        SlopeAngleError = EditorGUILayout.DelayedFloatField("减面角度误差", SlopeAngleError);
        SlopeAngleError = Mathf.Max(0.01f, SlopeAngleError);
        EditorGUI.indentLevel--;

        return EditorGUI.EndChangeCheck();
    }
}

internal class HRPMeshTextureBaker
{
    public Vector2 uvMin { get; private set; }
    public Vector2 uvMax { get; private set; }
    public Material layer0 { get; private set; }
    public Material layer1 { get; private set; }
    public Texture2D BakeResult { get; set; }
    public int Size { get { return texSize; } }
    private int texSize = 32;
    public HRPMeshTextureBaker(int size, Vector2 min, Vector2 max, Material m0, Material m1)
    {
        texSize = size;
        uvMin = min;
        uvMax = max;
        layer0 = m0;
        layer1 = m1;
        BakeResult = new Texture2D(texSize, texSize, TextureFormat.ARGB32, false);
    }
}
internal class MeshItem
{
    public int lod { get; private set; }
    public int meshId { get; private set; }
    public Mesh mesh { get; private set; }
    public Vector4 scaleOffset { get; private set; }
    public MeshItem(int i, int mid, Mesh m, Vector2 uvMin, Vector2 uvMax)
    {
        lod = i;
        meshId = mid;
        mesh = m;
        var v = new Vector4(1, 1, 0, 0);
        v.x = uvMax.x - uvMin.x;
        v.y = uvMax.y - uvMin.y;
        v.z = uvMin.x;
        v.w = uvMin.y;
        scaleOffset = v;
    }

    public Vector2Int GetIndex(int width, int height)
    {
        int x = meshId / height;
        int y = meshId % height;
        return new Vector2Int(x, y);
    }
}

public class HRPMeshEditor : EditorWindow
{
    enum SplitType
    {
        NormalLOD,
        HLOD
    }

    enum MatType
    {
        Splatmap,
        Basemap
    }


    [MenuItem("HRPTerrain/MeshCreator", priority = 1)]
    private static void ShowWindow()
    {
        EditorWindow.GetWindow<HRPMeshEditor>();
    }

    public static HRPMeshEditor instance;

    private SerializedObject serializedObject;

    [SerializeField]
    private SplitType splitType;

    [SerializeField]
    private Terrain terrainTarget;
    [SerializeField]
    private List<Terrain> splitedTerrains = new List<Terrain>();
    private Terrain[,] terrainGrids;
    private bool terrainGridsFull;

    [SerializeField]
    private bool genUV2 = true;
    [SerializeField]
    private MatType matType = MatType.Basemap;
    [SerializeField]
    private int bakeTextureSize = 1024;

    [SerializeField]
    private ConversionShaderSuite conversionShaderSuite;

    private List<HRPLODSetting> LODSettings = new List<HRPLODSetting>();
    private PreviewMeshGizmos previewGo;

    private void OnEnable()
    {
        instance = this;
        serializedObject = new SerializedObject(this);
        if (terrainTarget == null)
        {
            Terrain[] terrains = FindObjectsOfType<Terrain>(true);
            if (terrains != null && terrains.Length == 1)
            {
                terrainTarget = terrains[0];
            }
        }
        UpdateTerrainGrids();
        SceneView.duringSceneGui += UpdatePreviewMesh;
    }

    private void OnDisable()
    {
        SceneView.duringSceneGui -= UpdatePreviewMesh;
        GameObject.DestroyImmediate(previewGo?.gameObject);
        previewGo = null;
    }

    private void UpdatePreviewMesh(SceneView sceneView)
    {

    }

    Vector2 scrollPos;
    public static int DrawHRPLODSettings(List<HRPLODSetting> settings, bool showLODIndex, bool showCount, bool showDivistionInfo, bool showScreenRelativeTransitionHeight)
    {
        int changedIndex = -1;
        for (int i = 0; i < settings.Count; ++i)
        {
            if (settings[i].OnGUIDraw(i, showLODIndex, showDivistionInfo, showScreenRelativeTransitionHeight))
            {
                if(changedIndex == -1)
                    changedIndex = i;
            }
        }

        for (int i = 1; i < settings.Count; i++)
        {
            settings[i].screenRelativeTransitionHeight = Mathf.Clamp(settings[i].screenRelativeTransitionHeight, (settings.Count - i - 1) * 0.01f, settings[i - 1].screenRelativeTransitionHeight - 0.01f);
        }
        return changedIndex;
    }

    private int sliceCount = 4;
    private Material previewMat;
    private int previewIndex = 0;
    private Vector2 lodMeshScrollPos;
    private bool splitMeshButtonClicked = false;

    private void OnGUI()
    {
        serializedObject.Update();

        using (new EditorGUILayout.HorizontalScope())
        {
            terrainTarget = EditorGUILayout.ObjectField("Convert Target", terrainTarget, typeof(Terrain), true) as Terrain;
            if(terrainTarget != null && terrainTarget.materialTemplate.shader.name == "Universal Render Pipeline/Terrain/Lit"){
                if(GUILayout.Button("检测到shader为URP TerrainLit，点击替换为Ultra TerrainLit"))
                    terrainTarget.materialTemplate.shader = Shader.Find("TerrainSystem/HRP/Terrain/UltraLit");
            }
        }

        conversionShaderSuite = EditorGUILayout.ObjectField("Conversion Shader Suite", conversionShaderSuite, typeof(ConversionShaderSuite), false) as ConversionShaderSuite;

        if (terrainTarget == null || conversionShaderSuite == null)
        {
            EditorGUILayout.LabelField("请先添加用于转换的地形");
            return;
        }

        if (previewMat == null)
        {
            previewMat = new Material(Shader.Find("HRP/Lit/Lambert"));
        }
        if (previewGo == null)
        {
            previewGo = FindObjectOfType<PreviewMeshGizmos>();
            if (previewGo == null)
            {
                previewGo = new GameObject("PreviewMesh").AddComponent<PreviewMeshGizmos>();
                previewGo.gameObject.hideFlags = HideFlags.DontSave;
                previewGo.gameObject.AddComponent<MeshFilter>();
                previewGo.gameObject.AddComponent<MeshRenderer>();
            }
        }

        //using (var checker = new EditorGUI.ChangeCheckScope())
        //{
        //    EditorGUILayout.PropertyField(serializedObject.FindProperty("splitedTerrains"), true);
        //    if (checker.changed)
        //    {
        //        serializedObject.ApplyModifiedProperties();
        //        UpdateTerrainGrids();
        //    }
        //}

        if (terrainGrids[0, 0] == null)
        {
            UpdateTerrainGrids();
        }

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("烘焙分块信息");
        bool hasSplitedTerrian = splitedTerrains.Count > 0;
        if (hasSplitedTerrian)
        {
            if (!terrainGridsFull)
            {
                EditorGUILayout.LabelField("Split Terrain无法组成Target Terrain");
                return;
            }
        }

        using (new EditorGUILayout.HorizontalScope())
        {
            EditorGUI.BeginChangeCheck();
            matType = (MatType)EditorGUILayout.EnumPopup("材质类型", matType);
            if (matType == MatType.Basemap)
            {
                bakeTextureSize = EditorGUILayout.IntField("Bake Texture Size", bakeTextureSize);
                bakeTextureSize = Mathf.NextPowerOfTwo(bakeTextureSize);
            }
            
            if(splitType == SplitType.HLOD)
            {
                previewIndex = 0;
            }

            genUV2 = EditorGUILayout.Toggle("Generate UV2", genUV2);
            if (EditorGUI.EndChangeCheck() && splitType == SplitType.NormalLOD && matType == MatType.Splatmap)
            {
                //splitType = SplitType.HLOD;
            }
        }

        splitType = (SplitType)EditorGUILayout.EnumPopup(new GUIContent("LOD模式"), splitType, (value)=>
        {
            //SplitType realVal = (SplitType)value;
            //if (matType == MatType.Splatmap)
            //    return realVal != SplitType.NormalLOD;
            return true;
        }, false);

        using (new EditorGUILayout.HorizontalScope())
        {
            int minSliceCount = hasSplitedTerrian ? terrainGrids.GetLength(0) : 1;
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Label("分块数量(NxN)，必须是2的幂");
                EditorGUI.BeginChangeCheck();
                sliceCount = EditorGUILayout.DelayedIntField(sliceCount);
                sliceCount = Mathf.Max(minSliceCount, sliceCount);
                sliceCount = sliceCount == 1 ? 1 : Mathf.ClosestPowerOfTwo(sliceCount);
                if (EditorGUI.EndChangeCheck())
                    PreviewMesh(previewIndex);

                int count = LODSettings.Count;
                if (splitType == SplitType.NormalLOD)
                {
                    count = EditorGUILayout.DelayedIntField("LOD数量", count);
                }
                else
                {
                    count = 1;
                }

                count = Mathf.Clamp(count, 1, 5);
                if (count != LODSettings.Count)
                {
                    if (count < LODSettings.Count)
                    {
                        int diff = LODSettings.Count - count;
                        LODSettings.RemoveRange(count, diff);
                    }
                    else
                    {
                        int diff = count - LODSettings.Count;
                        for (int i = 0; i < diff; i++)
                        {
                            LODSettings.Add(new HRPLODSetting());
                        }
                    }
                }

                //EditorGUILayout.LabelField("LOD信息（Sample必须是2的幂，Slope Angle Error值越大减面越多）");
            }


            if (splitType == SplitType.HLOD)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    reducedFactor = EditorGUILayout.Slider("下一级减面为原来的", reducedFactor, 0.1f, 0.9f);
                    errorBound = EditorGUILayout.Slider("允许误差", errorBound, 0.02f, 0.1f);
                }
            }
        }

        using (var scrollScope = new EditorGUILayout.ScrollViewScope(lodMeshScrollPos))
        {
            int changedIndex = DrawHRPLODSettings(LODSettings, splitType == SplitType.NormalLOD, true, true, splitType == SplitType.NormalLOD);
            if (changedIndex >= 0)
            {
                previewIndex = changedIndex;
                PreviewMesh(previewIndex);
            }
            lodMeshScrollPos = scrollScope.scrollPosition;
        }

        if (verticesCount > 0)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("预览信息");
            EditorGUILayout.LabelField($"LOD{previewIndex}, 顶点数:{ verticesCount}, 三角面数:{ triangleCount}");
        }

        if(matType == MatType.Splatmap)
        {
            ShowAtlasInfo();
        }

        if (GUILayout.Button("Generate"))
        {
            if (LODSettings.Count == 0)
                return;

            splitMeshButtonClicked = true;
            GUI.FocusControl(null);
            return;
        }
 
        if(splitMeshButtonClicked && Event.current.type == EventType.Repaint){
            splitMeshButtonClicked = false;
            SplitMeshAndCombineMaterial();
        }

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Basemap资源流式记载配置信息");
        prefabRoot = EditorGUILayout.ObjectField("Meshed Terrain", prefabRoot, typeof(GameObject), true) as GameObject;
        resouceLoader = EditorGUILayout.ObjectField("Resource Loader", resouceLoader, typeof(ResourceLoader), false) as ResourceLoader;
        baseMat = EditorGUILayout.ObjectField("Base Material", baseMat, typeof(Material), false) as Material;
        if (GUILayout.Button("创建配置文件"))
        {
            if (resouceLoader == null)
            {
                EditorUtility.DisplayDialog("提示", "请先设置Asset Path Provider", "好的");
                return;
            }

            if (prefabRoot == null)
            {
                EditorUtility.DisplayDialog("提示", "请先设置网格化后的地形GameObject", "好的");
                return;
            }

            if(terrainTarget == null)
            {
                EditorUtility.DisplayDialog("提示", "请下设置原始地形", "好的");
                return;
            }

            if (baseMat == null)
            {
                EditorUtility.DisplayDialog("提示", "请下设置BaseMaterial", "好的");
                return;
            }

            if(prefabRoot.GetComponent<TerrainLODManager>() == null)
            {
                prefabRoot.AddComponent<TerrainLODManager>();
            }
            var lodManager = prefabRoot.GetComponent<TerrainLODManager>();
            int segmentCnt = Mathf.RoundToInt(Mathf.Sqrt(prefabRoot.transform.childCount));
            lodManager.InitDataInEditor(terrainTarget.terrainData, segmentCnt, segmentCnt, prefabRoot.transform, baseMat, resouceLoader);
            EditorUtility.SetDirty(lodManager);
        }
    }

    private void SplitMeshAndCombineMaterial()
    {
        string lodFolder = GetLodFolder();
        if (!AssetDatabase.IsValidFolder(lodFolder))
            AssetDatabase.CreateFolder("Assets", lodFolder.Replace("Assets/",""));

        if (splitType == SplitType.NormalLOD)
        {
            MTTerrainScanner customDetail = null;
            var tessellationJob = TessllateMesh(sliceCount, LODSettings.ConvertAll<MeshLODCreate>((data) => { return (MeshLODCreate)data; }), ref customDetail);
            List<MeshItem> meshItems = CreateMeshItem(lodFolder, tessellationJob, (data, lod)=>
            {
                return string.Format("{0}/{1}.mesh", lodFolder + "/Meshes", data.meshId + "_LOD" + lod);
            });

            //bake mesh prefab
            if (matType == MatType.Basemap)
            {
                var texture = new Texture2D(bakeTextureSize, bakeTextureSize, TextureFormat.RGBA32, true, true);
                texture.wrapMode = TextureWrapMode.Clamp;
                texture.anisoLevel = 0;
                RenderTexture renderTexture = RenderTexture.GetTemporary(bakeTextureSize, bakeTextureSize, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
                //reload Mats
                Material[] arrAlbetoMats = new Material[2];
                Material[] arrNormalMats = new Material[2];
                //var holeMat = new Material(Shader.Find("Unlit/NewUnlitShader"));
                MTMatUtils.GetBakeMaterials(terrainTarget, arrAlbetoMats, arrNormalMats, conversionShaderSuite);
                prefabRoot = ApplyNormalLODBasemap(meshItems, terrainTarget, lodFolder, LODSettings.Count, 0, texture, renderTexture,arrAlbetoMats, arrNormalMats);

                //额外烘焙一套全局basemap
                string albeto = string.Format("{0}/Textures/albeto_basemap.png", lodFolder);
                string normal = string.Format("{0}/Textures/normal_basemap.png", lodFolder);
                string hole = string.Format("{0}/Textures/hole_basemap.png", lodFolder);

                Texture2D normalTexture = CreateNormalTexture(texture);
                SaveBakedTexture(albeto, true, ref renderTexture, texture, arrAlbetoMats, new Vector4(1, 1, 0, 0));
                SaveBakedTexture(normal, false, ref renderTexture, normalTexture, arrNormalMats, new Vector4(1, 1, 0, 0));

                Graphics.Blit(terrainTarget.terrainData.holesTexture, renderTexture);
                texture.ReadPixels(new Rect(Vector2.zero, new Vector2(texture.width, texture.height)), 0, 0);
                texture.Apply();
                byte[] png = texture.EncodeToPNG();
                File.WriteAllBytes(hole, png);
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
                string matPath = string.Format("{0}/Materials/mat_basemap.mat", lodFolder);
                Texture2D albetoTex = AssetDatabase.LoadAssetAtPath<Texture2D>(albeto);
                Texture2D normalTex = AssetDatabase.LoadAssetAtPath<Texture2D>(normal);
                Texture2D holeTex = AssetDatabase.LoadAssetAtPath<Texture2D>(hole);
                Material basemapMat = conversionShaderSuite.SaveBakedMaterial(matPath, albetoTex, normalTex, null, new Vector2(1, 1), new Vector2(0, 0));
                baseMat = basemapMat;
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
            }
            else
            {
                prefabRoot = ApplyNormalLODSplatmap(lodFolder, meshItems, true);
            }

            EditorUtility.ClearProgressBar();
            AssetDatabase.Refresh();
        }
        else if (splitType == SplitType.HLOD)
        {
            prefabRoot = new GameObject(terrainTarget.name + "_HLOD");
            prefabRoot.transform.position = terrainTarget.transform.position;
            var hlodManager = prefabRoot.AddComponent<TerrainHLODManager>();

            if (matType == MatType.Basemap)
            {
                var texture = new Texture2D(bakeTextureSize, bakeTextureSize, TextureFormat.RGBA32, true);
                RenderTexture renderTexture = RenderTexture.GetTemporary(bakeTextureSize, bakeTextureSize);
                //reload Mats
                Material[] arrAlbetoMats = new Material[2];
                Material[] arrNormalMats = new Material[2];
                //var holeMat = new Material(Shader.Find("Unlit/NewUnlitShader"));
                MTMatUtils.GetBakeMaterials(terrainTarget, arrAlbetoMats, arrNormalMats, conversionShaderSuite);

                CreateHLODMeshAndCombineMaterial(lodFolder, hlodManager, 
                (meshItems, depth) =>
                {
                    CreateBasemapTextureAndMaterial(meshItems, lodFolder, 1, depth, texture, renderTexture, arrAlbetoMats, arrNormalMats);
                }, 
                (meshItem, meshGo, depth) =>
                {
                    var info = FetchBasemapAssetPath(lodFolder, meshItem, depth);
                    Renderer renderer = meshGo.GetComponent<Renderer>();
                    renderer.sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>(info.matPath);
                });
            }
            else
            {
                string mathPath = string.Format("{0}/{1}.mat", lodFolder, "splatmapAtlas");
                Material mat = AssetDatabase.LoadAssetAtPath<Material>(mathPath);
                if (mat != null)
                    AssetDatabase.DeleteAsset(mathPath);
                mat = conversionShaderSuite.GetSplatmapAtlasMat(controlmap, diffuseAtlas, normalAtlas);
                AssetDatabase.CreateAsset(mat, mathPath);

                CreateHLODMeshAndCombineMaterial(lodFolder, hlodManager, null, (meshItem, meshGo, depth)=>
                {
                    Renderer renderer = meshGo.GetComponent<Renderer>();
                    renderer.sharedMaterial = mat;
                });

                hlodManager.InitSplatmapInfo(terrainTarget.terrainData, mat, diffuseAtlas);
            }
            PrefabUtility.SaveAsPrefabAssetAndConnect(prefabRoot, lodFolder + "/" + terrainTarget.name + "_HLOD.prefab", InteractionMode.AutomatedAction);
            EditorUtility.ClearProgressBar();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }

        if(prefabRoot != null)
        {
            MeshFilter[] results = prefabRoot.GetComponentsInChildren<MeshFilter>(true);
            foreach (var result in results)
            {
                if (result.GetComponent<MeshCollider>() == null)
                {
                    if (result.gameObject.name.EndsWith("LOD0"))
                    {
                        var collider = result.gameObject.AddComponent<MeshCollider>();
                        collider.sharedMesh = result.sharedMesh;
                    }
                }
            }

            MeshRenderer[] resultRenderers = prefabRoot.GetComponentsInChildren<MeshRenderer>(true);
            foreach (var result in resultRenderers)
            {
                result.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            }
            PrefabUtility.ApplyPrefabInstance(prefabRoot, InteractionMode.AutomatedAction);
        }
    }


    [SerializeField]
    private GameObject prefabRoot;
    [SerializeField]
    private Material baseMat;
    [SerializeField]
    private ResourceLoader resouceLoader;
    private void CreateLODInfoDataset()
    {

    }

private List<MeshItem> CreateMeshItem(string lodFolder, TessellationJob tessellationJob, Func<MTMeshData, int, string> getTransferredMeshFolder)
    {
        if (getTransferredMeshFolder == null)
            return null;

        //save meshes
        List<MeshItem> bakers = new List<MeshItem>();
        for (int i = 0; i < tessellationJob.mesh.Length; ++i)
        {
            EditorUtility.DisplayProgressBar("saving data", "processing", (float)i / tessellationJob.mesh.Length);
            MTMeshData data = tessellationJob.mesh[i];
            if (!AssetDatabase.IsValidFolder(lodFolder))
            {
                AssetDatabase.CreateFolder(Path.GetDirectoryName(lodFolder), Path.GetFileNameWithoutExtension(lodFolder));
                AssetDatabase.Refresh();
            }

            for (int lod = 0; lod < data.lods.Length; ++lod)
            {
                if (!AssetDatabase.IsValidFolder(Path.Combine(lodFolder, "Meshes")))
                {
                    AssetDatabase.CreateFolder(lodFolder, "Meshes");
                    AssetDatabase.Refresh();
                }

                string path = getTransferredMeshFolder(data, lod);
                var mesh = SaveMesh(path, data.lods[lod], genUV2);
                var baker = new MeshItem(lod, data.meshId, mesh, data.lods[lod].uvmin, data.lods[lod].uvmax);
                bakers.Add(baker);
            }
        }

        return bakers;
    }

    private string GetLodFolder()
    {
        string lodFolder;
        if(splitType == SplitType.NormalLOD)
        {
            if (matType == MatType.Basemap)
            {
                lodFolder = string.Format("Assets/{0}_LOD_Basemap", terrainTarget.name);
            }
            else
            {
                lodFolder = string.Format("Assets/{0}_LOD_Splatmap", terrainTarget.name);
            }
        }
        else
        {
            if (matType == MatType.Basemap)
            {
                lodFolder = string.Format("Assets/{0}_HLOD_Basemap", terrainTarget.name);
            }
            else
            {
                lodFolder = string.Format("Assets/{0}_HLOD_Splatmap", terrainTarget.name);
            }
        }
        return lodFolder;
    }

    [SerializeField]
    Texture2D controlmap;
    [SerializeField]
    Texture2D diffuseAtlas;
    [SerializeField]
    Texture2D normalAtlas;
    private void ShowAtlasInfo()
    {
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("图集信息");
        using (new EditorGUILayout.HorizontalScope())
        {
            controlmap = EditorGUILayout.ObjectField("ControlMap", controlmap, typeof(Texture2D), false) as Texture2D;
            diffuseAtlas = EditorGUILayout.ObjectField("DiffuseAtlas", diffuseAtlas, typeof(Texture2D), false) as Texture2D;
            normalAtlas = EditorGUILayout.ObjectField("NormalAtlas", normalAtlas, typeof(Texture2D), false) as Texture2D;
        }
    }

    [SerializeField]
    float reducedFactor = 0.75f;
    [SerializeField]
    float errorBound = 0.05f;

    private void CreateHLODMeshAndCombineMaterial(string lodFolder, TerrainHLODManager hlodManager, Action<List<MeshItem>, int> onGetMeshItems,  Action<MeshItem, GameObject, int> onCreateMeshObj)
    {
        Stack<List<Renderer>> renderersStack = new Stack<List<Renderer>>();
        List<List<Renderer>> depthRenderers = new List<List<Renderer>>();
        int curSliceCount = sliceCount;
        MeshLODCreate curLodInput = LODSettings[0];
        MeshLODCreate originLodInput = new MeshLODCreate() { Subdivision = curLodInput.Subdivision, SlopeAngleError = curLodInput.SlopeAngleError };
        int depth = 0;
        int prevTriangleCount = 0;
        MTTerrainScanner customDetail = null;
        while (curSliceCount >= 1)
        {
            TryGetNextLODInput(curSliceCount, depth, prevTriangleCount,ref curLodInput);

            prevTriangleCount = 0;
            var tessellationJob = TessllateMesh(curSliceCount, new List<MeshLODCreate>() { curLodInput }, ref customDetail);
            for (int i = 0; i < tessellationJob.mesh.Length; ++i)
            {
                MTMeshData.LOD data = tessellationJob.mesh[i].lods[0];
                prevTriangleCount += data.faces.Length / 3;
            }

            //save meshes
            List<MeshItem> meshItems = CreateMeshItem(lodFolder, tessellationJob, (data, lod) =>
            {
                return string.Format("{0}/{1}.mesh", lodFolder + "/Meshes/Depth_" + depth, data.meshId + "_LOD" + lod);
            });
            onGetMeshItems?.Invoke(meshItems, depth);
            AssetDatabase.Refresh();

            List<Renderer> renderers = new List<Renderer>();
            int lodCount = LODSettings.Count;
            GameObject prefabRoot = new GameObject(terrainTarget.name);
            prefabRoot.transform.position = terrainTarget.transform.position;
            CreateMeshObjects(meshItems, lodCount, (meshItem, meshGo) =>
            {
                meshGo.transform.SetParent(prefabRoot.transform, false);
                prefabRoot.transform.SetParent(hlodManager.transform);
                renderers.Add(meshGo.GetComponent<MeshRenderer>());
                onCreateMeshObj(meshItem, meshGo, depth);
            });
            renderersStack.Push(renderers);

            //更新Slice信息，通过二分法按比例减面
            curSliceCount = curSliceCount / 2;
            curLodInput.Subdivision = curLodInput.Subdivision + 1;
            depth++;
        }

        curLodInput.Subdivision = originLodInput.Subdivision;
        curLodInput.SlopeAngleError = originLodInput.SlopeAngleError;

        while (renderersStack.Count > 0)
        {
            depthRenderers.Add(renderersStack.Pop());
        }
        hlodManager.InitHLODTree(terrainTarget, depthRenderers);
    }

    private void TryGetNextLODInput(int curSliceCount, int depth, int prevTriangleCount, ref MeshLODCreate curLodInput)
    {
        if (depth > 0)
        {
            //通过二分法按比例减面
            bool increseAngleErr = true;
            float lowerBoundSlopeAngleErr = 0;
            float upperBoundSlopeAngleErr = 0;
            int curTriangleCount = prevTriangleCount;
            int times = 0;
            do
            {
                times++;

                increseAngleErr = (curTriangleCount / (float)prevTriangleCount) > reducedFactor;
                curTriangleCount = 0;

                if (increseAngleErr)
                {
                    lowerBoundSlopeAngleErr = curLodInput.SlopeAngleError;
                    if (upperBoundSlopeAngleErr == 0)
                        curLodInput.SlopeAngleError *= 2;
                    else
                        curLodInput.SlopeAngleError = (upperBoundSlopeAngleErr + curLodInput.SlopeAngleError) * 0.5f;
                }
                else
                {
                    upperBoundSlopeAngleErr = curLodInput.SlopeAngleError;
                    curLodInput.SlopeAngleError = (lowerBoundSlopeAngleErr + curLodInput.SlopeAngleError) * 0.5f;
                }

                MTTerrainScanner temp = null;
                var tessellationJob = TessllateMesh(curSliceCount, new List<MeshLODCreate>() { curLodInput }, ref temp);
                for (int i = 0; i < tessellationJob.mesh.Length; ++i)
                {
                    MTMeshData.LOD data = tessellationJob.mesh[i].lods[0];
                    curTriangleCount += data.faces.Length / 3;
                }
            } while (Mathf.Abs(curTriangleCount / (float)prevTriangleCount - reducedFactor) > errorBound && times < 30);
        }
    }

    List<Vector3> vertices = new List<Vector3>();
    List<Vector3> normals = new List<Vector3>();
    List<Vector2> uv = new List<Vector2>();
    List<int> triangles = new List<int>();
    int verticesCount;
    int triangleCount;
    List<int> triangleCounts = new List<int>();

    private void PreviewMesh(int lod)
    {
        MTTerrainScanner customDetail = null;
        var tessellationJob = TessllateMesh(sliceCount, LODSettings.ConvertAll<MeshLODCreate>((data) => { return (MeshLODCreate)data; }), ref customDetail, false);
        Mesh previewMesh = new Mesh();
        previewMesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

        vertices.Clear();
        normals.Clear();
        uv.Clear();
        triangles.Clear();
        triangleCounts.Clear();

        for (int i = 0; i < tessellationJob.mesh.Length; ++i)
        {
            MTMeshData.LOD data = tessellationJob.mesh[i].lods[lod];
            int offset = vertices.Count;

            vertices.AddRange(data.vertices);
            normals.AddRange(data.normals);
            uv.AddRange(data.uvs);
            foreach (var face in data.faces)
            {
                triangles.Add(face + offset);
            }

            triangleCounts.Add(data.faces.Length / 3);
        }

        previewMesh.vertices = vertices.ToArray();
        previewMesh.normals = normals.ToArray();
        previewMesh.uv = uv.ToArray();
        previewMesh.triangles = triangles.ToArray();
        verticesCount = vertices.Count;
        triangleCount = triangles.Count / 3;

        previewGo.GetComponent<MeshFilter>().sharedMesh = previewMesh;
        previewGo.GetComponent<MeshRenderer>().sharedMaterial = previewMat;
        previewGo.transform.position = terrainTarget.transform.position;

        Vector3 center = new Vector3(terrainTarget.terrainData.size.x * 0.5f, 0f, terrainTarget.terrainData.size.z * 0.5f) + terrainTarget.transform.position;
        previewGo.Init(new Bounds(center, new Vector3(terrainTarget.terrainData.size.x, 0f, terrainTarget.terrainData.size.z)), sliceCount);
    }

    private TessellationJob TessllateMesh(int gridMax, List<MeshLODCreate> lodInputs, ref MTTerrainScanner customDetail, bool showMsg = true)
    {
        CreateMeshJob dataCreateJob = AddCreateMeshJob(gridMax, lodInputs, customDetail == null);
        for (int i = 0; i < int.MaxValue; ++i)
        {
            dataCreateJob.Update();
            if (showMsg)
                EditorUtility.DisplayProgressBar("creating data", "scaning volumn", dataCreateJob.progress);
            if (dataCreateJob.IsDone)
                break;
        }

        dataCreateJob.EndProcess(ref customDetail);
        //caculate min_tri size
        int max_sub = 1;
        foreach (var setting in LODSettings)
        {
            if (setting.Subdivision > max_sub)
                max_sub = setting.Subdivision;
        }
        float max_sub_grids = gridMax * (1 << max_sub);
        float minPoitDistance = Mathf.Max(terrainTarget.terrainData.bounds.size.x, terrainTarget.terrainData.bounds.size.z) / max_sub_grids * 0.25f;
        //float minArea = Mathf.Max(terrainTarget.terrainData.bounds.size.x, terrainTarget.terrainData.bounds.size.z) / max_sub_grids;
        //minArea = minArea * minArea / 8f;
        //minArea = Mathf.Min(minArea, 0.001f);
        //
        var tessellationJob = new TessellationJob(terrainTarget, dataCreateJob.LODs, minPoitDistance);

        for (int i = 0; i < int.MaxValue; ++i)
        {
            tessellationJob.Update();
            if (showMsg)
                EditorUtility.DisplayProgressBar("creating data", "tessellation", tessellationJob.progress);
            if (tessellationJob.IsDone)
                break;
        }
        return tessellationJob;
    }

    private CreateMeshJob AddCreateMeshJob(int gridMax, List<MeshLODCreate> lodInputs, bool createBoundry)
    {
        var tBnd = new Bounds(terrainTarget.transform.TransformPoint(terrainTarget.terrainData.bounds.center), terrainTarget.terrainData.bounds.size);
        CreateMeshJob dataCreateJob = new CreateMeshJob(terrainTarget, tBnd, gridMax, gridMax, lodInputs, createBoundry);
        return dataCreateJob;
    }

    void UpdateTerrainGrids()
    {
        if (splitedTerrains.Count == 0)
        {
            if(terrainGrids == null || terrainGrids.GetLength(0) != 1 || terrainGrids.GetLength(1) != 1)
            {
                terrainGrids = new Terrain[1,1];
            }

            terrainGrids[0, 0] = terrainTarget;
            terrainGridsFull = true;
        }
        else
        {
            float minTerrainWidth = float.MaxValue;
            for (int i = 0; i < splitedTerrains.Count; i++)
            {
                if (minTerrainWidth > splitedTerrains[i].terrainData.size.x)
                {
                    minTerrainWidth = splitedTerrains[i].terrainData.size.x;
                }
            }

            Vector3 targetTerrainSize = terrainTarget.terrainData.size;
            int count = Mathf.RoundToInt(targetTerrainSize.x / minTerrainWidth);
            terrainGrids = new Terrain[count, count];
            float xGap = targetTerrainSize.x / count;
            float yGap = targetTerrainSize.z / count;

            for (int x = 0; x < count; x++)
            {
                for (int y = 0; y < count; y++)
                {
                    for (int i = 0; i < splitedTerrains.Count; i++)
                    {
                        var terrain = splitedTerrains[i];
                        Bounds bounds = terrain.terrainData.bounds;
                        Bounds worldBounds = new Bounds(terrain.transform.TransformPoint(bounds.center), bounds.size);
                        Vector3 testPoint = new Vector3(xGap * (x + 0.5f), worldBounds.center.y, yGap * (y + 0.5f));
                        if (worldBounds.Contains(testPoint))
                        {
                            terrainGrids[x, y] = terrain;
                            Debug.Log($"({x},{y}): {terrain.name}", terrain);
                            break;
                        }
                    }
                }
            }

            terrainGridsFull = true;
            for (int x = 0; x < count; x++)
            {
                for (int y = 0; y < count; y++)
                {
                    if (terrainGrids[x, y] == null)
                    {
                        terrainGridsFull = false;
                    }
                }
            }
        }
    }

    void InsertTerrain2Mats(string lodFolder, Terrain terrain, ref Dictionary<Terrain, List<Material>> terrain2Mats)
    {
        List<Material> mats = new List<Material>();
        List<string> matPath = new List<string>();
        conversionShaderSuite.SaveMixMaterials(lodFolder, terrain.name, terrain, matPath);
        foreach (var p in matPath)
        {
            var m = AssetDatabase.LoadAssetAtPath<Material>(p);
            mats.Add(m);
        }

        foreach (var mat in mats)
        {
            float scale = terrainTarget.terrainData.size.x / terrain.terrainData.size.x;
            mat.SetTextureScale("_Control", Vector2.one * scale);
            //mat.SetTextureOffset("_Control", -new Vector2(terrain.transform.position.x / terrainTarget.terrainData.size.x, terrain.transform.position.z / terrainTarget.terrainData.size.z) * scale);

            for (int i = 0; i < 4; i++)
            {
                string splatName = "_Splat" + i;
                Vector2 splatScale = mat.GetTextureScale(splatName);
                mat.SetTextureScale(splatName, splatScale * scale);
            }
        }

        if (!terrain2Mats.ContainsKey(terrain))
        {
            terrain2Mats.Add(terrain, mats);
        }
    }

    GameObject ApplyNormalLODSplatmap(string lodFolder, List<MeshItem> meshItems, bool useSplatAtlas)
    {
        GameObject prefabRoot = new GameObject(terrainTarget.name);
        prefabRoot.transform.position = terrainTarget.transform.position;
        int lodCount = LODSettings.Count;

        if (useSplatAtlas)
        {
            string mathPath = string.Format("{0}/{1}.mat", lodFolder, "splatmapAtlas");
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(mathPath);
            if (mat != null)
                AssetDatabase.DeleteAsset(mathPath);
            mat = conversionShaderSuite.GetSplatmapAtlasMat(controlmap, diffuseAtlas, normalAtlas);
            AssetDatabase.CreateAsset(mat, mathPath);

            CreateMeshObjects(meshItems, lodCount, (meshItem, meshGo) =>
            {
                var renderer = meshGo.GetComponent<Renderer>();
                renderer.sharedMaterial = mat;
                Transform lodGroupTrans = prefabRoot.transform.Find(meshItem.meshId.ToString());
                LODGroup lodGroup = null;
                if (lodGroupTrans == null)
                {
                    lodGroupTrans = new GameObject(meshItem.meshId.ToString()).transform;
                    lodGroupTrans.gameObject.AddComponent<LODGroup>();
                }
                lodGroup = lodGroupTrans.GetComponent<LODGroup>();
                meshGo.transform.parent = lodGroupTrans.transform;
                meshGo.transform.localPosition = Vector3.zero;
                lodGroupTrans.SetParent(prefabRoot.transform, false);
            });
        }
        else
        {
            Dictionary<Terrain, List<Material>> terrain2Mats = new Dictionary<Terrain, List<Material>>();
            if (splitedTerrains.Count > 0)
            {
                foreach (var terrain in splitedTerrains)
                {
                    InsertTerrain2Mats(lodFolder, terrain, ref terrain2Mats);
                }
            }
            else
            {
                InsertTerrain2Mats(lodFolder, terrainTarget, ref terrain2Mats);
            }

            CreateMeshObjects(meshItems, lodCount, (meshItem, meshGo) =>
            {
                //为避免精度问题，在index的基础上偏移0.5
                Vector2Int index = meshItem.GetIndex(sliceCount, sliceCount);
                int xIndexInTerrainGrids = (int)((index.x + 0.5f) * ((float)terrainGrids.GetLength(0) / sliceCount));
                int yIndexInTerrainGrids = (int)((index.y + 0.5f) * ((float)terrainGrids.GetLength(0) / sliceCount));
                Terrain localTerrain = terrainGrids[xIndexInTerrainGrids, yIndexInTerrainGrids];
                List<Material> mats = terrain2Mats[localTerrain];
                var renderer = meshGo.GetComponent<Renderer>();
                renderer.sharedMaterials = mats.ToArray();
                Transform lodGroupTrans = prefabRoot.transform.Find(meshItem.meshId.ToString());
                LODGroup lodGroup = null;
                if (lodGroupTrans == null)
                {
                    lodGroupTrans = new GameObject(meshItem.meshId.ToString()).transform;
                    lodGroupTrans.gameObject.AddComponent<LODGroup>();
                }
                lodGroup = lodGroupTrans.GetComponent<LODGroup>();
                meshGo.transform.parent = lodGroupTrans.transform;
                meshGo.transform.localPosition = Vector3.zero;
                lodGroupTrans.SetParent(prefabRoot.transform, false);
            });
        }

        prefabRoot.AddComponent<TerrainLODGroupController>();
        ApplyLODGroupInfo(prefabRoot, LODSettings);
        PrefabUtility.SaveAsPrefabAssetAndConnect(prefabRoot, lodFolder + "/" + terrainTarget.name + ".prefab", InteractionMode.AutomatedAction);

        return prefabRoot;
    }

    private void CreateMeshObjects(List<MeshItem> meshItems, int lodCount, Action<MeshItem, GameObject> ogGetMeshGo)
    {
        for (int lodIndex = 0; lodIndex < lodCount; lodIndex++)
        {
            IterateMeshItemAtLod(meshItems, lodIndex, lodCount, (meshItem) =>
            {
                GameObject meshGo = new GameObject(meshItem.meshId.ToString() + "_LOD" + lodIndex);
                var filter = meshGo.AddComponent<MeshFilter>();
                filter.mesh = meshItem.mesh;
                meshGo.AddComponent<MeshRenderer>();
                ogGetMeshGo?.Invoke(meshItem, meshGo);
            });
        }
    }

    GameObject ApplyNormalLODBasemap(List<MeshItem> meshItems, Terrain curentTarget, string lodFolder, int lodCount, int depth, Texture2D texture, RenderTexture renderTexture, Material[] arrAlbetoMats, Material[] arrNormalMats)
    {
        GameObject prefabRoot = new GameObject(curentTarget.name);
        prefabRoot.transform.position = terrainTarget.transform.position;
        CreateBasemapTextureAndMaterial(meshItems, lodFolder, lodCount, depth, texture, renderTexture, arrAlbetoMats, arrNormalMats);

        CreateMeshObjects(meshItems, lodCount, (meshItem, meshGo) =>
        {
            var info = FetchBasemapAssetPath(lodFolder, meshItem, 0);
            //prefab
            Transform lodGroupTrans = prefabRoot.transform.Find(meshItem.meshId.ToString());
            LODGroup lodGroup = null;
            if (lodGroupTrans == null)
            {
                lodGroupTrans = new GameObject(meshItem.meshId.ToString()).transform;
                lodGroupTrans.gameObject.AddComponent<LODGroup>();
            }
            lodGroup = lodGroupTrans.GetComponent<LODGroup>();
            var filter = meshGo.GetComponent<MeshFilter>();
            filter.mesh = meshItem.mesh;
            var renderer = meshGo.GetComponent<MeshRenderer>();
            renderer.sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>(info.matPath);
            meshGo.transform.parent = lodGroupTrans.transform;
            meshGo.transform.localPosition = Vector3.zero;
            lodGroupTrans.SetParent(prefabRoot.transform, false);
        });

        prefabRoot.AddComponent<TerrainLODGroupController>();
        //var streamingTerrainManager = prefabRoot.AddComponent<StreamingTerrainManager>();
        //streamingTerrainManager.baseMapMat = basemapMat;
        ApplyLODGroupInfo(prefabRoot, LODSettings);
        RenderTexture.ReleaseTemporary(renderTexture);

        PrefabUtility.SaveAsPrefabAssetAndConnect(prefabRoot, lodFolder + "/" + terrainTarget.name + ".prefab", InteractionMode.AutomatedAction);
        return prefabRoot;
    }

    private void CreateBasemapTextureAndMaterial(List<MeshItem> meshItems, string lodFolder, int lodCount, int depth, Texture2D texture, RenderTexture renderTexture, Material[] arrAlbetoMats, Material[] arrNormalMats)
    {
        if (!AssetDatabase.IsValidFolder(Path.Combine(lodFolder, "Textures")))
        {
            AssetDatabase.CreateFolder(lodFolder, "Textures");
        }

        if (!AssetDatabase.IsValidFolder(Path.Combine(lodFolder, "Materials")))
        {
            AssetDatabase.CreateFolder(lodFolder, "Materials");
        }

        if (splitType == SplitType.HLOD)
        {
            if (!AssetDatabase.IsValidFolder(Path.Combine(lodFolder, "Textures", $"Depth{depth}")))
            {
                AssetDatabase.CreateFolder(Path.Combine(lodFolder, "Textures"), $"Depth{depth}");
            }

            if (!AssetDatabase.IsValidFolder(Path.Combine(lodFolder, "Materials", $"Depth{depth}")))
            {
                AssetDatabase.CreateFolder(Path.Combine(lodFolder, "Materials"), $"Depth{depth}");
            }
        }

        AssetDatabase.Refresh();

        Texture2D albetoTex = null;
        Texture2D normalTex = null;
        Texture2D holeTex = null;

        Texture2D normalTexture = CreateNormalTexture(texture);
        IterateMeshItemAtLod(meshItems, 0, lodCount, (meshItem) =>
        {
            var info = FetchBasemapAssetPath(lodFolder, meshItem, depth);
            SaveBakedTexture(info.albeto, true, ref renderTexture, texture, arrAlbetoMats, meshItem.scaleOffset);
            SaveBakedTexture(info.normal, false, ref renderTexture, normalTexture, arrNormalMats, meshItem.scaleOffset);
            albetoTex = AssetDatabase.LoadAssetAtPath<Texture2D>(info.albeto);
            normalTex = AssetDatabase.LoadAssetAtPath<Texture2D>(info.normal);
            holeTex = AssetDatabase.LoadAssetAtPath<Texture2D>(info.hole);
            conversionShaderSuite.SaveBakedMaterial(info.matPath, albetoTex, normalTex, holeTex, new Vector2(meshItem.scaleOffset.x, meshItem.scaleOffset.y), new Vector2(meshItem.scaleOffset.z, meshItem.scaleOffset.w));
        });

        AssetDatabase.Refresh();
    }

    private static Texture2D CreateNormalTexture(Texture2D texture)
    {
        //return new Texture2D(texture.width / 2, texture.height / 2, texture.format, true, true);
        return new Texture2D(texture.width, texture.height, texture.format, true, true);
    }

    class BasemapAssetPathInfo
    {
        public string albeto;
        public string normal;
        public string matPath;
        public string hole;
    }

    private BasemapAssetPathInfo FetchBasemapAssetPath(string lodFolder, MeshItem meshItem, int depth)
    {
        BasemapAssetPathInfo info = new BasemapAssetPathInfo();
        if (splitType == SplitType.NormalLOD)
        {
            info.albeto  = string.Format("{0}/Textures/albeto_{1}.png", lodFolder, meshItem.meshId);
            info.normal  = string.Format("{0}/Textures/normal_{1}.png", lodFolder, meshItem.meshId);
            info.matPath = string.Format("{0}/Materials/mat_{1}.mat", lodFolder, meshItem.meshId);
            info.hole = string.Format("{0}/Textures/hole_{1}.png", lodFolder, meshItem.meshId);
        }
        else
        {
            info.albeto = string.Format("{0}/Textures/Depth{1}/albeto_{2}.png", lodFolder, depth, meshItem.meshId);
            info.normal = string.Format("{0}/Textures/Depth{1}/normal_{2}.png", lodFolder, depth, meshItem.meshId);
            info.matPath = string.Format("{0}/Materials/Depth{1}/mat_{2}.mat", lodFolder, depth, meshItem.meshId);
            info.hole = string.Format("{0}/Textures/Depth{1}/hole_{2}.png", lodFolder, depth, meshItem.meshId);
        }
        return info;
    }

    private void IterateMeshItemAtLod(List<MeshItem> meshItems, int lodIndex, int totalLodCount,  Action<MeshItem> onIterate)
    {
        if (onIterate == null)
            return;

        //meshItems的存储逻辑是0_lod0, 0_lod1, 1_lod0, 1_lod1...
        int itemCountPerLod = meshItems.Count / totalLodCount;
        for (int cnt = 0, i = lodIndex; cnt < itemCountPerLod; cnt++, i += totalLodCount)
        {
            var baker = meshItems[i];
            onIterate(baker);
        }
    }

    public static void ApplyLODGroupInfo(GameObject root, List<HRPLODSetting> settings)
    {
        for (int i = 0; i < root.transform.childCount; i++)
        {
            var lodGroup = root.transform.GetChild(i).GetComponent<LODGroup>();
            LOD[] lods = new LOD[lodGroup.transform.childCount];
            for (int j = 0; j < lodGroup.transform.childCount; j++)
            {
                lods[j] = new LOD(settings[j].screenRelativeTransitionHeight, new Renderer[] { lodGroup.transform.GetChild(j).GetComponent<Renderer>() });
            }
            lodGroup.SetLODs(lods);
        }
    }

    Mesh SaveMesh(string path, MTMeshData.LOD data, bool genUV2)
    {
        Mesh mesh = new Mesh();
        mesh.vertices = data.vertices;
        mesh.normals = data.normals;
        mesh.uv = data.uvs;
        if (genUV2)
        {
            mesh.uv2 = data.uvs;
        }
        mesh.triangles = data.faces;
        mesh.UploadMeshData(true);
        if (!AssetDatabase.IsValidFolder(Path.GetDirectoryName(path)))
        {
            Directory.CreateDirectory(Application.dataPath.Replace("Assets", Path.GetDirectoryName(path)));
        }

        AssetDatabase.CreateAsset(mesh, path);
        return mesh;
    }


    void SaveBakedTexture(string path, bool isSRGB, ref RenderTexture renderTexture, Texture2D texture, Material[] arrMats, Vector4 scaleOffset)
    {
        RenderTexture.ReleaseTemporary(renderTexture);
        RenderTextureDescriptor descriptor = renderTexture.descriptor;
        if (isSRGB)
        {
            renderTexture = RenderTexture.GetTemporary(descriptor.width, descriptor.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        }
        else
        {
            renderTexture = RenderTexture.GetTemporary(descriptor.width, descriptor.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        }

        //不知道是哪里出了问题，材质上的一些属性会莫名奇妙的不起作用，需要重新赋一次才能正确工作
        conversionShaderSuite.InitBakeMaterial(arrMats[0], terrainTarget);
        arrMats[0].SetVector("_BakeScaleOffset", scaleOffset);
        Graphics.Blit(null, renderTexture, arrMats[0]);
        if (arrMats[1] != null)
        {
            conversionShaderSuite.InitBakeMaterial(arrMats[1], terrainTarget);
            arrMats[1].SetVector("_BakeScaleOffset", scaleOffset);
            Graphics.Blit(null, renderTexture, arrMats[1]);
        }
        texture.ReadPixels(new Rect(Vector2.zero, new Vector2(texture.width, texture.height)), 0, 0);
        texture.Apply();
        
        byte[] png = texture.EncodeToPNG();
        string pngPath = Application.dataPath.Replace("Assets", path);
        File.WriteAllBytes(pngPath, png);
        AssetDatabase.Refresh();

        var importer = TextureImporter.GetAtPath(path) as TextureImporter;
        importer.sRGBTexture = isSRGB;
        importer.wrapMode = TextureWrapMode.Clamp;
        importer.textureType = TextureImporterType.Default;
        TextureImporterPlatformSettings settings = importer.GetPlatformTextureSettings("Android");
        if (settings != null)
        {
            settings.overridden = true;
            settings.maxTextureSize = 2048;
            settings.format = isSRGB ? TextureImporterFormat.ASTC_6x6 : TextureImporterFormat.ASTC_4x4;
            importer.SetPlatformTextureSettings(settings);
        }
        settings = importer.GetPlatformTextureSettings("iPhone");
        if (settings != null)
        {
            settings.overridden = true;
            settings.maxTextureSize = 2048;
            settings.format = isSRGB ? TextureImporterFormat.ASTC_6x6 : TextureImporterFormat.ASTC_4x4;
            importer.SetPlatformTextureSettings(settings);
        }
        importer.SaveAndReimport();
        AssetDatabase.Refresh();
    }
}