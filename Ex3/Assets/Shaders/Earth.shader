Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"

                // Declare used properties
                uniform sampler2D _AlbedoMap;
                uniform float _Ambient;
                uniform sampler2D _SpecularMap;
                uniform float _Shininess;
                uniform sampler2D _HeightMap;
                uniform float4 _HeightMap_TexelSize;
                uniform float _BumpScale;
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                   // float2 uv  : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 objectPos : TEXCOORD2;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz; // world position
                    output.objectPos = input.vertex.xyz; // object position
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    float2 uv = getSphericalUV(normalize(input.objectPos));
                    float3 n = normalize(input.worldPos); // normal for sphere
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPos); // view
                    float3 l = _WorldSpaceLightPos0.xyz;  // light
                    
                    bumpMapData BumpMapData;
                    BumpMapData.normal = n;
                    BumpMapData.tangent = cross(n, float3(0, 1, 0)); // tangent vector
                    BumpMapData.uv = uv;
                    BumpMapData.heightMap = _HeightMap;
                    BumpMapData.du = _HeightMap_TexelSize.x;
                    BumpMapData.dv = _HeightMap_TexelSize.y;
                    BumpMapData.bumpScale = _BumpScale / 10000.0;

                    half4 albedo = tex2D(_AlbedoMap, uv);
                    half4 specularity = tex2D(_SpecularMap, uv);
                    
                    float3 bumpMappedNormal = getBumpMappedNormal(BumpMapData);                     
                    float3 finalNormal = (1- specularity) * bumpMappedNormal + specularity * n;
                    
                    fixed3 blinn = blinnPhong(finalNormal, v, l, _Shininess, albedo, specularity, _Ambient);
                    
                    fixed4 color = fixed4(blinn, 1.0);
                    
                    // atmosphere part
                    float Lambert = max(0, dot(n, l));
                    fixed4 atmosphere = (1-max(0, dot(n, v))) * sqrt(Lambert) * _AtmosphereColor;
                    half4 cloud = tex2D(_CloudMap, uv);
                    fixed4 clouds = cloud * (sqrt(Lambert) + _Ambient);

                    return color + atmosphere + clouds;
                }

            ENDCG
        }
    }
}
