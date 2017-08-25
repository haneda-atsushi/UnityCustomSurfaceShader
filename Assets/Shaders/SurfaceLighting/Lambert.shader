Shader "Custom/SurfaceLighting/Lambert"
{
	Properties
    {
        _BaseColor ( "BaseColor", Color ) = ( 1,1,1,1 )
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _LambertScale( "LambertScale", Range ( 0,1 ) ) = 0.0
	}

	SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

        // fullfowardshadows : Support all light shadow types in Forward rendering path
		#pragma surface surf MyLambert fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
        fixed4 _BaseColor;

		struct Input
        {
			float2 uv_MainTex;
		};

        half   _LambertScale;

		void surf(Input IN, inout SurfaceOutput o)
        {
			fixed4 base_color = tex2D( _MainTex, IN.uv_MainTex );
			o.Albedo          = base_color.rgb * _BaseColor.rgb;
			o.Alpha           = base_color.a;
		}

        half4 LightingMyLambert( SurfaceOutput s, half3 light_dir, half atten )
        {
            half dot_n_l = saturate( dot( s.Normal, light_dir ) ) * _LambertScale;

            half4 color;
            color.rgb = s.Albedo * _LightColor0.rgb * dot_n_l * atten;
            color.a   = s.Alpha;

            return color;
        }

		ENDCG
	}
	FallBack "Diffuse"
}
