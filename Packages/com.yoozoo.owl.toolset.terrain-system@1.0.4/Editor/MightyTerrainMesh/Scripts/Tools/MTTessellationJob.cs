namespace MightyTerrainMesh
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;
    using TriangleNet.Geometry;
    using System;

    //
    public class TessellationJob
    {
        public MTMeshData[] mesh;
        public MTTerrainScanner[] scanners;
        private Terrain terrain;

        public bool IsDone
        {
            get
            {
                return curIdx >= mesh.Length;
            }
        }
        public float progress
        {
            get
            {
                return (float)(curIdx / (float)(mesh.Length));
            }
        }
        public TessellationJob(Terrain terrain, MTTerrainScanner[] s, float minPointDistance)
        {
            this.terrain = terrain;
            scanners = s;
            MinPointDistance = minPointDistance;
            mesh = new MTMeshData[scanners[0].Trees.Length];
        }
        public float MinPointDistance { get; private set; }
        protected int curIdx = 0;

        //private HashSet<long> insertedPoints = new HashSet<long>();

        protected void RunTessellation(List<SampleVertexData> lVerts, MTMeshData.LOD lod, TriangleNet.TriangulationAlgorithm algorithm)
        {
            if (lVerts.Count < 3)
            {
                ++curIdx;
                return;
            }

            //将以世界空间(0,0)为父节点的mesh信息转变为以terrain为父节点的mesh信息
            Vector3 terrainPosition = terrain.transform.position;
            TerrainData terrainData = terrain.terrainData;
            InputGeometry geometry = new InputGeometry();
            //insertedPoints.Clear();
            //float pointError = 1f / minPointDistance;

            for (int i = 0; i < lVerts.Count; i++)
            {
                var vert = lVerts[i];
                //Vector2 localPos = new Vector2(vert.Position.x, vert.Position.z);
                //long key = (long)(localPos.x * pointError) + (((long)(localPos.y * pointError)) << 32);
                //if (!insertedPoints.Contains(key))
                //{
                //    insertedPoints.Add(key);
                //}
                geometry.AddPoint(vert.Position.x, vert.Position.z, 0);
            }
            TriangleNet.Mesh meshRepresentation = new TriangleNet.Mesh();
            meshRepresentation.Behavior.Algorithm = algorithm;
            meshRepresentation.Behavior.NoHoles = true;
            meshRepresentation.Triangulate(geometry);
            if (meshRepresentation.Vertices.Count != lVerts.Count)
            {
                Debug.LogError($"represent vertices: {meshRepresentation.vertices.Count}, lVerts: {lVerts.Count}");
            }

            List<Vector3> vertices = new List<Vector3>();
            List<Vector3> normals = new List<Vector3>();
            List<Vector2> uvs = new List<Vector2>();
            List<int> faces = new List<int>();

            int idx = 0;
            foreach (var v in meshRepresentation.Vertices)
            {
                //考虑到简化采样点会平均normal，因此lVert还是有用的
                Vector2 localPos = new Vector2(v.x, v.y) - new Vector2(terrainPosition.x, terrainPosition.z);
                Vector2 uv = new Vector2(localPos.x / terrainData.size.x, localPos.y / terrainData.size.z);
                vertices.Add(new Vector3(localPos.x, lVerts[idx].Position.y - terrainPosition.y, localPos.y));
                normals.Add(lVerts[idx].Normal);
                uvs.Add(lVerts[idx].UV);
                idx++;
            }

            foreach (var t in meshRepresentation.triangles.Values)
            {
                //var p = new Vector2[] { new Vector2(lod.vertices[t.P0].x, lod.vertices[t.P0].z),
                //    new Vector2(lod.vertices[t.P1].x, lod.vertices[t.P1].z),
                //    new Vector2(lod.vertices[t.P2].x, lod.vertices[t.P2].z)};
                //var triarea = UnityEngine.Mathf.Abs((p[2].x - p[0].x) * (p[1].y - p[0].y) -
                //       (p[1].x - p[0].x) * (p[2].y - p[0].y)) / 2.0f;
                //if (triarea < minTriArea)
                //    continue;
                faces.Add(t.P2);
                faces.Add(t.P1);
                faces.Add(t.P0);
            }

            lod.vertices = vertices.ToArray();
            lod.normals = normals.ToArray();
            lod.uvs = uvs.ToArray();
            lod.faces = faces.ToArray();
        }

        public virtual void Update()
        {
            if (IsDone)
                return;
            mesh[curIdx] = new MTMeshData(curIdx, scanners[0].Trees[curIdx].BND);
            mesh[curIdx].lods = new MTMeshData.LOD[scanners.Length];
            for (int lod = 0; lod < scanners.Length; ++lod)
            {
                var lodData = new MTMeshData.LOD();
                var tree = scanners[lod].Trees[curIdx];

                //不知道为啥，如果slopeAngleErr过低时使用Increment会在某处卡死，因此当其过小时使用Dwyer
                TriangleNet.TriangulationAlgorithm algorithm = scanners[lod].slopeAngleErr > 30 ? TriangleNet.TriangulationAlgorithm.Incremental : TriangleNet.TriangulationAlgorithm.Dwyer;
                RunTessellation(tree.Vertices, lodData, algorithm);
                lodData.uvmin = tree.uvMin;
                lodData.uvmax = tree.uvMax;
                mesh[curIdx].lods[lod] = lodData;
            }
            //update idx
            ++curIdx;
        }
    }

    //public class TessellationDataJob : TessellationJob
    //{
    //    Terrain terrain;
    //    List<SamplerTree> subTrees = new List<SamplerTree>();
    //    List<int> lodLvArr = new List<int>();

    //    public TessellationDataJob(Terrain terrain, MTTerrainScanner[] s, float minTriArea) : base(terrain, s, minTriArea)
    //    {
    //        this.terrain = terrain;

    //        int totalLen = 0;
    //        foreach(var scaner in scanners)
    //        {
    //            totalLen += scaner.Trees.Length;
    //            lodLvArr.Add(totalLen);
    //            subTrees.AddRange(scaner.Trees);
    //        }
    //        mesh = new MTMeshData[subTrees.Count];
    //    }

    //    private int GetLodLv(int idx)
    //    {
    //        for(int i=0; i<lodLvArr.Count; ++i)
    //        {
    //            if (idx < lodLvArr[i])
    //                return i;
    //        }
    //        return 0;
    //    }

    //    public override void Update()
    //    {
    //        if (IsDone)
    //            return;
    //        var lodLv = GetLodLv(curIdx);
    //        mesh[curIdx] = new MTMeshData(curIdx, subTrees[curIdx].BND, lodLv);
    //        mesh[curIdx].lods = new MTMeshData.LOD[1];
    //        var lodData = new MTMeshData.LOD();
    //        var tree = subTrees[curIdx];
    //        RunTessellation(tree.Vertices, lodData, TriangleNet.TriangulationAlgorithm.Dwyer);
    //        mesh[curIdx].lods[0] = lodData;
    //        //update idx
    //        ++curIdx;
    //    }
    //}
}
