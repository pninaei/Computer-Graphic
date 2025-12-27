using System;

using UnityEngine;

public class QuaternionUtils
{
    // The default rotation order of Unity. May be used for testing
    public static readonly Vector3Int UNITY_ROTATION_ORDER = new Vector3Int(1, 2, 0);

    // Returns the product of 2 given quaternions
    public static Vector4 Multiply(Vector4 q1, Vector4 q2)
    {
        return new Vector4(
            q1.w*q2.x + q1.x*q2.w + q1.y*q2.z - q1.z*q2.y,
            q1.w*q2.y + q1.y*q2.w + q1.z*q2.x - q1.x*q2.z,
            q1.w*q2.z + q1.z*q2.w + q1.x*q2.y - q1.y*q2.x,
            q1.w*q2.w - q1.x*q2.x - q1.y*q2.y - q1.z*q2.z
        );
    }

    // Returns the conjugate of the given quaternion q
    public static Vector4 Conjugate(Vector4 q)
    {
        return new Vector4(-q.x, -q.y, -q.z, q.w);
    }

    // Returns the Hamilton product of given quaternions q and v
    public static Vector4 HamiltonProduct(Vector4 q, Vector4 v)
    {
        Vector4 qConjugate = Conjugate(q);
        return Multiply(Multiply(q, v), qConjugate);
    }

    // Returns a quaternion representing a rotation of theta degrees around the given axis
    public static Vector4 AxisAngle(Vector3 axis, float theta)
    {
        float cos = Mathf.Cos((theta / 2.0f) * Mathf.Deg2Rad);
        float sin = Mathf.Sin((theta / 2.0f) * Mathf.Deg2Rad);
        return new Vector4(sin * axis.x, sin * axis.y, sin * axis.z, cos);
    }

    // Returns a quaternion representing the given Euler angles applied in the given rotation order
   public static Vector4 FromEuler(Vector3 euler, Vector3Int rotationOrder)
{
    Vector4 qx = AxisAngle(Vector3.right,   euler.x);
    Vector4 qy = AxisAngle(Vector3.up,      euler.y);
    Vector4 qz = AxisAngle(Vector3.forward, euler.z);

    // rotationOrder says:
    // rotationOrder.x = when to apply X rotation
    // rotationOrder.y = when to apply Y rotation
    // rotationOrder.z = when to apply Z rotation

    Vector4[] q = { qx, qy, qz }; // q[0] = X, q[1] = Y, q[2] = Z
    Vector4 result = new Vector4(0,0,0,1); // identity quaternion

    for (int i = 0; i < 3; i++)
    {
        if (rotationOrder.x == i) result = Multiply(result, qx);
        if (rotationOrder.y == i) result = Multiply(result, qy);
        if (rotationOrder.z == i) result = Multiply(result, qz);
    }

    return result / result.magnitude;
}

    // Returns a spherically interpolated quaternion between q1 and q2 at time t in [0,1]
    public static Vector4 Slerp(Vector4 q1, Vector4 q2, float t)
    {
        // Compute the dot product and make sure to take the shortest path
        float dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;
        if (dot < 0f)
        {
            q2 = -q2;  
        }
        Vector4 q2Conjugate = Conjugate(q2);
        Vector4 r = Multiply(q1, q2Conjugate);
        
        float w = Mathf.Clamp(r.w, -1f, 1f);
        float thetaRad = Mathf.Acos(w);
        float sinTheta = Mathf.Sin(thetaRad);

        if (Mathf.Sin(thetaRad) == 0f)
            return q1; 

        float left = Mathf.Sin((1 - t) * thetaRad) / sinTheta;
        float right = Mathf.Sin(t * thetaRad) / sinTheta;

        Vector4 result = left * q1 + right * q2;
        return result / result.magnitude;
    }

}