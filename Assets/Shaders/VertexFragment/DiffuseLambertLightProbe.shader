// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/DiffuseLambertLightProbe"
{
    Properties
    {
        [NoScaleOffset] _MainTex( "Texture", 2D ) = "white" {}
    }

    CGINCLUDE
#define ENABLE_PIXEL_LIGHTING 1
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
    ENDCG

    SubShader
    {
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM
#pragma vertex vert
#pragma fragment frag

            struct v2f
            {
                float2 uv   : TEXCOORD0;

#ifdef ENABLE_PIXEL_LIGHTING
                float3 worldNormal : TEXCOORD1;
#else
                float4 diff : COLOR0;
#endif

                float4 vertex : SV_POSITION;
            };

            v2f vert ( appdata_base v )
            {
                v2f o;
                o.vertex          = UnityObjectToClipPos ( v.vertex );
                o.uv              = v.texcoord;
                float3 worldNormal = UnityObjectToWorldNormal ( v.normal );

#ifdef ENABLE_PIXEL_LIGHTING
                o.worldNormal      = worldNormal;
#else
                // Diffuse lambert in vertex shader
                float nl           = max ( 0, dot ( worldNormal, _WorldSpaceLightPos0.xyz ) );
                o.diff             = nl * _LightColor0;

                // Evaluate light probe in vertex shader
                o.diff.rgb       += ShadeSH9( float4( worldNormal, 1 ) );
#endif

                return o;
            }

            sampler2D _MainTex;
            float4 frag ( v2f i ) : SV_Target
            {
                float4 result     = float4( 0, 0, 0, 1 );
                float4 base_color = tex2D ( _MainTex, i.uv );

#if ( ENABLE_PIXEL_LIGHTING )
                float3 worldNormal = normalize( i.worldNormal );
                float nl           = max( 0, dot( worldNormal, _WorldSpaceLightPos0.xyz ) );

                float3 diffuse_lighting;
                diffuse_lighting   = nl * _LightColor0;

                // Evaluate light probe in vertex shader
                diffuse_lighting  += ShadeSH9( float4( worldNormal, 1 ) );

                result.rgb = diffuse_lighting.rgb * base_color.rgb;
#else
                result.rgb = i.diff * base_color.rgb;
#endif

                return result;
            }
            ENDCG
        }
    }
}