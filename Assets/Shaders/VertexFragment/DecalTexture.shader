// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/DecalTexture"
{
    Properties
    {
	    _MainTex("Base (RGB)", 2D) = "white" {}
        _OffsetFactor( "OffsetFactor", Range( -1.0, 1.0 ) ) = 0.0
        _OffsetUnits( "OffsetUnits", Range( -1.0, 1.0 ) )   = 0.0
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry+1" "ForceNoShadowCasting" = "True" }
        LOD 200


        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Offset[_OffsetFactor],[_OffsetUnits]

        Pass
        {
            CGPROGRAM

#pragma vertex   my_vert
#pragma fragment my_frag

#pragma target 3.0

            sampler2D _MainTex;
            fixed     _ColorPow;

            struct VertexInput
            {
                float4 pos      : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos      : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            VertexOutput my_vert ( VertexInput vertex_input )
            {
                VertexOutput vertex_output;

                vertex_output.pos      = UnityObjectToClipPos (  vertex_input.pos );
                vertex_output.texcoord = vertex_input.texcoord;

                return vertex_output;
            }

            half4 my_frag ( VertexOutput vertex_output ) : COLOR
            {
                half4 base_color = tex2D( _MainTex, vertex_output.texcoord );
                return base_color;
            }

            ENDCG
        }
    }

    Fallback "Mobile/VertexLit"
}
