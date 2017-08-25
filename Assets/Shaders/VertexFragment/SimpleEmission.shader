// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/SimpleEmission"
{
    Properties
    {
        _MainTex ( "Albedo (RGB)", 2D ) = "white" {}
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM

            #pragma vertex   my_vert
            #pragma fragment my_frag

            #pragma target 3.0

            sampler2D _MainTex;

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

            VertexOutput my_vert( VertexInput vertex_input )
            {
                VertexOutput vertex_output;

                vertex_output.pos      = UnityObjectToClipPos( vertex_input.pos );
                vertex_output.texcoord = vertex_input.texcoord;

                return vertex_output;
            }

            half4 my_frag( VertexOutput vertex_output ) : COLOR
            {
                half4 base_color = tex2D( _MainTex, vertex_output.texcoord );
                return base_color;
            }

            ENDCG
        }
    }
}
