Shader "Custom/Surface/VertexAnimation"
{
	Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Speed( "Wave speed", Range( 0.1, 200 ) )        = 100
        _Frequency( "Wave frequency", Range ( 0, 64 ) )  = 10
        _Amplitude( "Wave amplitude", Range ( -1, 1 ) )  = 0.2

        _Glossiness ( "Smoothness", Range ( 0,1 ) ) = 1.0
        _Metallic ( "Metallic", Range ( 0,1 ) )     = 1.0
	}

    SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
        {
			float2 uv_MainTex;
		};

        half   _Glossiness;
        half   _Metallic;

        half   _Speed;
        half   _Amplitude;
        half   _Frequency;

        void vert( inout appdata_full v, out Input o )
        {
            UNITY_INITIALIZE_OUTPUT( Input, o );

            float time     = _Time      * _Speed;
            float wave_amp = _Amplitude * sin( time + ( v.vertex.x + v.vertex.z ) * _Frequency );

            v.vertex.xyz   = float3( v.vertex.x, v.vertex.y, v.vertex.z ) +
                             wave_amp * float3( 0.0, 1.0, 0.0 );
            // TODO : Calc correct normal
            v.normal     = normalize( v.normal.xyz );
        }

        void surf ( Input IN , inout SurfaceOutputStandard o )
        {
			half4 base_color = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo         = base_color.rgb;
			o.Alpha          = 1.0;

            o.Metallic       = _Metallic;
            o.Smoothness     = _Glossiness;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
