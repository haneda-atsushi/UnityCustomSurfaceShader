Shader "Custom/Surface/LightmapDecode"
{
    // Surface Shader Lighting Examples
    // http://docs.unity3d.com/Manual/SL-SurfaceShaderLightingExamples.html
    Properties
    {
        _MainTex ( "Texture", 2D ) = "white" {}
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" }
        CGPROGRAM

#pragma surface surf BlinnPhong

        half4 LightingStandard( SurfaceOutput s, half3 lightDir, half atten )
        {
            half NdotL = dot ( s.Normal, lightDir );
            half4 c; c.rgb = s.Albedo * _LightColor0.rgb * ( NdotL * atten );
            c.a = s.Alpha;
            return c;
        }

        inline fixed4 LightingStandard_SingleLightmap( SurfaceOutput s, fixed4 color )
        {
            half3 lm = DecodeLightmap ( color );
            return fixed4 ( lm, 0 );
        }

        inline fixed4 LightingStandard_DualLightmap( SurfaceOutput s, fixed4 totalColor, fixed4 indirectOnlyColor, half indirectFade )
        {
            half3 lm = lerp ( DecodeLightmap ( indirectOnlyColor ), DecodeLightmap ( totalColor ), indirectFade );
            return fixed4 ( lm, 0 );
        }

        inline fixed4 LightingStandard_DirLightmap( SurfaceOutput s, fixed4 color, fixed4 scale, bool surfFuncWritesNormal )
        {
            UNITY_DIRBASIS

            half3 lm = DecodeLightmap ( color );
            half3 scalePerBasisVector = DecodeLightmap ( scale );

            if ( surfFuncWritesNormal )
            {
                half3 normalInRnmBasis = saturate ( mul ( unity_DirBasis, s.Normal ) );
                lm *= dot ( normalInRnmBasis, scalePerBasisVector );
            }

            return fixed4 ( lm, 0 );
        }

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _MainTex;
        void surf ( Input IN, inout SurfaceOutput o )
        {
            o.Albedo = tex2D ( _MainTex, IN.uv_MainTex ).rgb;
        }
        ENDCG
    }

    Fallback "Diffuse"
}