//----------------------------------------------------------------------------------------------------
//
// PbsCommon.cginc
//
//----------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------
//
// BRDF Explorer
//
//----------------------------------------------------------------------------------------------------

#define   MATH_PI     ( 3.141592f )
#define   INV_MATH_PI ( 1.0f / 3.141592f )

float3 f_schlick( float3 f0, float u )
{
    return f0 + ( float3( 1.0, 1.0, 1.0 ) - f0 ) * pow( 1 - u, 5 );
}

float d_blinn_phong( float3 world_normal, float3 world_half_dir, float alpha_2 )
{
    float n = 2.0 / alpha_2 - 2.0;
    float D = pow( max( 0, dot( world_normal, world_half_dir ) ), n );

    return D;
}

float d_norm_blinn_phong( float3 world_normal, float3 world_half_dir, float alpha_2 )
{
    float D     = d_blinn_phong( world_normal, world_half_dir, alpha_2 );
    float n     = 2.0 / alpha_2 - 2.0;
    float scale = 0.5f * INV_MATH_PI * ( 2.0 + n );

    return ( D * scale );
}

float d_GGX( float alpha, float cos_n_h )
{
    float term0 = alpha * INV_MATH_PI;
    float term1 = cos_n_h *  cos_n_h * ( alpha - 1 ) + 1.0;
    float term2 = term1 * term1;

    return term0 / term2;
}

float calcDistrib( sampler2D lut_texture, float dot_n_h )
{
    float2 uv     = float2( clamp( dot_n_h, 0.0f, 1.0f), 0.0f );
    float distrib = tex2D( lut_texture, uv ).g;

    return distrib;
}

float g1( float dot_n_w, float k )
{
    return 1.0 / ( dot_n_w * ( 1.0 - k ) + k );
}

float v_shlick_ggx( float alpha, float dot_n_l, float dot_n_v )
{
    float k = 0.5 * alpha;
    return g1( dot_n_l, k ) * g1( dot_n_v, k );
}

//----------------------------------------------------------------------------------------------------

// Analytical DFG Term for IBL
// https://knarkowicz.wordpress.com/2014/12/27/analytical-dfg-term-for-ibl/
float3 EnvDFGPolynomial( float3 specularColor, float roughness, float ndotv )
{
    float gloss = pow( 1.0 - roughness, 4.0f );

    float x = gloss;
    float y = ndotv;

    float b1 = -0.1688;
    float b2 = 1.895;
    float b3 = 0.9903;
    float b4 = -4.853;
    float b5 = 8.404;
    float b6 = -5.069;
    float bias = saturate( min( b1 * x + b2 * x * x, b3 + b4 * y + b5 * y * y + b6 * y * y * y ) );

    float d0 = 0.6045;
    float d1 = 1.699;
    float d2 = -0.5228;
    float d3 = -3.603;
    float d4 = 1.404;
    float d5 = 0.1939;
    float d6 = 2.661;
    float delta = saturate( d0 + d1 * x + d2 * y + d3 * x * x + d4 * x * y + d5 * y * y + d6 * x * x * x );
    float scale = delta - bias;

    bias *= saturate( 50.0 * specularColor.y );
    return specularColor * scale + bias;
}

//----------------------------------------------------------------------------------------------------
//
// Specular IBL IS ( Substance Player : pbr_ibl.glsl )
//
//----------------------------------------------------------------------------------------------------

#define M_PI       3.14159265359f                     
#define M_INV_PI   0.31830988618379067153776752674503f
#define M_INV_LOG2 1.4426950408889634073599246810019f 

#define vanDerCorputMapWidth    256
#define vanDerCorputMapHeight     4
#define nbSamples                16

float normal_distrib( float ndh, float Roughness )
{
    // use GGX / Trowbridge-Reitz, same as Disney and Unreal 4
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    float  alpha = Roughness * Roughness;
    float  tmp   = alpha / max( 1e-8, ( ndh*ndh*( alpha*alpha - 1.0 ) + 1.0 ) );
    return ( tmp * tmp * M_INV_PI );
}

float probabilityGGX( float ndh, float vdh, float Roughness )
{
    return normal_distrib( ndh, Roughness ) * ndh / ( 4.0 * vdh );
}

