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
  import com.ibm.ilog.elixir.diagram.editor.HPoolAdorner;
  
  public class HPoolAdorner extends com.ibm.ilog.elixir.diagram.editor.HPoolAdorner
  {
    public function HPoolAdorner(adornedObject:Renderer)
    {
      super(adornedObject);
    }
    /**
     * Creates a new lane. This method is called when the user presses the 'add lane' handle.
     * The default implementation returns a new <code>HLane</code>
     * 
     * @return The new <code>HLane</code> that will be added to the pool.
     * 
     * @see com.ibm.ilog.elixir.diagram.HLane
     */
    protected override function createLane():com.ibm.ilog.elixir.diagram.HLane {
      return new HLane();
    }
  }
}
