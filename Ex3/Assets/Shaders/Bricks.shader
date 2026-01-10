Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(-100, 100)) = 40
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

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv  : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                    output.normal = mul((float3x3)unity_ObjectToWorld, input.normal);
                    output.tangent = mul(unity_ObjectToWorld, input.tangent);
                    output.uv = input.uv;

                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {
                    
                    
                    bumpMapData BumpMapData;

                    BumpMapData.normal = input.normal;
                    BumpMapData.tangent = input.tangent;
                    BumpMapData.uv = input.uv;
                    BumpMapData.heightMap = _HeightMap;
                    BumpMapData.du = _HeightMap_TexelSize.x;
                    BumpMapData.dv = _HeightMap_TexelSize.y;
                    BumpMapData.bumpScale = _BumpScale / 10000.0;
                    
            
                    half4 albedo = tex2D(_AlbedoMap, input.uv);
                    half4 specularity = tex2D(_SpecularMap, input.uv);

                    float3 normalizeN = getBumpMappedNormal(BumpMapData); // normal that computed from bump map
                    float3 view = normalize(_WorldSpaceCameraPos - input.worldPos); // v
                    float3 light = _WorldSpaceLightPos0.xyz;  // l
                    fixed3 blinn = blinnPhong(normalizeN, view, light, _Shininess, albedo, specularity, _Ambient);
                    fixed4 color = fixed4(blinn, 1.0);
                    return color;
                }

            ENDCG
        }
    }
}
