// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragment/FogFoward"
{
    // Vertex and Fragment Shader Examples
    // http://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html

    SubShader
    {
        Pass
        {
            CGPROGRAM
#pragma vertex vert
#pragma fragment frag

        //Needed for fog variation to be compiled.
#pragma multi_compile_fog

#include "UnityCG.cginc"

            struct vertexInput
            {
                float4 vertex : POSITION;
                half3  normal : NORMAL;
            };

            struct fragmentInput
            {
                float4 position : SV_POSITION;
                float3 normalWorld : TEXCOORD0;

                //Used to pass fog amount around number should be a free texcoord.
                UNITY_FOG_COORDS ( 1 )
            };

            fragmentInput vert( vertexInput i )
            {
                fragmentInput o;
                o.position  = UnityObjectToClipPos( i.vertex );
                o.normalWorld = normalize( mul( half4( i.normal, 0.0 ), unity_WorldToObject ).xyz );

                //Compute fog amount from clip space position.
                UNITY_TRANSFER_FOG ( o,o.position );
                return o;
            }

            fixed4 frag( fragmentInput i ) : SV_Target
            {
                float3 normal_world = normalize( i.normalWorld.xyz );
                fixed4 color;
                color.rgb = 0.5 * normal_world + float3( 0.5, 0.5, 0.5 );
                color.a   = 1.0f;

                //Apply fog (additive pass are automatically handled)
                UNITY_APPLY_FOG( i.fogCoord, color );

                //to handle custom fog color another option would have been 
                //#ifdef UNITY_PASS_FORWARDADD
                //  UNITY_APPLY_FOG_COLOR(i.fogCoord, color, float4(0,0,0,0));
                //#else
                //  fixed4 myCustomColor = fixed4(0,0,1,0);
                //  UNITY_APPLY_FOG_COLOR(i.fogCoord, color, myCustomColor);
                //#endif

                return color;
            }
            ENDCG
        }
    }
}