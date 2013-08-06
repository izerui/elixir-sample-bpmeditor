///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package bpm.graphic.icons
{
  import spark.components.supportClasses.SkinnableComponent;
  
  public class BPMNIcon extends SkinnableComponent
  {
    [Bindable]
    public var filled:Boolean = false;
    
    [Bindable]
    public var fillColor:uint = 0xffffff;
    
    [Bindable]
    public var closedStrokeColor:uint = 0x000000;
    
    [Bindable]
    public var openStrokeColor:uint = 0x000000;
    
    public function BPMNIcon()
    {
      super();
    }
  }
}
