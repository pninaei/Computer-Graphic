Shader "CG/BlinnPhong"
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
                    float3 normal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                };

                // Calculates diffuse lighting of secondary point lights (part 3)
                fixed4 pointLights(v2f input)
                {
                    fixed4 colorD = 0;
                    for (int i = 0; i < 4; i++){ //run over all the four lights
                        float3 lightPos = float3(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i]);
                        // diffuse component
                        // dot product of normal and light direction
                        float3 normalizeN = normalize(input.normal);
                        float3 light = normalize(lightPos - input.worldPos); // this is the light position relative to pixel
                        float dotDiffuse = dot(light , normalizeN); // l * n 
                        float maximumDiffuse = max(0, dotDiffuse);
                        
                        float d = distance(lightPos, input.worldPos);
                        fixed4 intensity = 1.0 / (1.0 + (unity_4LightAtten0[i] * d * d)); // calculate intensity according 1/ 1+ alpha * d^2
                        colorD += maximumDiffuse * _DiffuseColor * unity_LightColor[i] * intensity; // diffuse component
                    }
                    return colorD;
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                    output.normal = normalize(mul((float3x3)unity_ObjectToWorld, input.normal));
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {
                    fixed4 colorD;
                    fixed4 colorS;
                    fixed4 colorA;
                    // ambient component
                    colorA = _AmbientColor * _LightColor0;
                  
                    // diffuse component
                    // dot product of normal and light direction
                    float3 normalizeN = normalize(input.normal);
                    float3 light = normalize(_WorldSpaceLightPos0.xyz); 
                    float dotDiffuse = dot(light , normalizeN); // l * n 
                    float maximumDiffuse = max(0, dotDiffuse);
                    colorD = maximumDiffuse * _DiffuseColor * _LightColor0 ; // diffuse component
                     
                    // specular component
                    // dot product of normal and half vector
                    float3 view = normalize(_WorldSpaceCameraPos - input.worldPos); // this is v in TA terms
                    float3 halfVector = normalize(light + view); // h = (l + v)/ ||l + v||
                    
                    float dotSpecular = dot(normalizeN, halfVector); // n * h
                    float maximumSpecular = pow(max(0, dotSpecular), _Shininess);
                    colorS = maximumSpecular * _SpecularColor * _LightColor0 ; // specular component;
                    return colorA + colorD + colorS + pointLights(input);
                }

            ENDCG
        }
    }
}
