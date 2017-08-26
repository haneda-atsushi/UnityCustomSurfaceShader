// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexFragmentStandard/IndirectShadingMonteCarlo"
{
    Properties
    {
        [HideInInspector]_MainTex( "Diffuse Map", 2D ) = "white" {}
        [HideInInspector][NoScaleOffset]_BumpMap( "Bump Map", 2D ) = "bump" {}
        [HDR]_Color( "Diffuse Color", Color ) = ( 1,1,1,1 )
        [HDR]_SpecColor( "Specular Color", Color ) = ( 1,1,1,1 )
        _Roughness( "Roughness", Range( 0,1 ) ) = 0.5
        [HideInInspector][Enum(None,0,Unity,1,Lambert_MonteCarlo,2)]_IndirectDiffuseType( "Indirect Diffuse", Float ) = 0.0
        [HideInInspector][Enum(None,0,Unity,1,GGX_MonteCarlo,2)]_IndirectSpecularType( "Indirect Specular", Float ) = 0.0
        [HideInInspector][Enum(num1,1,num4,4,num8,8,num16,16,num32,32,num64,64,num128,128)]_ISSampleNum( "SampleNum", Int ) = 16
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "PerformanceChecks" = "False" }

        Pass
        {
            Name "FORWARD"
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fwdbase

#pragma skip_variants DIRECTIONAL_COOKIE
#pragma skip_variants POINT POINT_NOATT POINT_COOKIE
#pragma skip_variants SPOT SPOT_COOKIE
#pragma skip_variants _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
#pragma skip_variants _EMISSION
#pragma skip_variants _METALLICGLOSSMAP 
#pragma skip_variants _DETAIL_MULX2
#pragma skip_variants _PARALLAXMAP
// #pragma skip_variants SHADOWS_SOFT

#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
#pragma  shader_feature __ INDIRECT_DIFFUSE_UNITY  INDIRECT_DIFFUSE_IS
#pragma  shader_feature __ INDIRECT_SPECULAR_UNITY INDIRECT_SPECULAR_GGX_IS

            struct MyVertexInput
            {
                float4 vertex	: POSITION;
                half3 normal	: NORMAL;
                float2 uv0		: TEXCOORD0;
                float2 uv1		: TEXCOORD1;

                /*
        #if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
                float2 uv2		: TEXCOORD2;
        #endif
                */
                half4 tangent	: TANGENT;
            };

            sampler2D _MainTex;
            float4    _MainTex_ST;
            sampler2D _BumpMap;

            float4 _Color;
            float  _Roughness;
            int    _ISSampleNum;

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "PbsCommon.cginc"

            float3 GetCubeMapReflection( UNITY_ARGS_TEXCUBE(tex), float4 probe_hdr, float mip_level,
                                         float3 world_reflect_dir )
            {

                float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD( tex, world_reflect_dir, mip_level );
                return DecodeHDR( rgbm, probe_hdr );
            }

            float3 CalcIndirectSpecular( float4 probeHDR0,
                                         float3 world_normal, 
                                         float3 world_view_dir, float3 world_reflect_dir,
                                         float smoothness,
                                         float3 specular_color )
            {
                float3 specular;

                Unity_GlossyEnvironmentData gloss_env =
                    UnityGlossyEnvironmentSetup( smoothness, world_view_dir, world_normal, specular_color );
                gloss_env.reflUVW = world_reflect_dir;

                float3 env0 = Unity_GlossyEnvironment( UNITY_PASS_TEXCUBE( unity_SpecCube0 ),
                                                       probeHDR0, gloss_env );

                specular = env0;

                return specular;
            }

            float3 CalcUnitySpecularDFG( float3 specular_color,
                                         float roughness,
                                         float dot_v_h, float dot_n_v,
                                         sampler2D lut_texture )
            {    
                float3 dfg_term2       = EnvDFGPolynomial( float3( 1.0f, 1.0f, 1.0f), roughness, dot_n_v );
                float3 f_term          = calcFresnel( specular_color, dot_v_h, lut_texture );

                return f_term * dfg_term2;
            }

            float GetReflectionRoughness( float roughness )
            {
                roughness = clamp( roughness, 1e-4, 1.0 - 1e-4 );
                return roughness;
            }

            struct v2f
            {
                float4 pos							 : SV_POSITION;
                float4 tex							 : TEXCOORD0;
                half3 eyeVec 						 : TEXCOORD1;

                float3 worldNormal                   : TEXCOORD2;
                float3 worldTangent                  : TEXCOORD3;
                float3 worldBitangent                : TEXCOORD4;

                // half4 tangentToWorldAndParallax[ 3 ] : TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]
                // half4 ambientOrLightmapUV		    : TEXCOORD5;	// SH or Lightmap UV
                SHADOW_COORDS( 6 )
                UNITY_FOG_COORDS( 7 )

                float3 posWorld					: TEXCOORD8;
                // half3 reflUVW				: TEXCOORD9;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert( MyVertexInput v )
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID( v );

                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

                float4 vertex   = v.vertex;
                float3 normal   = v.normal;
                float4 tangent  = v.tangent;
                float2 texcoord = v.uv0;

                o.pos            = UnityObjectToClipPos( vertex );
                o.posWorld = mul( unity_ObjectToWorld, vertex ).xyz;

                float3 wNormal   = UnityObjectToWorldNormal( normal );
                o.worldNormal    = wNormal;

                float3 wTangent   = UnityObjectToWorldDir( tangent.xyz );
                o.worldTangent    = wTangent;

                float tangentSign = tangent.w * unity_WorldTransformParams.w;
                float3 wBitangent = cross( wNormal, wTangent ) * tangentSign;
                o.worldBitangent  = wBitangent;

                o.tex.xy = TRANSFORM_TEX( v.uv0, _MainTex );
                o.tex.zw = float2( 0.0f, 0.0f );

                o.eyeVec = float3( 0.0f, 0.0f, 1.0f );

                TRANSFER_SHADOW( o );
                UNITY_TRANSFER_FOG( o, o.pos );

                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                float2 uv             = i.tex;

                float3 diffuse_color  = _Color.rgb;
                float3 specular_color = _SpecColor.rgb;

                float  roughness      = _Roughness;
                roughness             = clamp( roughness, 1e-4, 1.0 - 1e-4 );
                float alpha           = roughness * roughness;
                float alpha_2         = alpha * alpha;

                float  smoothness     = 1.0f - roughness;
                float  occlusion      = 1.0f;

                float3 world_normal    = normalize( i.worldNormal );
                float3 world_tangent   = normalize( i.worldTangent );
                float3 world_bitangent = normalize( i.worldBitangent );

                float3 tspace0 = float3( world_tangent.x, world_bitangent.x, world_normal.x );
                float3 tspace1 = float3( world_tangent.y, world_bitangent.y, world_normal.y );
                float3 tspace2 = float3( world_tangent.z, world_bitangent.z, world_normal.z );

                float3 bump_normal = normalize( UnpackNormal( tex2D( _BumpMap, uv ) ) );

                float3 world_bump_normal;
                world_bump_normal.x = dot( tspace0, bump_normal );
                world_bump_normal.y = dot( tspace1, bump_normal );
                world_bump_normal.z = dot( tspace2, bump_normal );
                // world_bump_normal   = world_normal;

                float3 world_camera_pos  = _WorldSpaceCameraPos;

                float3 world_view_dir    = normalize( UnityWorldSpaceViewDir( i.posWorld ) );
                // float3 world_view_dir    = normalize( world_camera_pos - i.worldPos );
                float3 world_reflect_dir = reflect( - world_view_dir, world_bump_normal );

                float3 world_light_dir   = normalize( _WorldSpaceLightPos0.xyz );
                float3 light_color       = _LightColor0.rgb;

                float3 world_half_dir = normalize( world_light_dir + world_view_dir );
                float dot_l_h = max( dot( world_light_dir, world_half_dir ), 0.0 );
                float dot_n_h      = max( dot( world_bump_normal, world_half_dir ), 0.0 );
                float dot_n_v      = max( dot( world_bump_normal, world_view_dir ), 1e-5 );

                float sign_dot_n_l = dot( world_bump_normal, world_light_dir );
                float raw_dot_n_l  = max( sign_dot_n_l, 0.0f );
                uint sampleCount = ( uint )( _ISSampleNum );

                float direct_light_shadow = 1.0f;

                float3 direct_f_term   = float3( 0.0f, 0.0f, 0.0f );
                float3 indirect_f_term = float3( 0.0f, 0.0f, 0.0f );
                float  d_term          = 0.0f;

                float4 probeHDR0 = unity_SpecCube0_HDR;

    #if ( INDIRECT_DIFFUSE_UNITY )
                float3 indirect_diffuse_lighting =
                    ShadeSH9( float4( world_bump_normal, 1.0f ) );
    #elif ( INDIRECT_DIFFUSE_IS )
                float3 indirect_diffuse_lighting =
                    IntegrateLambertDiffuseIBLRef( UNITY_PASS_TEXCUBE( unity_SpecCube0 ),
                                                    probeHDR0,
                                                    world_bump_normal,
                                                    sampleCount );
    #else
                float3 indirect_diffuse_lighting = float3( 0.0f, 0.0f, 0.0f );
    #endif

                float3 reflect_half_dir = normalize( world_view_dir + world_reflect_dir );
                float  dot_v_h          = saturate( dot( world_view_dir, reflect_half_dir ) );

                float reflection_roughness = GetReflectionRoughness( roughness );
                float reflection_smoothness = 1.0f - reflection_roughness;

#if defined ( INDIRECT_SPECULAR_UNITY )
                float3 indirect_specular_shading =
                    CalcIndirectSpecular( probeHDR0,
                                          world_bump_normal, world_view_dir, world_reflect_dir,
                                          reflection_smoothness,
                                          specular_color );

                float3 dfg_term     =
                    CalcUnitySpecularDFG( specular_color,
                                          reflection_roughness,
                                          dot_v_h,
                                          dot_n_v );

                indirect_specular_shading *= dfg_term;

#elif defined( INDIRECT_SPECULAR_GGX_IS )
                float4 hdr_param = probeHDR0;

                float3 indirect_specular_shading = float3( 0, 0, 0 );

                IntegrateSpecularGGXIBLRef( indirect_specular_shading,
                                            UNITY_PASS_TEXCUBE( unity_SpecCube0 ),
                                            hdr_param,
                                            world_bump_normal,
                                            world_view_dir,
                                            roughness,
                                            specular_color,
                                            sampleCount );

#else
                float3 indirect_specular_shading = float3( 0, 0, 0 );
#endif

                float3 diffuse_shading  = ( indirect_diffuse_lighting * diffuse_color ) * occlusion;
                float3 specular_shading = ( indirect_specular_shading ) * occlusion;

                float4 final_color      = float4( 0.0f, 0.0f, 0.0f, 1.0f );
                final_color.rgb         = diffuse_shading + specular_shading;

                return final_color;
            }

            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
#pragma target 2.0

#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
#pragma shader_feature _METALLICGLOSSMAP
#pragma skip_variants SHADOWS_SOFT
#pragma multi_compile_shadowcaster

#pragma vertex vertShadowCaster
#pragma fragment fragShadowCaster

#include "UnityStandardShadow.cginc"

            ENDCG
        }
    }
    CustomEditor "IndirectShadingMonteCarloGUI"

    FallBack "Diffuse"
}