/*
float distortion( float3 Wn )
{
    // Computes the inverse of the solid angle of the (differential) pixel in
    // the environment map pointed at by Wn
    float sinT = sqrt( 1.0f - Wn.y * Wn.y );
    return sinT;
}

float computeLOD( float3 Ln,
                  float  p,
                  float  maxLod )
{
    float lod_level = 
        ( maxLod - 1.5 ) - 0.5f * ( log( float( nbSamples ) ) + log( p * distortion( Ln ) ) );
    return max( 0.0, lod_level * M_INV_LOG2 );
}

float3 samplePanoramicLOD( sampler2D env_map, float3 dir, float lod, float4 hdr_param )
{
    float n = length( dir.xz );
    float2 pos = float2( ( n>0.0000001 ) ? dir.x / n : 0.0, dir.y );
    pos = acos( pos )*M_INV_PI;
    pos.x = ( dir.z > 0.0 ) ? pos.x*0.5 : 1.0 - ( pos.x*0.5 );
    pos.y = 1.0 - pos.y;

    float4 uv   = float4( pos.x, pos.y, 0.0f, lod );
    float4 rgbm = tex2Dlod( env_map, uv );

    float3 hdr_color = DecodeHDR( rgbm, hdr_param );

    return hdr_color;
}
*/

void computeSamplingFrame( in float3 iFS_Tangent, in float3 iFS_Binormal, in float3 fixedNormalWS,
                           out float3 Tp, out float3 Bp )
{
    Tp = normalize( iFS_Tangent
                    - fixedNormalWS * dot( iFS_Tangent, fixedNormalWS ) );
    Bp = normalize( iFS_Binormal
                    - fixedNormalWS * dot( iFS_Binormal, fixedNormalWS )
                    - Tp*dot( iFS_Binormal, Tp ) );
}

/*
//- Return the i*th* number from the Van Der Corput sequence.
float VanDerCorput( sampler2D vanDerCorputMap,
                    int i,
                    int vanDerCorputMapWidth,
                    int vanDerCorputMapHeight,
                    int nbSamples)
{
    float xInVanDerCorputTex = (float(i)+0.5) / vanDerCorputMapWidth;
    float yInVanDerCorputTex = 0.5 / vanDerCorputMapHeight; // First row pixel
    return texture2D(vanDerCorputMap, vec2(xInVanDerCorputTex, yInVanDerCorputTex)).x;
}

//- Return the i*th* couple from the Hammerlsey sequence.
//- nbSample is required to get an uniform distribution. nbSample has to be less than 1024.
vec2 hammersley2D( sampler2D vanDerCorputMap,
                   int i,
                   int vanDerCorputMapWidth,
                   int vanDerCorputMapHeight,
                   int nbSamples )
{
    return vec2(
    (float(i)+0.5) / float(nbSamples),
    VanDerCorput(vanDerCorputMap, i, vanDerCorputMapWidth, vanDerCorputMapHeight, nbSamples)
    );
}
*/

//-----------------------------------------------------------------------------
// Sample generator
//-----------------------------------------------------------------------------
// Ref: http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
uint ReverseBits32( uint bits )
{
#if 0 // Shader model 5
    return reversebits( bits );
#else
    bits = ( bits << 16 ) | ( bits >> 16 );
    bits = ( ( bits & 0x00ff00ff ) << 8 ) | ( ( bits & 0xff00ff00 ) >> 8 );
    bits = ( ( bits & 0x0f0f0f0f ) << 4 ) | ( ( bits & 0xf0f0f0f0 ) >> 4 );
    bits = ( ( bits & 0x33333333 ) << 2 ) | ( ( bits & 0xcccccccc ) >> 2 );
    bits = ( ( bits & 0x55555555 ) << 1 ) | ( ( bits & 0xaaaaaaaa ) >> 1 );
    return bits;
#endif
}
//-----------------------------------------------------------------------------
float RadicalInverse_VdC( uint bits )
{
    return float( ReverseBits32( bits ) ) * 2.3283064365386963e-10; // 0x100000000
}

//-----------------------------------------------------------------------------
float2 Hammersley2d( uint i, uint maxSampleCount )
{
    return float2( float( i ) / float( maxSampleCount ), RadicalInverse_VdC( i ) );
}

//-----------------------------------------------------------------------------
float Hash( uint s )
{
    s = s ^ 2747636419u;
    s = s * 2654435769u;
    s = s ^ ( s >> 16 );
    s = s * 2654435769u;
    s = s ^ ( s >> 16 );
    s = s * 2654435769u;
    return float( s ) / 4294967295.0f;
}

//-----------------------------------------------------------------------------
float2 InitRandom( float2 input )
{
    float2 r;
    r.x = Hash( uint( input.x * 4294967295.0f ) );
    r.y = Hash( uint( input.y * 4294967295.0f ) );

    return r;
}


