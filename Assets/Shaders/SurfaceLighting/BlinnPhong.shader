Shader "Custom/SurfaceLighting/BlinnPhong"
{
	Properties
    {
        _SpecularColor ( "SpecularColor", Color ) = ( 1,1,1,1 )
		_SpecularPow("SpecularPow", Range ( 1.0,1024 ) ) = 4
        //
        //_Glossiness ( "Smoothness", Range ( 0,1 ) ) = 0.5
        //_Metallic ( "Metallic", Range ( 0,1 ) ) = 0.0
        //_LambertScale( "LambertScale", Range ( 0,1 ) ) = 1.0
	}

	SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

		// Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf MyBlinnPhong fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
        {
			float2 uv_MainTex;
		};

		fixed4 _SpecularColor;
        half   _SpecularPow;

		void surf (Input IN, inout SurfaceOutput o)
        {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;

			// o.Metallic   = _Metallic;
			// o.Smoothness = _Glossiness;
			o.Alpha      = c.a;
		}

        float4 LightingMyBlinnPhong( SurfaceOutput s, float3 light_dir, float3 view_dir, float atten )
        {
            float3 normal = normalize ( s.Normal );
            float  dot_n_l           = saturate( dot( normal, light_dir ) );
            float3 h_vec             = normalize( light_dir + view_dir );
            float  dot_n_h           = saturate( dot( normal, h_vec ) );
            float3 specular_lighting = pow( dot_n_h, _SpecularPow ) * _SpecularColor;

            float4 color;
            color.rgb = specular_lighting * _LightColor0.rgb * dot_n_l * atten;
            color.a   = s.Alpha;

            return color;
        }

		ENDCG
	}
	FallBack "Diffuse"
}
