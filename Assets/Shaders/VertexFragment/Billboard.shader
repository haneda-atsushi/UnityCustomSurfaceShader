Shader "Custom/VertexFragment/Billboard"
{
    Properties
    {
        _MainTex ( "Albedo (RGB)", 2D ) = "white" {}
        _Cutoff( "Alpha cutoff", Range( 0, 1 ) ) = 0.5
    }

    SubShader
    {
        Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "true" "RenderType" = "TransparentCutout" }
        LOD 200

        Cull Off

        Pass
        {
            CGPROGRAM

            #pragma vertex   my_vert
            #pragma fragment my_frag

            #pragma target 3.0

            uniform sampler2D _MainTex;
            uniform float     _Cutoff;

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
                vertex_output.pos      = mul( UNITY_MATRIX_P,
                                              mul( UNITY_MATRIX_MV, float4( 0.0, 0.0, 0.0, 1.0 ))
                                              + float4( vertex_input.pos.x, vertex_input.pos.y, 0.0, 0.0 ) );
                vertex_output.texcoord = vertex_input.texcoord;

                return vertex_output;
            }

            half4 my_frag( VertexOutput vertex_output ) : COLOR
            {
                half4 base_color = tex2D( _MainTex, vertex_output.texcoord );
                if ( base_color.a < _Cutoff )
                {
                    discard;
                }

                return base_color;
            }

            ENDCG
        }
    }
}
