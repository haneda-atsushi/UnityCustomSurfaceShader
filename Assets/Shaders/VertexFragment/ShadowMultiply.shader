// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/ShadowMultiply"
{
    Properties
    {
        _MainTex( "Albedo (RGB)", 2D ) = "white" {}
        _ColorPow( "ColorPow", Range(0.0,32.0) ) = 1.0
    }

    SubShader
    {
        Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 200

        Blend DstColor Zero
        ZWrite Off
        Offset -1, -1

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
                half4 base_color = tex2D ( _MainTex, vertex_output.texcoord );
                base_color.rgb   = pow( base_color.rgb, _ColorPow );

                return base_color;
            }

            ENDCG
        }
    }
}
