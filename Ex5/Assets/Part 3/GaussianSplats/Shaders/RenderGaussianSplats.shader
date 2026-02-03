// SPDX-License-Identifier: MIT
Shader "Gaussian Splatting/Render Splats"
{
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            ZWrite Off
            Blend OneMinusDstAlpha One
            Cull Off
            
			CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members cameraDist)
#pragma exclude_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			#pragma require compute
			#pragma use_dxc

			#include "GaussianSplatting.hlsl"

			struct v2f
			{
			    half4 col : COLOR0;
			    float2 pos : TEXCOORD0;
			    float4 vertex : SV_POSITION;
				float3 center: TEXCOORD2;
			};

			StructuredBuffer<uint> _OrderBuffer;
			StructuredBuffer<SplatViewData> _SplatViewData;
			ByteAddressBuffer _SplatSelectedBits;
			uint _SplatBitsValid;
			float4 _BoundsMin;
			float4 _BoundsMax;

			float getAnimationTime()
			{
				return frac(_Time.y * 0.25);
			}

			float3 animatePosition(float3 center) {
				float time = getAnimationTime();
				// TODO: implement animation. Make the splats that currently appear along the XZ plane pulsate outwards
				// a bit and return to their original position. Assume that the given splat `center` is in local space.
				// Hint: smoothstep is your best friend for writing effects! Test your formulas on https://graphtoy.com/
				// Lerp between the original values and effect values. 
			
				// Normalized Y position of the splat within the bounds 
				float normalizedY = (center.y - _BoundsMin.y) / (_BoundsMax.y - _BoundsMin.y);
				// current portal height
				float portalHeight = time * (_BoundsMax.y - _BoundsMin.y) + _BoundsMin.y;
				// Distance of this splat from the portal plane
				float distanceToPortal = abs(normalizedY - time);
				// Rolling window thickness
				float window = 0.5;
				// pulse: if the value is 1 we want movement (near the portal). if it's 0 we don't want any movement, and if between we want some movement 
				float pulse =  1.0- smoothstep(0.0, window, distanceToPortal);
				// Direction of movement: outward in XZ plane
				float3 outwardDir = normalize(float3(center.x, 0.0, center.z));
				// Pulse strength
				float amplitude = 0.1;
				// Offset in local space directly
    			float3 offsetLocal = outwardDir * pulse * amplitude;
				return center + offsetLocal;
			}

			v2f vert (uint vtxID : SV_VertexID, uint instID : SV_InstanceID)
			{
			    v2f o = (v2f)0;
			    instID = _OrderBuffer[instID];
				SplatViewData view = _SplatViewData[instID];

				float3 newCenterPos = animatePosition(view.pos.xyz);
				o.center = newCenterPos;
				
				float3 centerWorldPos = mul(unity_ObjectToWorld, float4(newCenterPos,1)).xyz;
				float4 centerClipPos = mul(UNITY_MATRIX_VP, float4(centerWorldPos, 1));
				
				bool behindCam = centerClipPos.w <= 0;
				
				if (behindCam)
				{
					o.vertex = asfloat(0x7fc00000); // NaN discards the primitive
				}
				else
				{
					o.col.r = f16tof32(view.color.x >> 16);
					o.col.g = f16tof32(view.color.x);
					o.col.b = f16tof32(view.color.y >> 16);
					o.col.a = f16tof32(view.color.y);

					uint idx = vtxID;
					float2 quadPos = float2(idx&1, (idx>>1)&1) * 2.0 - 1.0;
					quadPos *= 2;

					o.pos = quadPos;

					float2 deltaScreenPos = (quadPos.x * view.axis1 + quadPos.y * view.axis2) * 2 / _ScreenParams.xy;
					o.vertex = centerClipPos;
					float cameraDist = centerClipPos.w;
					
					o.vertex.xy += deltaScreenPos * cameraDist;

					// is this splat selected?
					if (_SplatBitsValid)
					{
						uint wordIdx = instID / 32;
						uint bitIdx = instID & 31;
						uint selVal = _SplatSelectedBits.Load(wordIdx * 4);

						if (selVal & (1 << bitIdx))
						{
							o.col.a = -1;				
						}
					}
				}
				FlipProjectionIfBackbuffer(o.vertex);
			    return o;
			}

			struct effect_result
			{
				half3 effectColor;
				float alpha;
			};

			effect_result calculateEffectColor(float3 center, float alpha, half3 color)
			{
				effect_result output;
				float time = getAnimationTime();
				// TODO: implement effect. A glowing red "portal" effect revealing the object along the XZ plane, from top to bottom.
				// Hint: smoothstep is your best friend for writing effects! Test your formulas on https://graphtoy.com/
				// Lerp between the original values and effect values.
				
				// Normalized Y position of the splat within the bounds 
				float normalizedY = (center.y - _BoundsMin.y) / (_BoundsMax.y - _BoundsMin.y);
				// thickness of the portal effect 
				float thickness = 0.01; 
	            // portal effect factor based on distance to the moving portal plane
				float portalEffect = smoothstep(time - thickness, time + thickness, normalizedY);
	            // glowing red color
				float3 redGlowing = float3(30.0f, 0.0f, 0.0f);
	            // combine the color for the red glowing effect
				output.effectColor = lerp(color, redGlowing, portalEffect);
				// reduce alpha to create a fading effect
				output.alpha = lerp(alpha, 0.0f, portalEffect);
				return output;
			}

			half4 frag (v2f i) : SV_Target
			{
				float power = -dot(i.pos, i.pos);
				half alpha = exp(power);
				if (i.col.a >= 0)
				{
					alpha = saturate(alpha * i.col.a);
				}
				else
				{
					// "selected" splat: magenta outline, increase opacity, magenta tint
					half3 selectedColor = half3(1,0,1);
					
					if (alpha > 7.0/255.0)
					{
						if (alpha < 10.0/255.0)
						{
							alpha = 1;
							i.col.rgb = selectedColor;
						}
						alpha = saturate(alpha + 0.3);
					}
					i.col.rgb = lerp(i.col.rgb, selectedColor, 0.5);
				}
				
			    if (alpha < 1.0/255.0)
			    {
				    discard;
			    }
				
				effect_result result = calculateEffectColor(i.center, alpha, i.col.rgb);
			    half4 res = half4(result.effectColor * result.alpha, result.alpha);
				
			    return res;
			}
			ENDCG
        }
    }
}
