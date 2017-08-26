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
        private enum ISSampleNum
        {
            num4    = 4,
            num8    = 8,
            num16   = 16,
            num32   = 32,
            num64   = 64,
            num128  = 128,
            num256  = 256,
            num512  = 512,
            num1024 = 1024,
        };

        public static readonly string[] indirect_diffuse_type_names =
            Enum.GetNames( typeof( IndirectDiffuseType ) );
        public static readonly string[] indirect_specular_type_names =
            Enum.GetNames( typeof( IndirectSpecularType ) );
        public static readonly string[] is_sample_num_names =
            Enum.GetNames( typeof( ISSampleNum ) );

        MaterialProperty m_IndirectDiffuseTypeProperty  = null;
        MaterialProperty m_IndirectSpecularTypeProperty = null;
        MaterialProperty m_ISSampleNumProperty          = null;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            m_IndirectDiffuseTypeProperty =
                FindProperty( "_IndirectDiffuseType", props );
            m_IndirectSpecularTypeProperty =
                FindProperty( "_IndirectSpecularType", props );
            m_ISSampleNumProperty =
                FindProperty( "_ISSampleNum", props );

            Material targetMat = materialEditor.target as Material;

            IndirectDiffuseType indirect_diffuse_type = 
                (IndirectDiffuseType) m_IndirectDiffuseTypeProperty.floatValue;
            IndirectSpecularType indirect_specular_type = 
                (IndirectSpecularType) m_IndirectSpecularTypeProperty.floatValue;
            ISSampleNum is_sample_num =
                (ISSampleNum) m_ISSampleNumProperty.floatValue;

            base.OnGUI(materialEditor, props);

            EditorGUI.BeginChangeCheck();

            indirect_diffuse_type =
                (IndirectDiffuseType) EditorGUILayout.Popup( "Indirect Diffuse Type",
                    (int) indirect_diffuse_type, indirect_diffuse_type_names );

            indirect_specular_type =
                (IndirectSpecularType) EditorGUILayout.Popup( "Indirect Specular Type",
                    (int) indirect_specular_type, indirect_specular_type_names );

            is_sample_num =
                (ISSampleNum) EditorGUILayout.Popup( "IS sample num",
                    (int) is_sample_num, is_sample_num_names );

            if (EditorGUI.EndChangeCheck())
            {
                targetMat.DisableKeyword( "INDIRECT_DIFFUSE_UNITY" );
                targetMat.DisableKeyword( "INDIRECT_DIFFUSE_LAMBERT_IS" );
                if ( indirect_diffuse_type == IndirectDiffuseType.None )
                {
                }
                else if ( indirect_diffuse_type == IndirectDiffuseType.Unity )
                {
                    targetMat.EnableKeyword( "INDIRECT_DIFFUSE_UNITY" );
                }
                else if ( indirect_diffuse_type == IndirectDiffuseType.Lambert_MonteCarlo )
                {
                    targetMat.EnableKeyword( "INDIRECT_DIFFUSE_LAMBERT_IS" );
                }

                targetMat.DisableKeyword( "INDIRECT_SPECULAR_UNITY" );
                targetMat.DisableKeyword( "INDIRECT_SPECULAR_IS" );
                if ( indirect_specular_type == IndirectSpecularType.None )
                {
                }
                else if ( indirect_specular_type == IndirectSpecularType.Unity )
                {
                    targetMat.EnableKeyword( "INDIRECT_SPECULAR_UNITY" );
                }
                else if ( indirect_specular_type == IndirectSpecularType.GGX_MonteCarlo )
                {
                    targetMat.EnableKeyword( "INDIRECT_SPECULAR_GGX_IS" );
                }

                m_IndirectDiffuseTypeProperty.floatValue  = ( float ) indirect_diffuse_type;
                m_IndirectSpecularTypeProperty.floatValue = ( float ) indirect_specular_type;
                m_ISSampleNumProperty.floatValue          = ( float ) is_sample_num;
            }
        }
    }
} // namespace UnityEditor
