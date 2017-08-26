//----------------------------------------------------------------------------------------------------
//
// PbsCommon.cginc
//
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
// From UnityImageBasedLighting.cginc
//     Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
//
//----------------------------------------------------------------------------------------------------

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

// weightOverPdf return the weight (without the diffuseAlbedo term) over pdf. diffuseAlbedo term must be apply by the caller.
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

// Ref: Moving Frostbite to PBR (Appendix A)
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

// ----------------------------------------------------------------------------	
