///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package bpm.graphic.editor
{
  import bpm.graphic.TextAnnotation;
  
  import com.ibm.ilog.elixir.diagram.Renderer;
  import com.ibm.ilog.elixir.diagram.editor.NodeAdorner;
  
  import flash.display.DisplayObject;
  
  public class TextAnnotationAdorner extends NodeAdorner
  {
    public function TextAnnotationAdorner(adornedObject:Renderer)
    {
      super(adornedObject);
    }
    
    /**
     * @private
     */
    protected override function partAdded(partName:String, instance:Object) : void
    {
      super.partAdded(partName, instance);
      
      if(isLinkHandle(instance)){
        DisplayObject(instance).visible =
          instance == (TextAnnotation(adornedObject).bracketOnRight ? rightHandle : leftHandle);
      }
    }
  }
}
