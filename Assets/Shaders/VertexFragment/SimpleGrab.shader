// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/SimpleGrabShader"
{
    Properties
    {
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Transparent" "IgnoreProjector" = "True" }
        ZWrite   On
        Lighting Off
        Cull     Off
        Fog { Mode Off }
        Blend One Zero

        // To share GrabTexture between several materials
        GrabPass{ "_SimpleGrabTexture" }
        // GrabPass{}

        Pass
        {
            CGPROGRAM

            #pragma vertex   my_vert
            #pragma fragment my_frag
            #include "UnityCG.cginc"

            #pragma target 3.0

            sampler2D _SimpleGrabTexture;

            struct VertexInput
            {
                float4 pos      : POSITION;
            };

            struct VertexOutput
            {
                float4 pos     : SV_POSITION;
                float4 grab_uv : TEXCOORD0;
            };

            VertexOutput my_vert( VertexInput vertex_input )
            {
                VertexOutput vertex_output;

                vertex_output.pos     = UnityObjectToClipPos (  vertex_input.pos );
                vertex_output.grab_uv = ComputeGrabScreenPos( vertex_output.pos );

                return vertex_output;
            }

            half4 my_frag( VertexOutput vertex_output ) : COLOR
            {
                half4 texcoord_proj    = UNITY_PROJ_COORD( vertex_output.grab_uv );
                half4 base_color       = tex2Dproj( _SimpleGrabTexture, texcoord_proj );
                base_color.r          += 0.5;

                return base_color;
            }

            ENDCG
        }
    }
}
