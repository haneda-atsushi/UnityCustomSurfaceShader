Shader "Custom/Surface/NormalMap"
{
	Properties
    {
        _NormalTex ( "NormalMap", 2D ) = "bump" {}
        _NormalIntensity ( "Normal intensity", Range ( 0,8 ) ) = 1.0
	}
	SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

        sampler2D _NormalTex;
        float _NormalIntensity;

        struct Input
        {
            float2 uv_NormalTex;
        };

        void surf ( Input IN, inout SurfaceOutputStandard o )
        {
            float3 bump_normal = 
                UnpackNormal( tex2D( _NormalTex, IN.uv_NormalTex ) );
            bump_normal.x *= _NormalIntensity;
            bump_normal.y *= _NormalIntensity;
            bump_normal    = normalize( bump_normal );
            o.Normal       = bump_normal;
            o.Albedo       = float3( 0.5, 0.5, 0.5 );
        }
        ENDCG
    }
    FallBack "Diffuse"
}
