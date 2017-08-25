// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/SimpleShaderVariation"
{
    Properties
    {
        _BaseColor( "BaseColor", Color ) = ( 1,1,1,1 )
        _MainTex( "Albedo (RGB)", 2D ) = "white" {}

        [Enum(None,0,Red,1,Green,2,Blue,3)]_ForceBaseColor( "ForceBaseColor", Float ) = 0.0
        [HideInInspector][Toggle]_UseTexture( "UseTexture", Float ) = 0.0
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM

            #pragma multi_compile  __ FORCE_BASE_COLOR_RED FORCE_BASE_COLOR_GREEN FORCE_BASE_COLOR_BLUE
            #pragma shader_feature USE_TEXTURE

            #pragma vertex   my_vert
            #pragma fragment my_frag

            #pragma target 3.0

            float4    _BaseColor;
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
                float4 color = _BaseColor;

#if FORCE_BASE_COLOR_RED
                color = float4( 1, 0, 0, 1 );
#elif FORCE_BASE_COLOR_GREEN
                color = float4( 0, 1, 0, 1 );
#elif FORCE_BASE_COLOR_BLUE
                color = float4( 0, 0, 1, 1 );
#endif

#if USE_TEXTURE
                half4 base_color = tex2D( _MainTex, vertex_output.texcoord );
#else
                half4 base_color = half4( 1, 1, 1, 1 );
#endif

                return base_color * color;
            }

            ENDCG
        }
    }

    CustomEditor "SimpleShaderVariationGUI"
}
