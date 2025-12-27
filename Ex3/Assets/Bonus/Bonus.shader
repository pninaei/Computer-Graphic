Shader "CG/Bonus"
{
    Properties
    {
        _BumpScale ("Bump Scale", Float) = 0.06
        _Shininess ("Shininess", Range(0.1, 150)) = 120
        _MeltAmount ("Melt Amount", Range(0, 3)) = 0.0
        [NoScaleOffset] _Cube ("Environment Cube Map", CUBE) = "" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGRandom.cginc"
                #include "CGUtils.cginc"

                // Declare used properties
                uniform float _BumpScale;
                uniform samplerCUBE _Cube;
                uniform float _MeltAmount;
                uniform float _Shininess;


                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float3 worldPos : TEXCOORD0;
                    float3 normal   : NORMAL;
                    float3 tangent  : TANGENT;
                };
                
                // Function to generate 3D Perlin noise
                float iceNoise(float3 p, float t)
                {
                    return perlin3d(float3(p.x, p.y, p.z + t));
                }

                // Function to generate layered 3D noise of multiple 
                //frequencies to simulate ice texture 
                float layeredNoise3d(float3 p)
                {
                    float f = 0;
                    float a = 0.25;
                    f += a * perlin3d(p);  
                    p *= 2.02;
                    a *= 0.5;
                    f += a * perlin3d(p);  
                    p *= 2.03; 
                    a *= 0.5;
                    f += a * perlin3d(p);  
                    p *= 2.01; 
                    a *= 0.5;
                    f += a * perlin3d(p);
                    return f;
                }

                
                // Returns a bump-mapped normal using noise instead of heightMap
                float3 getIceBumpMappedNormal(bumpMapData i, float3 worldPos)
                {
                    float3 p = worldPos * 8.0;   // high frequency frost
                                    
                    float h0 = layeredNoise3d(p);
                    float hU = layeredNoise3d(p + float3(i.du * 8.0, 0, 0));
                    float hV = layeredNoise3d(p + float3(0, i.dv * 8.0, 0));

                    float slope_u = (hU - h0) / i.du;
                    float slope_v = (hV - h0) / i.dv;

                    fixed3 t_u = float3(1, 0, slope_u * i.bumpScale);
                    fixed3 t_v = float3(0, 1, slope_v * i.bumpScale);

                    float3 n_h = normalize(cross(t_u, t_v));
                    float3 worldTangent = normalize(i.tangent);
                    float3 worldNormal = normalize(i.normal);
                    float3 worldBitangent = normalize(cross(worldNormal, worldTangent));

                    float3 n_world = n_h.x * worldTangent + n_h.y * worldBitangent + n_h.z * worldNormal;
                    return normalize(n_world);
                }



                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;  
                    output.normal = mul((float3x3)unity_ObjectToWorld, input.normal);
                    output.tangent = mul((float3x3)unity_ObjectToWorld, input.tangent.xyz);
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {             
                    bumpMapData BumpMapData;
                    BumpMapData.normal = input.normal;
                    BumpMapData.tangent = input.tangent;
                    BumpMapData.du = 0.05;
                    BumpMapData.dv = 0.05;
                    BumpMapData.bumpScale = _BumpScale;
                    
                    float3 iceBumpNormal = getIceBumpMappedNormal(BumpMapData, input.worldPos);
                   
                    float3 view = normalize(_WorldSpaceCameraPos - input.worldPos); // v
                    float3 r = (2 * dot(view, iceBumpNormal) * iceBumpNormal) - view; // reflection vector
                    float3 l = _WorldSpaceLightPos0.xyz;  // light
                    
                    float3 whiteColor = float3(1.0, 1.0, 1.0);
                    float3 ReflectionColor = texCUBE(_Cube, r).rgb * 0.6;
                                       
                    float3 iceColor = float3(0.6, 0.8, 1.0);   // light blue color
                    float noiseValue = iceNoise(input.worldPos, _Time.y * 0.5); // make the ice "move"
                    float fog = noiseValue * 0.5 + 0.5; // map from [-1,1] to [0,1]
                    float3 cloudyColor = lerp(iceColor, whiteColor, fog * 0.02); // blend between iceColor and white based on fog
                    fixed4 albedo = fixed4(cloudyColor, 1.0);
                    
                    fixed3 blinn = blinnPhong(iceBumpNormal, view, l, _Shininess, albedo, fixed4(whiteColor, 1.0), 0.2);
                    
                    float drip = layeredNoise3d(input.worldPos * 10.0 + float3(0, -_Time.y * 0.5, 0)); // make the ice "melt slowly"
                    float transparency = 0.3 + (fog * 0.2);
                    transparency -= drip * _MeltAmount * 0.2; 
                    return fixed4(blinn + ReflectionColor, transparency);
                }

            ENDCG
        }
    }
}
