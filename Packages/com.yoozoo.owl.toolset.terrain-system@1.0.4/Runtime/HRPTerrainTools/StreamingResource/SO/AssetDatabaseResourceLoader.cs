using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[CreateAssetMenu(menuName = "HRP/ResourceLoader/AssetDatabaseResourceLoader")]
public class AssetDatabaseResourceLoader : ResourceLoader
{
    public override void LoadAsync(ResourceReq req, Action<UnityEngine.Object> onSuccess)
    {
#if UNITY_EDITOR
        var asset = AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(req.msg.assetPath);
        onSuccess?.Invoke(asset);
#endif
    }

    public override string ProvidePath(UnityEngine.Object asset)
    {
#if UNITY_EDITOR
        return AssetDatabase.GetAssetPath(asset);
#else
        return string.Empty;
#endif
    }

    public override void UnloadAsync(ResourceReq req, Action onSuccess)
    {
#if UNITY_EDITOR
        onSuccess?.Invoke();
#endif
    }
}
