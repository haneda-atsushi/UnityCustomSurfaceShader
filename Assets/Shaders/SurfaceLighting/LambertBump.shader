Shader "Custom/SurfaceLighting/LambertBump"
{
	Properties
    {
        _BaseColor ( "BaseColor", Color ) = ( 1,1,1,1 )
        _MainTex ( "Albedo (RGB)", 2D ) = "white" {}
        _NormalMap ( "Normal Map", 2D ) = "bump" {}
	}

	SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM

        // exclude_path : Do not generate passes for given rendering path.
        // noforwardadd : Disables Forward rendering additive pass. 
        //                This makes the shader support one full directional light,
        //                with all other lights computed per-vertex/SH.
		#pragma surface surf MyLambert exclude_path:prepass noforwardadd 

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

        fixed4 _BaseColor;
        sampler2D _MainTex;
        sampler2D _NormalMap;

		struct Input
        {
            half2 uv_MainTex;
		};

        void surf( Input IN, inout SurfaceOutput o )
        {
            half2 uv0         = IN.uv_MainTex;

            fixed4 base_color = tex2D(_MainTex, uv0 );
            o.Albedo          = base_color.rgb * _BaseColor.rgb;
            o.Alpha           = base_color.a;

            o.Normal          = UnpackNormal( tex2D( _NormalMap, uv0 ) );
        }

        fixed4 LightingMyLambert( SurfaceOutput s, fixed3 light_dir, fixed atten )
        {
            float3 normal = normalize ( s.Normal );
            fixed dot_n_l = saturate( dot( normal, light_dir ) );

            fixed4 color;
            color.rgb    = s.Albedo * _LightColor0.rgb * ( dot_n_l * atten );
            color.a      = s.Alpha;

            return color;
        }

		ENDCG
	}
	FallBack "Diffuse"
}
