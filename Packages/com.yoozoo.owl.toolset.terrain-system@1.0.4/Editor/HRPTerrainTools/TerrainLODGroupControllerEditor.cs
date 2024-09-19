using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(TerrainLODGroupController))]
public class TerrainLODGroupControllerEditor : Editor
{
    public LODGroup[] lodGroups;
    private TerrainLODGroupController controller;
    private List<HRPLODSetting> lodSettings = new List<HRPLODSetting>();

    private void OnEnable()
    {
        controller = target as TerrainLODGroupController;
        lodGroups = controller.GetComponentsInChildren<LODGroup>();
        if (lodGroups.Length == 0)
            return;

        LOD[] lods = lodGroups[0].GetLODs();
        for (int i = 0; i < lods.Length; i++)
        {
            HRPLODSetting setting = new HRPLODSetting();
            setting.screenRelativeTransitionHeight = lods[i].screenRelativeTransitionHeight;
            lodSettings.Add(setting);
        }
    }

    private void OnDisable()
    {
        lodSettings.Clear();
    }

    private List<float> screenTransitionHeights = new List<float>();

    public override void OnInspectorGUI()
    {
        EditorGUILayout.LabelField("LOD信息");
        screenTransitionHeights.Clear();
        foreach (var lodSetting in lodSettings)
        {
            screenTransitionHeights.Add(lodSetting.screenRelativeTransitionHeight);
        }

        HRPMeshEditor.DrawHRPLODSettings(lodSettings, true, false, false, true);
        for (int i = 0; i < screenTransitionHeights.Count; i++)
        {
            if(screenTransitionHeights[i] != lodSettings[i].screenRelativeTransitionHeight)
            {
                HRPMeshEditor.ApplyLODGroupInfo(controller.gameObject, lodSettings);
                break;
            }
        }

        using (new EditorGUILayout.HorizontalScope())
        {
            if (GUILayout.Button("开启所有LODGroup"))
            {
                for (int i = 0; i < lodGroups.Length; i++)
                {
                    lodGroups[i].enabled = true;
                }
            }

            if (GUILayout.Button("关闭所有LODGroup"))
            {
                for (int i = 0; i < lodGroups.Length; i++)
                {
                    lodGroups[i].enabled = false;
                }
            }
        }

        using (new EditorGUILayout.HorizontalScope())
        {
            if (GUILayout.Button("添加MeshCollider"))
            {
                MeshFilter[] results = controller.GetComponentsInChildren<MeshFilter>(true);
                foreach (var result in results)
                {
                    if(result.GetComponent<MeshCollider>() == null)
                    {
                        if (result.gameObject.name.EndsWith("LOD0"))
                        {
                            var collider = result.gameObject.AddComponent<MeshCollider>();
                            collider.sharedMesh = result.sharedMesh;
                        }
                    }
                }
                EditorUtility.SetDirty(controller.gameObject);
            }
            if (GUILayout.Button("移除MeshCollider"))
            {
                MeshCollider[] results = controller.GetComponentsInChildren<MeshCollider>(true);
                foreach (var result in results)
                {
                    GameObject.DestroyImmediate(result);
                }
                EditorUtility.SetDirty(controller.gameObject);
            }
        }

        using (new EditorGUILayout.HorizontalScope())
        {
            if (GUILayout.Button("开启投影"))
            {
                MeshRenderer[] results = controller.GetComponentsInChildren<MeshRenderer>(true);
                foreach (var result in results)
                {
                    result.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
                }
                EditorUtility.SetDirty(controller.gameObject);
            }
            if (GUILayout.Button("关闭投影"))
            {
                MeshRenderer[] results = controller.GetComponentsInChildren<MeshRenderer>(true);
                foreach (var result in results)
                {
                    result.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                }
                EditorUtility.SetDirty(controller.gameObject);
            }
        }

        if (GUILayout.Button("移除所有材质"))
        {
            MeshRenderer[] results = controller.GetComponentsInChildren<MeshRenderer>(true);
            foreach (var result in results)
            {
                result.sharedMaterial = null;
            }
            EditorUtility.SetDirty(controller.gameObject);
        }
    }
}
