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
  import com.ibm.ilog.elixir.diagram.Subgraph;
  
  import spark.primitives.Rect;
  [SkinState("activeCollapsed")]
  [SkinState("doneCollapsed")]

  public class SubProcess extends Subgraph
  {
        [Bindable]
    public var adHoc:Boolean;
    
    /** Indicates the monitoring status: either active or done*/
    private var _monitoringStatus:String = "";

    
    public function SubProcess()
    {
      super();
            collapsedWidth = 90;
            collapsedHeight = 50;
    }
    
    
    [Bindable]
    public function get monitoringStatus():String{
      return _monitoringStatus;
    }
    
    public function set monitoringStatus(value:String):void{
      _monitoringStatus = value;
      invalidateSkinState();
    }
    
    /**
     * @inheritDoc
     */
    override protected function getCurrentSkinState() : String{
      if(monitoringStatus=="active" && collapsed ) return "activeCollapsed";
      if(monitoringStatus=="done" && collapsed ) return "doneCollapsed";
      return super.getCurrentSkinState();
    }     
    
    
  }
}
