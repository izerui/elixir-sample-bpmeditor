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
  import spark.primitives.Path;
  import spark.primitives.supportClasses.GraphicElement;

  public class TextAnnotation extends Artifact
  {
    [Bindable]
    public var bracketOnRight:Boolean;
    
    public function TextAnnotation()
    {
      super();
    }
  }
}
