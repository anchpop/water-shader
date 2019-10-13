// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Per pixel bumped refraction.
// Uses a normal map to distort the image behind, and
// an additional texture to tint the color.

Shader "FX/Glass/Stained BumpDistort" {
	Properties{
		_Bump1Amt("Distortion1", range(0,128)) = 10
		_Bump1Scl("Scale1", range(.05,20)) = 1
		_X1Off("X1", range(.01,1)) = 0
		_Y1Off("Y1", range(.01,1)) = 0
		_Speed1Amt("Speed1", range(0,10)) = 1


		_Bump1DScl("Scale1D", range(.05,20)) = 1
		_X1DOff("X1D", range(.01,1)) = 0
		_Y1DOff("Y1D", range(.01,1)) = 0
		_Speed1DAmt("Speed1D", range(0,10)) = 1

		_BumpMap("Normalmap", 2D) = "bump" {}
		_NoiseMap("Texture Noise", 2D) = "noise" {}
	}

		Category{

		// We must be transparent, so other objects are drawn before this one.
		Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }


		SubShader {

		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _GrabTexture
		GrabPass {
			Name "BASE"
			Tags { "LightMode" = "Always" }
		}

		// Main pass: Take the texture grabbed above and use the bumpmap to perturb it
		// on to the screen
		Pass {
			Name "BASE"
			Tags { "LightMode" = "Always" }

CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"

struct appdata_t {
	float4 vertex : POSITION;
	float2 texcoord: TEXCOORD0;
};

struct v2f {
	float4 vertex  : POSITION;
	float4 uvgrab  : TEXCOORD0;
	float2 uvbump  : TEXCOORD1;
	float2 uvmain  : TEXCOORD2;
};

float _Bump1Amt;
float _Bump1Scl;
float _X1Off;
float _Y1Off;
float _Speed1Amt;

float _Bump1DScl;
float _X1DOff;
float _Y1DOff;
float _Speed1DAmt;

float4 _BumpMap_ST;
float4 _NoiseMap_ST;

v2f vert(appdata_t v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
	#else
	float scale = 1.0;
	#endif
	o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
	o.uvgrab.zw = o.vertex.zw;
	o.uvbump = TRANSFORM_TEX(v.texcoord, _BumpMap);
	return o;
}

sampler2D _GrabTexture;
float4 _GrabTexture_TexelSize;
sampler2D _BumpMap;
sampler2D _MainTex;
sampler2D _NoiseMap;

half4 frag(v2f i) : COLOR
{
	// calculate perturbed coordinates
	float magnitude = sqrt(pow( _X1Off, 2) + pow(_Y1Off, 2));
	half2 bump1 = UnpackNormal(tex2D(_BumpMap, float2(-_X1Off, -_Y1Off) / magnitude * _Time * _Speed1Amt + i.uvbump / _Bump1Scl)).rg; // we could optimize this by just reading the x & y without reconstructing the Z
	float2 offset1 = bump1 * _Bump1Amt * _GrabTexture_TexelSize.xy;
	i.uvgrab.xy = offset1 * i.uvgrab.z + i.uvgrab.xy;

	half4 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.uvgrab));
	half4 noise = tex2D(_NoiseMap, UNITY_PROJ_COORD(i.uvgrab) / _Bump1DScl);
	return col * noise;
}
ENDCG
		}
	}

		// ------------------------------------------------------------------
		// Fallback for older cards and Unity non-Pro

		SubShader {
			Blend DstColor Zero
			Pass {
				Name "BASE"
				SetTexture[_MainTex] {	combine texture }
			}
		}
	}

}