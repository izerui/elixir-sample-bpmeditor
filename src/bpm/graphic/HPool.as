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
  import com.ibm.ilog.elixir.diagram.HPool;
  
  public class HPool extends com.ibm.ilog.elixir.diagram.HPool
  {
    public function HPool()
    {
      super();
    }
    /**
     * Collapses or expands the subgraph and invalidates the current skin state.
     * 
     * <p>The HPool skin provided in this sample was created with
     * the intention to not allow a lane to be collapsed.
     * </p>
     * @default false
     */
    public override function set collapsed(value:Boolean):void 
    {
      // no-op
    }
    public override function get collapsed():Boolean
    {
      return false;
    }
  }
}
