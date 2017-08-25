// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/VertexFragmentStandard/CustomStandardSimple"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        [Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0

        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 300


        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------
            #pragma shader_feature _EMISSION

            #pragma skip_variants _NORMALMAP
            #pragma skip_variants _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma skip_variants _METALLICGLOSSMAP
            #pragma skip_variants ___ _DETAIL_MULX2
            #pragma skip_variants _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants _ _SPECULARHIGHLIGHTS_OFF
            #pragma skip_variants _ _GLOSSYREFLECTIONS_OFF
            #pragma skip_variants _PARALLAXMAP            
        
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex   MyVertBase
            #pragma fragment MyFragBase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityStandardCore.cginc"

            /*
            // UnityStandardInput.cginc
            struct VertexInput
            {
                float4 vertex   : POSITION;
                half3 normal    : NORMAL;
                float2 uv0      : TEXCOORD0;
                float2 uv1      : TEXCOORD1;
                #if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
                float2 uv2      : TEXCOORD2;
                #endif
                #ifdef _TANGENT_TO_WORLD
                half4 tangent   : TANGENT;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            */

            struct MyVertexOutputForwardBase
            {
                UNITY_POSITION( pos );
                float4 tex                          : TEXCOORD0;
                half3 eyeVec                        : TEXCOORD1;
                half4 tangentToWorldAndPackedData[ 3 ]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
                half4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UV
                UNITY_SHADOW_COORDS( 6 )
                UNITY_FOG_COORDS( 7 )

                // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
                float3 posWorld                 : TEXCOORD8;
    #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            MyVertexOutputForwardBase MyVertForwardBase( VertexInput v )
            {
                UNITY_SETUP_INSTANCE_ID( v );
                VertexOutputForwardBase o;
                UNITY_INITIALIZE_OUTPUT( VertexOutputForwardBase, o );
                UNITY_TRANSFER_INSTANCE_ID( v, o );
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

                float4 posWorld = mul( unity_ObjectToWorld, v.vertex );
    #if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                o.tangentToWorldAndPackedData[ 0 ].w = posWorld.x;
                o.tangentToWorldAndPackedData[ 1 ].w = posWorld.y;
                o.tangentToWorldAndPackedData[ 2 ].w = posWorld.z;
    #else
                o.posWorld = posWorld.xyz;
    #endif
    #endif
                o.pos = UnityObjectToClipPos( v.vertex );

                o.tex = TexCoords( v );
                o.eyeVec = NormalizePerVertexNormal( posWorld.xyz - _WorldSpaceCameraPos );
                float3 normalWorld = UnityObjectToWorldNormal( v.normal );
    #ifdef _TANGENT_TO_WORLD
                float4 tangentWorld = float4( UnityObjectToWorldDir( v.tangent.xyz ), v.tangent.w );

                float3x3 tangentToWorld = CreateTangentToWorldPerVertex( normalWorld, tangentWorld.xyz, tangentWorld.w );
                o.tangentToWorldAndPackedData[ 0 ].xyz = tangentToWorld[ 0 ];
                o.tangentToWorldAndPackedData[ 1 ].xyz = tangentToWorld[ 1 ];
                o.tangentToWorldAndPackedData[ 2 ].xyz = tangentToWorld[ 2 ];
    #else
                o.tangentToWorldAndPackedData[ 0 ].xyz = 0;
                o.tangentToWorldAndPackedData[ 1 ].xyz = 0;
                o.tangentToWorldAndPackedData[ 2 ].xyz = normalWorld;
    #endif

                // We need this for shadow receving
                UNITY_TRANSFER_SHADOW( o, v.uv1 );

                o.ambientOrLightmapUV = VertexGIForward( v, posWorld, normalWorld );

                UNITY_TRANSFER_FOG( o,o.pos );

                return o;
            }

            half4 MyFragForwardBaseInternal( MyVertexOutputForwardBase i )
            {
                UNITY_APPLY_DITHER_CROSSFADE( i.pos.xy );

                FRAGMENT_SETUP( s )

                UNITY_SETUP_INSTANCE_ID( i );
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( i );


                UnityLight mainLight = MainLight();
                UNITY_LIGHT_ATTENUATION( atten, i, s.posWorld );

                half4 c;
                float lambert = max( dot( mainLight.dir, s.normalWorld ), 0.0f );
                c.rgb         = s.diffColor.rgb * atten * lambert;

                return OutputForward( c, s.alpha );
            }

            half4 MyFragForwardBase( MyVertexOutputForwardBase i ) : SV_Target   // backward compatibility (this used to be the fragment entry function)
            {
                return MyFragForwardBaseInternal( i );
            }

            MyVertexOutputForwardBase MyVertBase( VertexInput v ) { return MyVertForwardBase( v ); }
            half4 MyFragBase( MyVertexOutputForwardBase i ) : SV_Target{ return MyFragForwardBaseInternal( i ); }

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------

            #pragma shader_feature _EMISSION

            #pragma skip_variants _NORMALMAP
            #pragma skip_variants _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma skip_variants _METALLICGLOSSMAP
            #pragma skip_variants ___ _DETAIL_MULX2
            #pragma skip_variants _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants _ _SPECULARHIGHLIGHTS_OFF
            #pragma skip_variants _ _GLOSSYREFLECTIONS_OFF
            #pragma skip_variants _PARALLAXMAP            

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex   MyVertAdd
            #pragma fragment MyFragAdd

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityStandardCore.cginc"

            struct MyVertexOutputForwardAdd
            {
                UNITY_POSITION( pos );
                float4 tex                          : TEXCOORD0;
                half3 eyeVec                        : TEXCOORD1;
                half4 tangentToWorldAndLightDir[ 3 ]  : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:lightDir]
                float3 posWorld                     : TEXCOORD5;
                UNITY_SHADOW_COORDS( 6 )
                UNITY_FOG_COORDS( 7 )

                // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
    #if defined(_PARALLAXMAP)
                half3 viewDirForParallax            : TEXCOORD8;
    #endif

                UNITY_VERTEX_OUTPUT_STEREO
            };

            MyVertexOutputForwardAdd MyVertForwardAdd( VertexInput v )
            {
                UNITY_SETUP_INSTANCE_ID( v );
                MyVertexOutputForwardAdd o;
                UNITY_INITIALIZE_OUTPUT( MyVertexOutputForwardAdd, o );
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

                float4 posWorld = mul( unity_ObjectToWorld, v.vertex );
                o.pos = UnityObjectToClipPos( v.vertex );

                o.tex = TexCoords( v );
                o.eyeVec = NormalizePerVertexNormal( posWorld.xyz - _WorldSpaceCameraPos );
                o.posWorld = posWorld.xyz;
                float3 normalWorld = UnityObjectToWorldNormal( v.normal );
#ifdef _TANGENT_TO_WORLD
                float4 tangentWorld = float4( UnityObjectToWorldDir( v.tangent.xyz ), v.tangent.w );

                float3x3 tangentToWorld = CreateTangentToWorldPerVertex( normalWorld, tangentWorld.xyz, tangentWorld.w );
                o.tangentToWorldAndLightDir[ 0 ].xyz = tangentToWorld[ 0 ];
                o.tangentToWorldAndLightDir[ 1 ].xyz = tangentToWorld[ 1 ];
                o.tangentToWorldAndLightDir[ 2 ].xyz = tangentToWorld[ 2 ];
#else
                o.tangentToWorldAndLightDir[ 0 ].xyz = 0;
                o.tangentToWorldAndLightDir[ 1 ].xyz = 0;
                o.tangentToWorldAndLightDir[ 2 ].xyz = normalWorld;
#endif
                //We need this for shadow receiving
                UNITY_TRANSFER_SHADOW( o, v.uv1 );

                float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
#ifndef USING_DIRECTIONAL_LIGHT
                lightDir = NormalizePerVertexNormal( lightDir );
#endif
                o.tangentToWorldAndLightDir[ 0 ].w = lightDir.x;
                o.tangentToWorldAndLightDir[ 1 ].w = lightDir.y;
                o.tangentToWorldAndLightDir[ 2 ].w = lightDir.z;

                UNITY_TRANSFER_FOG( o,o.pos );

                return o;
            }


            half4 MyFragForwardAddInternal( MyVertexOutputForwardAdd i )
            {
                UNITY_APPLY_DITHER_CROSSFADE( i.pos.xy );
                FRAGMENT_SETUP_FWDADD( s )

                UNITY_LIGHT_ATTENUATION( atten, i, s.posWorld )
                UnityLight light = AdditiveLight( IN_LIGHTDIR_FWDADD( i ), atten );

                half4 c;
                float lambert = max( dot( light.dir, s.normalWorld ), 0.0f );
                c.rgb         = s.diffColor.rgb * atten * lambert;

                return OutputForward( c, s.alpha );
            }

            half4 MyFragAdd( MyVertexOutputForwardAdd i ) : SV_Target
            {
                return MyFragForwardAddInternal( i );
            }

            MyVertexOutputForwardAdd MyVertAdd( VertexInput v )
            {
                return MyVertForwardAdd( v );
            }

            half4 MyFragForwardAdd( MyVertexOutputForwardAdd i ) : SV_Target     // backward compatibility (this used to be the fragment entry function)
            {
                return MyFragForwardAddInternal( i );
            }

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _PARALLAXMAP
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster

            #include "UnityStandardShadow.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Deferred pass
        Pass
        {
            Name "DEFERRED"
            Tags { "LightMode" = "Deferred" }

            CGPROGRAM
            #pragma target 3.0
            #pragma exclude_renderers nomrt

            // -------------------------------------
            #pragma skip_variants _NORMALMAP
            #pragma skip_variants _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma skip_variants _EMISSION
            #pragma skip_variants _METALLICGLOSSMAP
            #pragma skip_variants _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants _ _SPECULARHIGHLIGHTS_OFF
            #pragma skip_variants _ _GLOSSYREFLECTIONS_OFF
            #pragma skip_variants ___ _DETAIL_MULX2
            #pragma skip_variants _PARALLAXMAP            

            #pragma multi_compile_prepassfinal
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex   MyVertDeferred
            #pragma fragment MyFragDeferred

            #include "UnityStandardCore.cginc"

            struct MyVertexOutputDeferred
            {
                UNITY_POSITION( pos );
                float4 tex                          : TEXCOORD0;
                half3 eyeVec                        : TEXCOORD1;
                half4 tangentToWorldAndPackedData[ 3 ]: TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
                half4 ambientOrLightmapUV           : TEXCOORD5;    // SH or Lightmap UVs

    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
                float3 posWorld                     : TEXCOORD6;
    #endif

                UNITY_VERTEX_OUTPUT_STEREO
            };

            MyVertexOutputDeferred MyVertDeferred( VertexInput v )
            {
                UNITY_SETUP_INSTANCE_ID( v );
                VertexOutputDeferred o;
                UNITY_INITIALIZE_OUTPUT( VertexOutputDeferred, o );
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

                float4 posWorld = mul( unity_ObjectToWorld, v.vertex );

    #if UNITY_REQUIRE_FRAG_WORLDPOS
    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                o.tangentToWorldAndPackedData[ 0 ].w = posWorld.x;
                o.tangentToWorldAndPackedData[ 1 ].w = posWorld.y;
                o.tangentToWorldAndPackedData[ 2 ].w = posWorld.z;
    #else
                o.posWorld = posWorld.xyz;
    #endif
    #endif
                o.pos = UnityObjectToClipPos( v.vertex );

                o.tex = TexCoords( v );
                o.eyeVec = NormalizePerVertexNormal( posWorld.xyz - _WorldSpaceCameraPos );
                float3 normalWorld = UnityObjectToWorldNormal( v.normal );


    #ifdef _TANGENT_TO_WORLD
                float4 tangentWorld = float4( UnityObjectToWorldDir( v.tangent.xyz ), v.tangent.w );

                float3x3 tangentToWorld = CreateTangentToWorldPerVertex( normalWorld, tangentWorld.xyz, tangentWorld.w );
                o.tangentToWorldAndPackedData[ 0 ].xyz = tangentToWorld[ 0 ];
                o.tangentToWorldAndPackedData[ 1 ].xyz = tangentToWorld[ 1 ];
                o.tangentToWorldAndPackedData[ 2 ].xyz = tangentToWorld[ 2 ];
    #else
                o.tangentToWorldAndPackedData[ 0 ].xyz = 0;
                o.tangentToWorldAndPackedData[ 1 ].xyz = 0;
                o.tangentToWorldAndPackedData[ 2 ].xyz = normalWorld;
    #endif

                o.ambientOrLightmapUV = 0;

    #ifdef LIGHTMAP_ON
                o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
    #elif UNITY_SHOULD_SAMPLE_SH
                o.ambientOrLightmapUV.rgb = ShadeSHPerVertex( normalWorld, o.ambientOrLightmapUV.rgb );
    #endif
    #ifdef DYNAMICLIGHTMAP_ON
                o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

                return o;
            }

            void MyFragDeferred(
                MyVertexOutputDeferred i,
                out half4 outGBuffer0 : SV_Target0,
                out half4 outGBuffer1 : SV_Target1,
                out half4 outGBuffer2 : SV_Target2,
                out half4 outEmission : SV_Target3          // RT3: emission (rgb), --unused-- (a)
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                ,out half4 outShadowMask : SV_Target4       // RT4: shadowmask (rgba)
    #endif
            )
            {
    #if (SHADER_TARGET < 30)
                outGBuffer0 = 1;
                outGBuffer1 = 1;
                outGBuffer2 = 0;
                outEmission = 0;
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                outShadowMask = 1;
    #endif
                return;
    #endif

                UNITY_APPLY_DITHER_CROSSFADE( i.pos.xy );

                FRAGMENT_SETUP( s )

                // no analytic lights in this pass
                UnityLight dummyLight = DummyLight();
                half atten = 1;

                // only GI
                // half occlusion = Occlusion( i.tex.xy );
                half occlusion = 1.0f;
  
                /*
                #if UNITY_ENABLE_REFLECTION_BUFFERS
                bool sampleReflectionsInDeferred = false;
                #else
                bool sampleReflectionsInDeferred = true;
                #endif
                UnityGI gi = 
                    FragmentGI( s, occlusion, i.ambientOrLightmapUV, atten,
                                dummyLight, sampleReflectionsInDeferred );
                half3 emissiveColor = 
                    UNITY_BRDF_PBS( s.diffColor, s.specColor,
                                    s.oneMinusReflectivity, s.smoothness,
                                    s.normalWorld, -s.eyeVec, gi.light, gi.indirect ).rgb;
                */
                float3 emissiveColor = float3( 1, 0, 0 );

    #ifdef _EMISSION
                emissiveColor += Emission( i.tex.xy );
    #endif

    #ifndef UNITY_HDR_ON
                emissiveColor.rgb = exp2( -emissiveColor.rgb );
    #endif

                UnityStandardData data;
                data.diffuseColor  = s.diffColor;
                data.occlusion     = occlusion;
                data.specularColor = s.specColor;
                data.smoothness    = s.smoothness;
                data.normalWorld   = s.normalWorld;

                UnityStandardDataToGbuffer( data, outGBuffer0, outGBuffer1, outGBuffer2 );

                // Emissive lighting buffer
                outEmission = half4( emissiveColor, 1 );

                // Baked direct lighting occlusion if any
    #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                outShadowMask = UnityGetRawBakedOcclusions( i.ambientOrLightmapUV.xy, IN_WORLDPOS( i ) );
    #endif
            }

            ENDCG
        }

        // ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"
            ENDCG
        }
    }

    FallBack "VertexLit"
}
