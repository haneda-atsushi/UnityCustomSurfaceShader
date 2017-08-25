Shader "Custom/Surface/Transparent"
{
	Properties
    {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        _AlphaScale ( "AlphaScale", Range ( 0, 16 ) ) = 8.0
	}

	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="true" "RenderType"="Transparent" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows alpha:blend

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
        {
			float2 uv_MainTex;
		};

        fixed  _AlphaScale;

		void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;

			// Metallic and smoothness come from slider variables
			o.Metallic   = 0.0;
			o.Smoothness = 0.0;
			o.Alpha      = saturate ( c.a * _AlphaScale );
		}
		ENDCG
	}
	FallBack "Diffuse"
}
