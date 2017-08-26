# UnityCustomSurfaceShader
Several custom shader examples for Unity.

### (Type0) Surface shaders
* #pragma surface surf Standard fullforwardshadows
<img src="https://github.com/haneda-atsushi/UnityCustomSurfaceShader/blob/master/ScreenShots/surface.PNG" width="640"/>

### (Type1) Surface shaders using lighting macro
* #pragma surface surf MyBlinnPhong fullforwardshadows
<img src="https://github.com/haneda-atsushi/UnityCustomSurfaceShader/blob/master/ScreenShots/surface_lighting.PNG" width="720"/>

### (Type2) Explicit Vertex and fragment shaders
* #pragma vertex   my_vert
* #pragma fragment my_frag
<img src="https://github.com/haneda-atsushi/UnityCustomSurfaceShader/blob/master/ScreenShots/vertex_fragment.PNG" width="720"/>

### (Type3) Vertex and fragment shaders for custom standard shading
* Custom standard shading using unity builtin shader functions.
* Importance sampling for lambert IBL and GGX IBL.
<img src="https://github.com/haneda-atsushi/UnityCustomSurfaceShader/blob/master/ScreenShots/vertex_frag_standard.PNG" width="720"/>

# Recommended system requirements
* Unity 2017.1.0f3
