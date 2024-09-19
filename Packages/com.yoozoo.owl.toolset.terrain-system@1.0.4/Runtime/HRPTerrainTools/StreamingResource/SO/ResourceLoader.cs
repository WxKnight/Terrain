using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class ResourceLoader : ScriptableObject
{
    public abstract string ProvidePath(UnityEngine.Object asset);
    public abstract void LoadAsync(ResourceReq req, Action<UnityEngine.Object> onSuccess);
    public abstract void UnloadAsync(ResourceReq req, Action onSuccess);
}
