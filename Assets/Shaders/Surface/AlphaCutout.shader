Shader "Custom/Surface/AlphaCutout"
{
	Properties
    {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Cutoff( "Alpha cutoff", Range( 0, 1 ) ) = 0.5
        [Enum(Back,2,Off,0,Front,1)] _Cull( "CullMode", Float ) = 2
	}

	SubShader {
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="true" "RenderType"="TransparentCutout" }
		LOD 200
        Cull[_Cull]

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
        // fullforwardshadows : Support all light shadow types in forward rendering
        // addshadow          : Need to cast proper shadow with alphatest
        #pragma surface surf Standard fullforwardshadows alphatest:_Cutoff addshadow
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
        {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;

			// Metallic and smoothness come from slider variables
			o.Metallic   = 0.0;
			o.Smoothness = 0.0;
			o.Alpha      = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
