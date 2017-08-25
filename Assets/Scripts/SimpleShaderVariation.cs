using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Assertions;

public class SimpleShaderVariation : MonoBehaviour
{
    Material m_Material;

	// Use this for initialization
	void Start()
    {
        Renderer renderer = GetComponent<Renderer>();
        Assert.IsNotNull( renderer );

        m_Material = renderer.sharedMaterial;
        Assert.IsNotNull( m_Material );
	}
	
	// Update is called once per frame
	void Update ()
    {
        float force_base_color = m_Material.GetFloat( "_ForceBaseColor" );
        // Debug.Log( "force_base_color = " + force_base_color );

        m_Material.DisableKeyword( "FORCE_BASE_COLOR_RED" );
        m_Material.DisableKeyword( "FORCE_BASE_COLOR_GREEN" );
        m_Material.DisableKeyword( "FORCE_BASE_COLOR_BLUE" );
        if ( force_base_color == 0.0f )
        {
        }
        else if ( force_base_color == 1.0f )
        {
            m_Material.EnableKeyword( "FORCE_BASE_COLOR_RED" );
        }
        else if ( force_base_color == 2.0f )
        {
            m_Material.EnableKeyword( "FORCE_BASE_COLOR_GREEN" );
        }
        else if ( force_base_color == 3.0f )
        {
            m_Material.EnableKeyword( "FORCE_BASE_COLOR_BLUE" );
        }
	}
}
