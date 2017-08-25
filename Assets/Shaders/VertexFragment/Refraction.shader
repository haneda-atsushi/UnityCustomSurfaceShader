// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/VertexFragment/Refraction"
{
    Properties
    {
        _Color( "Color", Color ) = ( 1,1,1,1 )
        _NoiseTex ( "Noise text", 2D ) = "white" {}

        _Period( "Period", Range( 0, 50 ) )        = 10
        _Magnitude( "Magnitude", Range( 0, 0.5 ) ) = 0.05
        _Scale( "Scale", Range( 0, 10 ) )          = 1
    }

    SubShader
    {
        Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }
        ZWrite   Off
        Lighting Off
        Cull     Off
        Fog { Mode Off }
        Blend One Zero

        // To share GrabTexture between several materials
        GrabPass{ "_GrabTexture" }
        // GrabPass{}

        Pass
        {
            CGPROGRAM

            #pragma vertex   my_vert
            #pragma fragment my_frag
            #include "UnityCG.cginc"

            #pragma target 3.0

            float4    _Color;

            sampler2D _GrabTexture;
            sampler2D _NoiseTex;

            float  _Period;
            float  _Magnitude;
            float  _Scale;

            struct VertexInput
            {
                float4 pos      : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos      : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float4 grab_uv  : TEXCOORD2;
            };

            VertexOutput my_vert( VertexInput vertex_input )
            {
                VertexOutput vertex_output;

                vertex_output.pos      = UnityObjectToClipPos(  vertex_input.pos );
                vertex_output.texcoord = vertex_input.texcoord;
                vertex_output.worldPos = mul( unity_ObjectToWorld , vertex_input.pos );
                vertex_output.grab_uv  = ComputeGrabScreenPos( vertex_output.pos );

                return vertex_output;
            }

            half4 my_frag( VertexOutput vertex_output ) : COLOR
            {
                float sinT        = sin ( _Time.w / _Period );
                float2 distortion =
                    float2( tex2D( _NoiseTex ,
                                   vertex_output.worldPos.xy / _Scale + float2( sinT , 0 ) ).r - 0.5,
                            tex2D( _NoiseTex ,
                                   vertex_output.worldPos.xy / _Scale + float2( 0 , sinT ) ).r - 0.5 );

                float4 grab_uv    = vertex_output.grab_uv;
                grab_uv.xy       += distortion * _Magnitude;
                
                half4 texcoord_proj = UNITY_PROJ_COORD( grab_uv );
                half4 base_color    = tex2Dproj( _GrabTexture, texcoord_proj );
                base_color         *= _Color;

                return base_color;
            }

            ENDCG
        }
    }
}
