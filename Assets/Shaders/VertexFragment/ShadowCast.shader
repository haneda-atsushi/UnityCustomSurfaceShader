// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/ShadowCast"
{
    Properties
    {
        _Color( "Color", Color ) = ( 1,1,1,1 )
    }

    CGINCLUDE
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
    ENDCG

    SubShader
    {
        // very simple lighting pass, that only does non-textured ambient
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
#pragma vertex vert
#pragma fragment frag

            float4 _Color = float4( 1, 1, 1, 1 );

            struct v2f
            {
                float3 worldNormal : TEXCOORD0;
                float4 vertex      : SV_POSITION;
            };

            v2f vert ( appdata_base v )
            {
                v2f o;
                o.vertex      = UnityObjectToClipPos ( v.vertex );
                o.worldNormal = UnityObjectToWorldNormal ( v.normal );

                return o;
            }

            float4 frag ( v2f i ) : SV_Target
            {
                float3 worldNormal = normalize( i.worldNormal );
                float nl           = max( 0, dot( worldNormal, _WorldSpaceLightPos0.xyz ) );

                float3 diffuse_lighting;
                diffuse_lighting = nl * _LightColor0;

                float4 result = float4( 0, 0, 0, 1 );
                result.rgb    = _Color.rgb * diffuse_lighting;

                return result;
            }
            ENDCG
        }

        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass
        {
            Tags{ "LightMode" = "ShadowCaster" }

            CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_shadowcaster

            struct v2f 
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert ( appdata_base v )
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
                return o;
            }

            float4 frag ( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT ( i )
            }
            ENDCG
        }
    }
}