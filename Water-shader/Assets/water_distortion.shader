// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Per pixel bumped refraction.
// Uses a normal map to distort the image behind, and
// an additional texture to tint the color.

Shader "FX/Glass/Stained BumpDistort" {
	Properties{
		_Bump1Amt("Distortion1", range(0,128)) = 10
		_Bump1Scl("Scale1", range(.05,20)) = 1
		_X1Off("X1", range(-1,1)) = 0
		_Y1Off("Y1", range(-1,1)) = 0
		_Speed1Amt("Speed1", range(0,10)) = 1


		_ThresholdAmt("Threshold", range(0,1)) = .5
		_ThresholdBrightening("brightening", range(0,1)) = .5


		_Bump1DScl("Scale1D", range(.05,20)) = 1
		_X1DOff("X1D", range(-1,1)) = 0
		_Y1DOff("Y1D", range(-11,1)) = 0
		_Speed1DAmt("Speed1D", range(0,10)) = 1


		_Bump2DScl("Scale2D", range(.05,20)) = 1
		_X2DOff("X2D", range(-1,1)) = 0.01
		_Y2DOff("Y2D", range(-1,1)) = 0.01
		_Speed2DAmt("Speed2D", range(0,10)) = 1

		_BumpMap("Normalmap", 2D) = "bump" {}
		_Noise1Map("Texture Noise 1", 2D) = "noise1" {}
		_Noise2Map("Texture Noise 2", 2D) = "noise2" {}
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

float _ThresholdAmt;
float _ThresholdBrightening;

float _Bump1DScl;
float _X1DOff;
float _Y1DOff;
float _Speed1DAmt;

float _Bump2DScl;
float _X2DOff;
float _Y2DOff;
float _Speed2DAmt;

float4 _BumpMap_ST;
float4 _Noise1Map_ST;

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
sampler2D _Noise1Map;
sampler2D _Noise2Map;

half4 frag(v2f i) : COLOR
{
	// calculate perturbed coordinates
	float magnitude1  = sqrt(pow(_X1Off, 2) + pow(_Y1Off, 2));
	float magnitude1D = sqrt(pow(_X1DOff, 2) + pow(_Y1DOff, 2));
	float magnitude2D = sqrt(pow(_X2DOff, 2) + pow(_Y2DOff, 2));



	half2 bump1 = UnpackNormal(tex2D(_BumpMap, float2(-_X1Off, -_Y1Off) / magnitude1 * _Time.y * _Speed1Amt + i.uvbump / _Bump1Scl)).rg; // we could optimize this by just reading the x & y without reconstructing the Z
	float2 offset1 = bump1 * _Bump1Amt * _GrabTexture_TexelSize.xy;
	i.uvgrab.xy = offset1 * i.uvgrab.z + i.uvgrab.xy;


	half4 noise1 = tex2D(_Noise1Map, float2(-_X1DOff, -_Y1DOff) / magnitude1D * _Time.y * (_Speed1DAmt / 8) + UNITY_PROJ_COORD(i.uvgrab) / _Bump1DScl);
	half4 noise2 = tex2D(_Noise2Map, float2(-_X2DOff, -_Y2DOff) / magnitude2D * _Time.y * (_Speed2DAmt / 8) + UNITY_PROJ_COORD(i.uvgrab) / _Bump2DScl);

	float noiseCombined = noise1.x * noise2.x;
	bool noiseStepped = step(_ThresholdAmt, noise1.x * noise2.x);

	half4 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.uvgrab));
	return lerp(col, lerp(col, float4(1, 1, 1, 1), _ThresholdBrightening * noiseCombined), noiseStepped);
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