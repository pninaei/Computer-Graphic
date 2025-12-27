Shader "CG/BlinnPhongGouraud"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (0.14, 0.43, 0.84, 1)
        _SpecularColor ("Specular Color", Color) = (0.7, 0.7, 0.7, 1)
        _AmbientColor ("Ambient Color", Color) = (0.05, 0.13, 0.25, 1)
        _Shininess ("Shininess", Range(0.1, 50)) = 10
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
                #include "Lighting.cginc"

                // Declare used properties
                uniform fixed4 _DiffuseColor;
                uniform fixed4 _SpecularColor;
                uniform fixed4 _AmbientColor;
                uniform float _Shininess;

                struct appdata
                { 
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR0;

                };


                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    fixed4 colorD;
                    fixed4 colorS;
                    fixed4 colorA;
                    // ambient component
                    colorA = _AmbientColor * _LightColor0;
                  
                    // diffuse component
                    // dot product of normal and light direction
                    float3 light = normalize(_WorldSpaceLightPos0.xyz); 
                    float dotDiffuse = dot(light , input.normal); // l * n 
                    float maximumDiffuse = max(0, dotDiffuse);
                    colorD = maximumDiffuse * _DiffuseColor * _LightColor0 ; // diffuse component
                     
                    // specular component
                    // dot product of normal and half vector
                    float3 worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                    
                    float3 view = normalize(_WorldSpaceCameraPos - worldPos); // this is v in TA terms
                    float3 halfVector = normalize(light + view); // h = (l + v)/ ||l + v||
                    
                    float dotSpecular = dot(input.normal, halfVector); // n * h
                    float maximumSpecular = pow(max(0, dotSpecular), _Shininess);
                    colorS = maximumSpecular * _SpecularColor * _LightColor0 ; // specular component
                    output.color = colorA + colorD + colorS;
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {
                    return input.color;
                }

            ENDCG
        }
    }
}
