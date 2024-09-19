using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum StreamingResourceState {
    Unloaded,
    Loading,
    Loaded,
    Unloading,
}

public enum ResourceMsgId
{
    Load,
    Unload
}

public struct ResourceMsg
{
    public ResourceMsgId msgId;
    public string assetPath;

    public override string ToString()
    {
        return $"msgId: {msgId}, assetPath: {assetPath}";
    }
}

public struct ResourceReq
{
    public ResourceMsg msg;
    public Action<StreamingResource> callback;

    public ResourceReq(ResourceMsg msg, Action<StreamingResource> callback)
    {
        this.msg = msg;
        this.callback = callback;
    }
}

public class StreamingResource
{
    public string AssetPath { get; private set; }
    public StreamingResourceState State { get; protected set; }
    public UnityEngine.Object Res { get; protected set; }

    public StreamingResource(string assetPath)
    {
        AssetPath = assetPath;
        State = StreamingResourceState.Unloaded;
    }

    public void LoadAsync(ResourceReq req, ResourceLoader resouceLoader)
    {
        State = StreamingResourceState.Loading;
        resouceLoader.LoadAsync(req, (obj) =>
        {
            State = StreamingResourceState.Loaded;
            Res = obj;
            req.callback?.Invoke(this);
        });
    }

    public void UnloadAsync(ResourceReq req, ResourceLoader resouceLoader)
    {
        State = StreamingResourceState.Unloading;
        resouceLoader.UnloadAsync(req, () =>
        {
            State = StreamingResourceState.Unloaded;
            req.callback?.Invoke(this);
            Res = null;
        });
    }
}