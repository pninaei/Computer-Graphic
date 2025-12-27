using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile; // The BVH file that defines the animation and skeleton
    public bool animate; // Indicates whether or not the animation should be running
    public bool interpolate; // Indicates whether or not frames should be interpolated
    [Range(0.01f, 2f)] public float animationSpeed = 1; // Controls the speed of the animation playback

    public BVHData data; // BVH data of the BVHFile will be loaded here
    public float t = 0; // Value used to interpolate the animation between frames
    public float[] currFrameData; // BVH channel data corresponding to the current keyframe
    public float[] nextFrameData; // BVH vhannel data corresponding to the next keyframe

    private float animTime = 0f; 
    private bool wasAnimating = false;


    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);
        CreateJoint(data.rootJoint, Vector3.zero);

    }

    // Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v
    public Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        // normalizing v
        Vector3 normalizedV = v.normalized;

        float thetaX = 90f - Mathf.Atan2(normalizedV.y, normalizedV.z) * Mathf.Rad2Deg;
        float thetaZ = 90f - Mathf.Atan2(Mathf.Sqrt((normalizedV.y * normalizedV.y) + (normalizedV.z * normalizedV.z)), normalizedV.x) * Mathf.Rad2Deg;

        Matrix4x4 R = MatrixUtils.RotateX(thetaX) * MatrixUtils.RotateZ(-thetaZ);
        return R;
    }

    // Creates a Cylinder GameObject between two given points in 3D space
    public GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {

        GameObject cylinder = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        // position the center at the cylinder's center
        Vector3 center = (p1 + p2) / 2.0f;
        
        // translation matrix
        Matrix4x4 T = MatrixUtils.Translate(center);

        // rotation matrix
        Matrix4x4 R = RotateTowardsVector(p2 - p1);

        // scale matrix
        Matrix4x4 S = MatrixUtils.Scale(new Vector3(diameter, (p2 - p1).magnitude / 2.0f, diameter));

        // combined transformation matrix
        Matrix4x4 M = T * R * S;
        MatrixUtils.ApplyTransform(cylinder, M);
        
        return cylinder;
    }

    // Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints
    public GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)

    {
        joint.gameObject = new GameObject();
        joint.gameObject.name = joint.name;

        GameObject jointObject = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        jointObject.transform.parent = joint.gameObject.transform;
     
        // part 1.3
        Vector3 scale = (joint.name == "Head") ? new Vector3(8.0f, 8.0f, 8.0f) : new Vector3(2.0f, 2.0f, 2.0f);
        Matrix4x4 scalingMatrix = MatrixUtils.Scale(scale);
        MatrixUtils.ApplyTransform(jointObject, scalingMatrix);

        // part 1.4 + 1.5
        Matrix4x4 translationMatrix = MatrixUtils.Translate(joint.offset + parentPosition);
        MatrixUtils.ApplyTransform(joint.gameObject, translationMatrix);

        // part 1.6
        foreach (BVHJoint child in joint.children)
        {
            //if (!child.isEndSite)
        //  {
            child.gameObject = CreateJoint(child, joint.offset + parentPosition);
            GameObject cylinder = CreateCylinderBetweenPoints(joint.offset + parentPosition,
                                            child.offset + joint.offset + parentPosition, 0.6f);
            cylinder.transform.parent = joint.gameObject.transform; 
                
            //}
        }
        return joint.gameObject;
    }

    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    public void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform)

    {
        // Scale matrix
        Matrix4x4 S = Matrix4x4.identity;
        // Translation matrix
        Matrix4x4 T = MatrixUtils.Translate(joint.offset);
        Matrix4x4 R; // Rotation matrix
        // Calculate the hip position
        Vector3 currHipPos = new Vector3(currFrameData[joint.positionChannels.x]
                                                , currFrameData[joint.positionChannels.y]
                                                , currFrameData[joint.positionChannels.z]);
        Vector3 nextHipPos = new Vector3(nextFrameData[joint.positionChannels.x]
                                                , nextFrameData[joint.positionChannels.y]
                                                , nextFrameData[joint.positionChannels.z]);


        if (!interpolate)
        { 
            if (joint == data.rootJoint)
            {
                // Apply the BVH root translation
                
                T = T * MatrixUtils.Translate(currHipPos);
            }
            Vector3 euler = new Vector3(currFrameData[joint.rotationChannels.x],
                                        currFrameData[joint.rotationChannels.y],
                                        currFrameData[joint.rotationChannels.z]);

            Vector4 q = QuaternionUtils.FromEuler(euler, joint.rotationOrder);
            
            R = MatrixUtils.RotateFromQuaternion(q);
        }
        else // if case interpolation is needed
        {
            if (joint == data.rootJoint)
            {
                Vector3 lerpedPosition = Vector3.Lerp(currHipPos, nextHipPos, t);
                T = T * MatrixUtils.Translate(lerpedPosition);
            }

            // Take all of the axis angles
            Vector3 currEuler = new Vector3(currFrameData[joint.rotationChannels.x],
                                        currFrameData[joint.rotationChannels.y],
                                        currFrameData[joint.rotationChannels.z]);
            Vector3 nextEuler = new Vector3(nextFrameData[joint.rotationChannels.x],
                                            nextFrameData[joint.rotationChannels.y],
                                            nextFrameData[joint.rotationChannels.z]);
            // calculate the quaternions based on the angles      
            Vector4 q1 = QuaternionUtils.FromEuler(currEuler, joint.rotationOrder);
            Vector4 q2 = QuaternionUtils.FromEuler(nextEuler, joint.rotationOrder);

            // Slerp
            Vector4 qInterpolated = QuaternionUtils.Slerp(q1, q2, t);
            // Rotation matrix
            R = MatrixUtils.RotateFromQuaternion(qInterpolated);
        }

        Matrix4x4 M = T * R * S;
        Matrix4x4 multiplication = parentTransform * M;
        MatrixUtils.ApplyTransform(joint.gameObject, multiplication);
        
        foreach (BVHJoint child in joint.children)
        {
            //if (!child.isEndSite) 
            TransformJoint(child, multiplication);
        }
    }

    // Returns the frame number of the BVH animation at a given time
    public int GetFrameNumber(float time)
    {
        return (int)(time / data.frameLength) % data.numFrames;
    }

    // Returns the proportion of time elapsed between the last frame and the next one, between 0 and 1
    public float GetFrameIntervalTime(float time)
    {
        int currFrame = GetFrameNumber(time);
        float currFrameTime = currFrame * data.frameLength;
        float nextFrameTime = (currFrame + 1) * data.frameLength;
        return (time - currFrameTime) / (nextFrameTime - currFrameTime);
    }

    // Update is called once per frame
  void Update()
    {
        if (animate && !wasAnimating)
        {
            // Reset animation to start
            animTime = 0f;
            t = 0f;

            currFrameData = data.keyframes[0];
            nextFrameData = data.keyframes[1 % data.numFrames];

            TransformJoint(data.rootJoint, Matrix4x4.identity);
        }

        wasAnimating = animate;

        if (animate)
        {
            // Advance our private animation time 
            animTime += Time.deltaTime * animationSpeed;

            int currFrame = GetFrameNumber(animTime);
            currFrameData = data.keyframes[currFrame];

            if (currFrame < data.numFrames - 1)
                nextFrameData = data.keyframes[currFrame + 1];
            else
                nextFrameData = data.keyframes[0];

            t = Mathf.Clamp01(GetFrameIntervalTime(animTime));

            TransformJoint(data.rootJoint,  Matrix4x4.identity);
        }
    }

}
