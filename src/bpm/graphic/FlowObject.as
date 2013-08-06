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
  import com.ibm.ilog.elixir.diagram.Node;
  
  [SkinState("active")]
  [SkinState("done")]
  
  public class FlowObject extends Node
  {
    /** Indicates the monitoring status: either active or done*/
    private var _monitoringStatus:String = "";
    
    public function FlowObject()
    {
      super();
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
      if(monitoringStatus=="active") return "active";
      if(monitoringStatus=="done") return "done";
      return super.getCurrentSkinState();
    }     
    
    
    
  }
}
