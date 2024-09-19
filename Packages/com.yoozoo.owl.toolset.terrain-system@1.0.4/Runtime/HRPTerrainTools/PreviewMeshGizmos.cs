using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PreviewMeshGizmos : MonoBehaviour
{
#if UNITY_EDITOR
    private Bounds bounds;
    private float gapX;
    private float gapZ;
    private int sliceCount;

    public void Init(Bounds bounds, int sliceCount)
    {
        this.sliceCount = sliceCount;
        this.bounds = bounds;
        gapX = bounds.size.x / sliceCount;
        gapZ = bounds.size.z / sliceCount;
    }

    private void OnDrawGizmos()
    {
        return;

        Gizmos.color = Color.green;
        for (int x = 0; x < sliceCount; x++)
        {
            for (int y = 0; y < sliceCount; y++)
            {
                Vector3 center = new Vector3(bounds.min.x + gapX * (x + 0.5f), bounds.min.y, bounds.min.z + gapZ * (y + 0.5f));

                Gizmos.DrawWireCube(center, new Vector3(gapX, 0, gapZ));
            }
        }
    }
#endif
}
