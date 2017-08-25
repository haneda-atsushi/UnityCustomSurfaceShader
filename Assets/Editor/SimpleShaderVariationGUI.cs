// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

using System;
using UnityEngine;

namespace UnityEditor
{
    internal class SimpleShaderVariationGUI : ShaderGUI
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            base.OnGUI(materialEditor, props);

            Material targetMat = materialEditor.target as Material;

            bool use_texture = 
                Array.IndexOf(targetMat.shaderKeywords, "USE_TEXTURE") != -1;
            EditorGUI.BeginChangeCheck();
            use_texture = EditorGUILayout.Toggle( "Use Texture", use_texture );
            if (EditorGUI.EndChangeCheck())
            {
                if ( use_texture)
                {
                    targetMat.EnableKeyword( "USE_TEXTURE" );
                }
                else
                {
                    targetMat.DisableKeyword( "USE_TEXTURE" );
                }
            }
        }
    }
} // namespace UnityEditor
