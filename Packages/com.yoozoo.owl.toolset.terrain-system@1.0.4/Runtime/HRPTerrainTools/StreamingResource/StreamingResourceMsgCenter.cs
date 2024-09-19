using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StreamingResourceMsgCenter : MonoBehaviour
{
    public static StreamingResourceMsgCenter Instance
    {
        get; private set;
    }

    private Dictionary<string, StreamingResource> streamingResources = new Dictionary<string, StreamingResource>();
    private Queue<ResourceReq> resourceReqs = new Queue<ResourceReq>();
    private List<ResourceReq> tempReqs = new List<ResourceReq>();
    private ResourceLoader resouceLoader;

    private void Awake()
    {
        if (Instance == null)
        {
            DontDestroyOnLoad(gameObject);
            Instance = this;
        }
        else
        {
            GameObject.Destroy(gameObject);
        }
    }

    public void AddResourceReq(ResourceReq resourceReq)
    {
        resourceReqs.Enqueue(resourceReq);
    }

    public void SetResLoader(ResourceLoader resouceLoader)
    {
        this.resouceLoader = resouceLoader;
    }

    public void Update()
    {
        foreach (var tempReq in tempReqs)
        {
            resourceReqs.Enqueue(tempReq);
        }
        tempReqs.Clear();

        while (resourceReqs.Count > 0)
        {
            var req = resourceReqs.Dequeue();
            HandleRequest(req, ref tempReqs);
        }
    }

    private List<StreamingResource> loadedStreamingResources = new List<StreamingResource>();

    private void HandleRequest(ResourceReq req, ref List<ResourceReq> tempReqs)
    {
        var res = GetStreamingResource(req.msg.assetPath);
        switch (req.msg.msgId)
        {
            case ResourceMsgId.Load:
                if (res == null)
                {
                    var streamingRes = new StreamingResource(req.msg.assetPath);
                    AddResource(req.msg.assetPath, streamingRes);
                    streamingRes.LoadAsync(req, resouceLoader);
                    break;
                }

                if(res.State == StreamingResourceState.Unloaded)
                {
                    res.LoadAsync(req, resouceLoader);
                }

                if (res.State == StreamingResourceState.Loaded)
                {
                    req.callback?.Invoke(res);
                    break;
                }

                if(res.State == StreamingResourceState.Unloading || res.State == StreamingResourceState.Loading)
                    tempReqs.Add(req);
                break;
            case ResourceMsgId.Unload:
                if(res == null)
                {
                    break;
                }

                if(res.State == StreamingResourceState.Loaded)
                {
                    res.UnloadAsync(req, resouceLoader);
                    break;
                }

                if(res.State == StreamingResourceState.Unloaded)
                {
                    req.callback?.Invoke(res);
                }

                if (res.State == StreamingResourceState.Loading || res.State == StreamingResourceState.Unloading)
                    tempReqs.Add(req);
                break;
            default:
                break;
        }
    }

    public StreamingResource GetStreamingResource(string assetPath)
    {
        if (streamingResources.ContainsKey(assetPath))
        {
            return streamingResources[assetPath];
        }
        return null;
    }

    private void AddResource(string assetPath, StreamingResource streamingResource)
    {
        if (!streamingResources.ContainsKey(assetPath))
        {
            streamingResources.Add(assetPath, streamingResource);
        }
    }

    private bool RemoveResource(StreamingResource streamingResource)
    {
        return streamingResources.Remove(streamingResource.AssetPath);
    }
}