float3 calcFresnel( in float3 specAlbedo, in float3 h, in float3 l )
{
    float lDotH = saturate( dot( l, h ) );
    return specAlbedo + ( 1.0f - specAlbedo ) * pow( ( 1.0f - lDotH ), 5.0f );
}

float3 calcFresnel( float vdh, float3 F0 )
{
    // Schlick with Spherical Gaussian approximation
    // cf http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf p3
    float sphg = pow( 2.0, ( -5.55473*vdh - 6.98316 ) * vdh );

    return F0 + ( float3( 1.0, 1.0, 1.0 ) - F0 ) * sphg;
}

inline float calcPow5( float x )
{
    return x*x * x*x * x;
}

float3 calcFresnel( float3 specular_color, float dot_v_h,
                    sampler2D lut_texture )
{
    float3 f_term = f_schlick( specular_color, dot_v_h );

    return f_term;
}

void GetLocalFrame( float3 N, out float3 tangentX, out float3 tangentY )
{
    float3 upVector = abs( N.z ) < 0.999f ? float3( 0.0f, 0.0f, 1.0f ) : float3( 1.0f, 0.0f, 0.0f );
    tangentX = normalize( cross( upVector, N ) );
    tangentY = cross( N, tangentX );
}

void ImportanceSampleGGXDir( float2 u,
                             float3 V,
                             float3 N,
                             float3 tangentX,
                             float3 tangentY,
                             float roughness,
                             out float3 H,
                             out float3 L )
{
    // GGX NDF sampling
    float cosThetaH = sqrt( ( 1.0f - u.x ) / ( 1.0f + ( roughness * roughness - 1.0f ) * u.x ) );
    float sinThetaH = sqrt( max( 0.0f, 1.0f - cosThetaH * cosThetaH ) );
    float phiH = UNITY_TWO_PI * u.y;

    // Transform from spherical into cartesian
    H = float3( sinThetaH * cos( phiH ), sinThetaH * sin( phiH ), cosThetaH );
    // Local to world
    H = tangentX * H.x + tangentY * H.y + N * H.z;

    // Convert sample from half angle to incident angle
    L = 2.0f * dot( V, H ) * H - V;
}

// ----------------------------------------------------------------------------
// weightOverPdf return the weight (without the Fresnel term) over pdf. Fresnel term must be apply by the caller.
void ImportanceSampleGGX(
    float2 u,
    float3 V,
    float3 N,
    float3 tangentX,
    float3 tangentY,
    float roughness,
    float NdotV,
    out float3 L,
    out float VdotH,
    out float NdotL,
    out float weightOverPdf )
{
    float3 H;
    ImportanceSampleGGXDir( u, V, N, tangentX, tangentY, roughness, H, L );

    float NdotH = saturate( dot( N, H ) );
    // Note: since L and V are symmetric around H, LdotH == VdotH
    VdotH = saturate( dot( V, H ) );
    NdotL = saturate( dot( N, L ) );

    // Importance sampling weight for each sample
    // pdf = D(H) * (N.H) / (4 * (L.H))
    // weight = fr * (N.L) with fr = F(H) * G(V, L) * D(H) / (4 * (N.L) * (N.V))
    // weight over pdf is:
    // weightOverPdf = F(H) * G(V, L) * (L.H) / ((N.H) * (N.V))
    // weightOverPdf = F(H) * 4 * (N.L) * V(V, L) * (L.H) / (N.H) with V(V, L) = G(V, L) / (4 * (N.L) * (N.V))
    // F is apply outside the function

    float Vis = SmithJointGGXVisibilityTerm( NdotL, NdotV, roughness );
    weightOverPdf = 4.0f * Vis * NdotL * VdotH / NdotH;
}

