// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// http://answers.unity3d.com/questions/688943/how-to-receive-shadows-on-a-simple-custom-shader.html

Shader "Custom/VertexFragment/ShadowReceive_LightMacro"
{
    Properties
    {
        _Color( "Color", Color ) = ( 1.0,1.0,1.0,1.0 )
    }

    CGINCLUDE
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
    ENDCG

    SubShader
    {
        LOD 200
        Tags{ "RenderType" = "Opaque" }
        Pass
        {
            Lighting On
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fwdbase

            float4 _Color = float4( 1, 1, 1, 1 );

            struct vertexInput
            {
                float4     vertex        :    POSITION;
                float3     normal        :    NORMAL;
            };

            struct vertexOutput
            {
                float4     pos            : SV_POSITION;
                float3    worldNormal    : TEXCOORD0;
                LIGHTING_COORDS( 1,3 )
            };

            vertexOutput vert( vertexInput v )
            {
                vertexOutput o;

                float4 posWorld = mul( unity_ObjectToWorld, v.vertex );
                o.pos            = UnityObjectToClipPos( v.vertex );
                o.worldNormal    = normalize( mul( float4( v.normal, 0.0 ), unity_WorldToObject ).xyz );

                TRANSFER_VERTEX_TO_FRAGMENT( o );

                return o;
            }

            float4 frag( vertexOutput i ) : COLOR
            {
                float3 world_normal      = normalize( i.worldNormal );
                float3 light_dir         = normalize( _WorldSpaceLightPos0.xyz );
                float NdotL              = max( dot( world_normal, light_dir ), 0.0f );
                float atten              = LIGHT_ATTENUATION( i );
                float3 diffuseReflection = NdotL * atten * _LightColor0.rgb;
                float3 finalColor        = _Color.rgb * ( UNITY_LIGHTMODEL_AMBIENT.xyz + diffuseReflection );

                return float4( finalColor, 1.0 );
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}