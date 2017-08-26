// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

using System;
using UnityEngine;

namespace UnityEditor
{
    internal class IndirectShadingMonteCarloGUI : ShaderGUI
    {
        private enum IndirectDiffuseType
        {
            None,
            Unity,
            Lambert_MonteCarlo,
        };
        private enum IndirectSpecularType
        {
            None,
            Unity,
            GGX_MonteCarlo,
        };
        private enum SampleNum
        {
            num1   = 1,
            num4   = 4,
            num8   = 8,
            num16  = 16,
            num32  = 32,
            num64  = 64,
            num128 = 128,
        };

        public static readonly string[] indirect_diffuse_type_names =
            Enum.GetNames( typeof( IndirectDiffuseType ) );
        public static readonly string[] indirect_specular_type_names =
            Enum.GetNames( typeof( IndirectSpecularType ) );
        public static readonly string[] sample_num_names =
            Enum.GetNames( typeof( SampleNum ) );

        MaterialProperty m_IndirectDiffuseTypeProperty  = null;
        MaterialProperty m_IndirectSpecularTypeProperty = null;
        MaterialProperty m_SampleNumProperty            = null;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            m_IndirectDiffuseTypeProperty =
                FindProperty( "_IndirectDiffuseType", props );
            m_IndirectSpecularTypeProperty =
                FindProperty( "_IndirectSpecularType", props );
            m_SampleNumProperty =
                FindProperty( "_ISSampleNum", props );

            base.OnGUI(materialEditor, props);

            Material targetMat = materialEditor.target as Material;

            IndirectDiffuseType indirect_diffuse_type = 
                (IndirectDiffuseType) m_IndirectDiffuseTypeProperty.floatValue;

            EditorGUI.BeginChangeCheck();
            indirect_diffuse_type =
                (IndirectDiffuseType) EditorGUILayout.Popup( "Indirect Diffuse Type",
                    (int) indirect_diffuse_type, indirect_diffuse_type_names );

            if (EditorGUI.EndChangeCheck())
            {
                targetMat.DisableKeyword( "INDIRECT_DIFFUSE_UNITY" );
                targetMat.DisableKeyword( "INDIRECT_DIFFUSE_IS" );
                if ( indirect_diffuse_type == IndirectDiffuseType.None )
                {
                }
                else if ( indirect_diffuse_type == IndirectDiffuseType.Unity )
                {
                    targetMat.EnableKeyword( "INDIRECT_DIFFUSE_UNITY" );
                }
                else if ( indirect_diffuse_type == IndirectDiffuseType.Lambert_MonteCarlo )
                {
                    targetMat.EnableKeyword( "INDIRECT_DIFFUSE_IS" );
                }

                m_IndirectDiffuseTypeProperty.floatValue = (float) indirect_diffuse_type;
            }
        }
    }
} // namespace UnityEditor
