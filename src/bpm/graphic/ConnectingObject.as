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
    import com.ibm.ilog.elixir.diagram.Link;
    import com.ibm.ilog.elixir.diagram.LinkDecoration;
    [SkinState("active")]
    [SkinState("done")]

    public class ConnectingObject extends Link
    {
        [SkinPart(required = true)]
        public var labelElement:LinkDecoration;
        
        [Bindable]
        public var label:String;
     
        /** Indicates the monitoring status: either active or done*/
        private var _monitoringStatus:String = "";

        /** Indicates the monitoring delay between every nodes, this is used to animate
        * the ConnectingObject skin */
        private var _monitoringDelay:Number = 2000;
        
        public function ConnectingObject(){
            
        }
        
        [Bindable]
        public function get monitoringStatus():String{
          return _monitoringStatus;
        }
        
        public function set monitoringStatus(value:String):void{
          _monitoringStatus = value;
          invalidateSkinState();
        }   
        
        [Bindable]
        public function get monitoringDelay():Number{
          return _monitoringDelay;
        }
        
        public function set monitoringDelay(value:Number):void{
          _monitoringDelay = value;
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