// ----------------------------------------------------------------------------	
// Ref: Moving Frostbite to PBR (Appendix A)
void IntegrateSpecularGGXIBLRef( out float3 specularLighting,
                                 UNITY_ARGS_TEXCUBE( tex ),
                                 float4 texHdrParam, // Multiplier to apply on hdr texture (in case of rgbm)
                                 float3 N,
                                 float3 V,
                                 float roughness,
                                 float3 f0,
                                 uint sampleCount )
                                 // float f90,
                                 //uint sampleCount = 2048 )
{
    float NdotV = saturate( dot( N, V ) );
    float3 acc = float3( 0.0f, 0.0f, 0.0f );
    // Add some jittering on Hammersley2d
    float2 randNum = InitRandom( V.xy * 0.5f + 0.5f );

    float3 tangentX, tangentY;
    GetLocalFrame( N, tangentX, tangentY );

    for ( uint i = 0; i < sampleCount; ++i )
    {
        float2 u = Hammersley2d( i, sampleCount );
        u = frac( u + randNum + 0.5f );

        float VdotH;
        float NdotL;
        float3 L;
        float weightOverPdf;

        // GGX BRDF
        ImportanceSampleGGX( u, V, N, tangentX, tangentY, roughness, NdotV,
                             L, VdotH, NdotL, weightOverPdf );

        //if ( NdotL > 0.0f )
        {
            // float3 f_term = fresnel( f0, VdotH );

            float3 dot_v_h = VdotH;
            float3 f_term = calcFresnel( f0, dot_v_h );
            //float3 f_term = FresnelLerp( f0, f90, VdotH );

            // Fresnel component is apply here as describe in ImportanceSampleGGX function
            //float3 FweightOverPdf = FresnelLerp( f0, f90, VdotH ) * weightOverPdf;
            float3 FweightOverPdf = f_term * weightOverPdf;

            float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD( tex, L, 0 ).rgba;
            float3 val = DecodeHDR( rgbm, texHdrParam );

            acc += 
                ( NdotL > 0.0f ) ?
                FweightOverPdf * val :
                0.0f;
        }
    }

    specularLighting = acc / sampleCount;
}

// ----------------------------------------------------------------------------	
void ImportanceSampleCosDir( float2 u,
                             float3 N,
                             float3 tangentX,
                             float3 tangentY,
                             out float3 L )
{
    // Cosine sampling - ref: http://www.rorydriscoll.com/2009/01/07/better-sampling/
    float cosTheta = sqrt( max( 0.0f, 1.0f - u.x ) );
    float sinTheta = sqrt( u.x );
    float phi = UNITY_TWO_PI * u.y;

    // Transform from spherical into cartesian
    L = float3( sinTheta * cos( phi ), sinTheta * sin( phi ), cosTheta );
    // Local to world
    L = tangentX * L.x + tangentY * L.y + N * L.z;
}

void ImportanceSampleLambert(
    float2 u,
    float3 N,
    float3 tangentX,
    float3 tangentY,
    out float3 L,
    out float NdotL,
    out float sign_NdotL,
    out float weightOverPdf )
{
    ImportanceSampleCosDir( u, N, tangentX, tangentY, L );

    sign_NdotL = dot( N, L );
    NdotL      = saturate( sign_NdotL );

    // Importance sampling weight for each sample
    // pdf = N.L / PI
    // weight = fr * (N.L) with fr = diffuseAlbedo / PI
    // weight over pdf is:
    // weightOverPdf = (diffuseAlbedo / PI) * (N.L) / (N.L / PI)
    // weightOverPdf = diffuseAlbedo
    // diffuseAlbedo is apply outside the function 

    weightOverPdf = 1.0f;
}

float3 IntegrateLambertDiffuseIBLRef( UNITY_ARGS_TEXCUBE( tex ),
                                      float4 texHdrParam,
                                      float3 N,
                                      uint sampleCount )
{
    float3 acc = float3( 0.0f, 0.0f, 0.0f );
    // Add some jittering on Hammersley2d
    float2 randNum = InitRandom( N.xy * 0.5f + 0.5f );

    float3 tangentX, tangentY;
    GetLocalFrame( N, tangentX, tangentY );

    for ( uint i = 0; i < sampleCount; ++i )
    {
        float2 u = Hammersley2d( i, sampleCount );
        u        = frac( u + randNum + 0.5f );

        float3 L;
        float NdotL;
        float sign_NdotL;
        float weightOverPdf;
        ImportanceSampleLambert( u, N, tangentX, tangentY, L,
                                 NdotL, sign_NdotL, weightOverPdf );

        //if ( NdotL > 0.0f )
        {
            float4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD( tex, L, 0 ).rgba;
            float3 val = DecodeHDR( rgbm, texHdrParam );

            acc += ( NdotL > 0.0f ) ?
                 weightOverPdf * val : float3( 0.0f, 0.0f, 0.0f );

            // diffuse Albedo is apply here as describe in ImportanceSampleLambert function
            // acc += diffuseAlbedo * weightOverPdf * val;
        }
    }

    float3 diffuseLighting = acc / sampleCount;

    return diffuseLighting;
}
