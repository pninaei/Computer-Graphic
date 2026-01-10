Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
                uniform float _BumpScale;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float2 uv       : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 normal   : NORMAL;
                    float3 tangent  : TANGENT;
            
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    return perlin3d(float3(0.5 * uv.x , 0.5 * uv.y, 0.5 * t)) + (0.5 * perlin3d(float3(uv.x, uv.y, t))) + (0.2 * perlin3d(float3(2 * uv.x, 2 * uv.y, 3 * t)));
            
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    // slope in the v direction
                    // f_v’(p) ≈ [f(p + dv) – f(p)] / dv
                    float slope_v = (waterNoise(i.uv + float2(0, i.dv), t) - waterNoise(i.uv, t)) / i.dv;
                    fixed3 t_v = float3(0, 1, slope_v * i.bumpScale);

                    // slope in the u direction
                    // this is the formula f_u’(p) ≈ [f(p + du) – f(p)] / du
                    float slope_u = (waterNoise(i.uv + float2(i.du, 0), t) - waterNoise(i.uv, t)) / i.du;
                    fixed3 t_u = float3(1, 0, slope_u * i.bumpScale);
                    
                    // n_h = cross(t_u, t_v)
                    float3 n_h = cross(t_u, t_v);
                    n_h = normalize(n_h);

                    // t and n to world space
                    float3 worldTangent = normalize(i.tangent);
                    float3 worldNormal = normalize(i.normal);

                    // b = cross(n, t)
                    float3 worldBitangent = normalize(cross(worldNormal, worldTangent));

                    // n_world = world space normal
                    float3 n_world = n_h.x * worldTangent  + n_h.z * worldNormal + n_h.y * worldBitangent;
                    return normalize(n_world);
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    float2 uv = _NoiseScale * input.uv;
                    output.uv = uv;
                    
                    float waterNoiseValue = waterNoise(uv, _Time.y * _TimeScale);
                    float3 pTag = input.vertex.xyz + (input.normal * waterNoiseValue) * _BumpScale; // as we see in TA5 p’ = p + hn
                    output.pos = UnityObjectToClipPos(float4(pTag, 1));
                    output.worldPos = mul(unity_ObjectToWorld, float4(pTag, 1)).xyz;
                    output.normal = mul((float3x3)unity_ObjectToWorld, input.normal); 
                    output.tangent = mul(unity_ObjectToWorld, input.tangent);
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float2 uv = _NoiseScale * input.uv;
                    float waterNoiseValue = waterNoise(uv,  _Time.y * _TimeScale);                    

                    bumpMapData BumpMapData;
                    BumpMapData.normal = input.normal;
                    BumpMapData.tangent = input.tangent;
                    BumpMapData.uv = input.uv;
                    BumpMapData.du = DELTA;
                    BumpMapData.dv = DELTA;
                    BumpMapData.bumpScale = _BumpScale;
                    
                    float3 bumpNormal = getWaterBumpMappedNormal(BumpMapData, _Time.y * _TimeScale);
                    
                    // from TA5 - r = 2(v · n)n – v
                    float3 view = normalize(_WorldSpaceCameraPos - input.worldPos); // v
                    float3 r = (2 * dot(view, bumpNormal) * bumpNormal) - view;
                    float4 ReflectionColor = texCUBE(_CubeMap, r);
                    float4 color = (1 - max(0, dot(bumpNormal, view)) + 0.2) * ReflectionColor;
                    return color;
                }

            ENDCG
        }
    }
}
