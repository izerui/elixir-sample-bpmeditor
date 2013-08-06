///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package bpm.graphic
{
  import com.ibm.ilog.elixir.diagram.Renderer;
  import com.ibm.ilog.elixir.diagram.editor.VPoolAdorner;
  
  public class VPoolAdorner extends com.ibm.ilog.elixir.diagram.editor.VPoolAdorner
  {
    public function VPoolAdorner(adornedObject:Renderer)
    {
      super(adornedObject);
    }
    /**
     * Creates a new lane. This method is called when the user presses the 'add lane' handle.
     * The default implementation returns a new <code>VLane</code>
     * 
     * @return The new <code>VLane</code> that will be added to the pool.
     * 
     * @see com.ibm.ilog.elixir.diagram.VLane
     */
    protected override function createLane():com.ibm.ilog.elixir.diagram.VLane {
      return new VLane();
    }
  }
}
