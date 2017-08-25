Shader "Custom/Surface/SimpleSurface"
{
	Properties
    {
        _BaseColor( "BaseColor", Color ) = ( 1,1,1,1 )
        _Glossiness ( "Smoothness", Range ( 0,1 ) ) = 0.5
        _Metallic ( "Metallic", Range ( 0,1 ) ) = 0.0
	}

	SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

        // fullfowardshadows : Support all light shadow types in Forward rendering path
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        fixed4 _BaseColor;
        half   _Glossiness;
        half   _Metallic;

        sampler2D _MainTex;
        struct Input
        {
            float2 uv_MainTex;
        };

		void surf( Input IN, inout SurfaceOutputStandard o )
        {
			o.Albedo          = _BaseColor.rgb;
			o.Alpha           = _BaseColor.a;
            o.Metallic        = _Metallic;
            o.Smoothness      = _Glossiness;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
