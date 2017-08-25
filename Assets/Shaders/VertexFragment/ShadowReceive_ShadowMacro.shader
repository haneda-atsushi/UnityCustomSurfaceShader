// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/ShadowReceive_ShadowMacro"
{
    Properties
    {
        _Color( "Color", Color ) = ( 1,1,1,1 )
    }

    CGINCLUDE
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
    ENDCG

    SubShader
    {
        Pass
        {
            Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM

#pragma vertex vert
#pragma fragment frag

        // compile shader into multiple variants, with and without shadows
        // (we don't care about any lightmaps yet, so skip these variants)
#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
        // shadow helper functions and macros

        float4 _Color = float4( 1, 1, 1, 1 );

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float3 worldNormal : TEXCOORD1;
            SHADOW_COORDS( 2 ) // put shadows data into TEXCOORD2
            float4 pos : SV_POSITION;
        };

        v2f vert ( appdata_base v )
        {
            v2f o;
            o.pos = UnityObjectToClipPos ( v.vertex );
            o.uv  = v.texcoord;
            o.worldNormal = UnityObjectToWorldNormal ( v.normal );

            // compute shadows data
            TRANSFER_SHADOW ( o )

            return o;
        }

        float4 frag ( v2f i ) : SV_Target
        {
            float4 base_color = _Color;
            // compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
            float shadow = SHADOW_ATTENUATION( i );

            float3 worldNormal      = normalize( i.worldNormal );
            float nl                = max( 0, dot( worldNormal, _WorldSpaceLightPos0.xyz ) );
            float3 diffuse_lighting = nl * _LightColor0.rgb * shadow;

            float4 color = float4( 0, 0, 0, 1 );
            color.rgb    = base_color.rgb * diffuse_lighting;

            return color;
        }
        ENDCG
    }

    // shadow casting support
    UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
