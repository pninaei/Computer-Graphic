using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }

    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        normals = new Vector3[vertices.Count];
        for (int i = 0; i < vertices.Count; i++)
        {
            List<Vector3> facesNormals = new List<Vector3>();
            for (int j = 0; j < triangles.Count - 2; j += 3)
            {
                // each of this three indexes tells us which vertices participate in the triangle
                int index0 = triangles[j];
                int index1 = triangles[j + 1];
                int index2 = triangles[j + 2];

                if (index0 == i || index1 == i || index2 == i)
                {
                    Vector3 v0 = vertices[index0];
                    Vector3 v1 = vertices[index1];
                    Vector3 v2 = vertices[index2];

                    Vector3 edge1 = v1 - v0;
                    Vector3 edge2 = v2 - v0;
                    // this is a normal for one face that vertex i in this triangle
                    Vector3 faceNormal = Vector3.Cross(edge1, edge2).normalized;

                    facesNormals.Add(faceNormal);
                }

            }
            // average the normals of all faces that share this vertex
            Vector3 sumNormals = new Vector3(0, 0, 0);
            foreach (Vector3 normal in facesNormals) sumNormals += normal;
            normals[i] = sumNormals.normalized;

        }

    }

    // Edits mesh such that each face has a unique set of 3 vertices
    public void MakeFlatShaded()
    {
        List<Vector3> new_vertices = new List<Vector3>();
        List<int> new_triangles = new List<int>();
        List<Vector3> new_normals = new List<Vector3>();

        int index = 0;
        // for each triangle, create 3 new vertices // (vi, vj, vk)
        for (int i = 0; i < triangles.Count - 2; i += 3)
        {

            // take the three vertices of one triangle
            Vector3 v0 = new Vector3(vertices[triangles[i]].x, vertices[triangles[i]].y, vertices[triangles[i]].z);
            Vector3 v1 = new Vector3(vertices[triangles[i + 1]].x, vertices[triangles[i + 1]].y, vertices[triangles[i + 1]].z);
            Vector3 v2 = new Vector3(vertices[triangles[i + 2]].x, vertices[triangles[i + 2]].y, vertices[triangles[i + 2]].z);
            // add them to the new vertices list
            new_vertices.Add(v0);
            new_vertices.Add(v1);
            new_vertices.Add(v2);

            // create a new triangle with the new vertices
            new_triangles.Add(index);
            new_triangles.Add(index + 1);
            new_triangles.Add(index + 2);
            index += 3;

            // compute normal for this face
            Vector3 edge1 = v1 - v0;
            Vector3 edge2 = v2 - v0;
            // this is a normal for one face that vertex i in this triangle
            Vector3 faceNormal = Vector3.Cross(edge1, edge2).normalized;

            // assign the same normal to the three new vertices
            new_normals.Add(faceNormal);
            new_normals.Add(faceNormal);
            new_normals.Add(faceNormal);
        }
        // replace old lists with new ones
        vertices = new_vertices;
        triangles = new_triangles;
        normals = new_normals.ToArray();
    }
}