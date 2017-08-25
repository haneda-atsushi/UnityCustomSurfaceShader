Shader "Custom/Surface/TransparentWithShadow"
{
    // Unity5で半透明オブジェクトに影を投影する方法
    // http://famme-fatale.hatenablog.com/entry/2015/03/18/124410

    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Cutout ("Cutout", Range(0,1)) = 0.0
        _AlphaScale ( "AlphaScale", Range ( 0, 16 ) ) = 8.0
    }

    SubShader
    {
        Tags { "Queue"="AlphaTest" "IgnoreProjector"="true" "RenderType"="TransparentCutout" }
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        Offset -1, -1
        LOD 200
        
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alphatest:_Cutout addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed  _AlphaScale;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c     = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo     = c.rgb;

            // Metallic and smoothness come from slider variables
            o.Metallic   = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha      = c.a * _AlphaScale;
        }
        ENDCG
    } 
    FallBack "Diffuse"
}