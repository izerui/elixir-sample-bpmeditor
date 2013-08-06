///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package bpm.port
{
  import com.ibm.ilog.elixir.diagram.Link;
  import com.ibm.ilog.elixir.diagram.PortBase;
  
  import flash.display.DisplayObject;
  import flash.errors.IllegalOperationError;
  import flash.geom.Point;
  import flash.geom.Rectangle;

  public class OrthogonalPort extends PortBase
  {
    public function OrthogonalPort()
    {
    }
    
    override public function getConnectionPoint(link:Link, referencePoint:Point, targetCoordinateSpace:DisplayObject, connectionPoint:Point, originPoint:Point, origin:Boolean=true):void{
      
      if (!owner)
        throw new IllegalOperationError("Cannot compute connection point when owner is null");
      
      if (!link)
        throw new ArgumentError("link must not be null");
      
      if (!referencePoint)
        throw new ArgumentError("referencePoint must not be null");
      
      if (!targetCoordinateSpace)
        throw new ArgumentError("targetCoordinateSpace must not be null");
    
      if (!connectionPoint)
        throw new ArgumentError("connectionPoint must not be null");
      
      if (!originPoint)
        throw new ArgumentError("originPoint must not be null");
      
      // Get the bounds of the owner object.
      //
      var bounds:Rectangle = owner.getNodeOrBaseBounds(targetCoordinateSpace);
      

      // Determine in which quadrant the reference point is with respect to the owner bounds
      //
      if (referencePoint.y < bounds.y)
      {
        // Reference point is above the object:
        // connect on top, keeping the same X position as the reference point.
        //
        connectionPoint.x = Math.max(bounds.x, Math.min(referencePoint.x, bounds.right));
        connectionPoint.y = bounds.y;
        originPoint.x = connectionPoint.x;
        originPoint.y = bounds.y + bounds.height / 2;
  
      }
      else if (referencePoint.y > bounds.bottom)
      {
        // Reference point is below the object:
        // connect to the bottom, keeping the same X position as the reference point.
        //
        connectionPoint.x = Math.max(bounds.x, Math.min(referencePoint.x, bounds.right));
        connectionPoint.y = bounds.bottom;
        originPoint.x = connectionPoint.x;
        originPoint.y = bounds.y + bounds.height / 2;
   
      }
      else if (referencePoint.x < bounds.x)
      {
        // Reference point is on the left of the object:
        // connect to the left, keeping the same Y position as the reference point.
        //
        connectionPoint.x = bounds.x;
        connectionPoint.y = referencePoint.y;
        originPoint.x = bounds.x + bounds.width / 2;
        originPoint.y = referencePoint.y;
   
      }
      else if (referencePoint.x > bounds.right)
      {
        // Reference point is on the right of the object:
        // connect to the right, keeping the same Y position as the reference point.
        //
        connectionPoint.x = bounds.right;
        connectionPoint.y = referencePoint.y;
        originPoint.x = bounds.x + bounds.width / 2;
        originPoint.y = referencePoint.y;
  
      }
      else if (referencePoint.y < bounds.y + bounds.height / 2)
      {
        // Reference point is inside the object, in the upper half:
        // connect to the top, keeping the same X position as the reference point.
        //
        connectionPoint.x = referencePoint.x;
        connectionPoint.y = bounds.y;
        originPoint.x = referencePoint.x;
        originPoint.y = bounds.y + bounds.height / 2;
    
      }
      else
      {
        // Reference point is inside the object, in the lower half:
        // connect to the bottom, keeping the same X position as the reference point.
        //
        connectionPoint.x = referencePoint.x;
        connectionPoint.y = bounds.bottom;
        originPoint.x = referencePoint.x;
        originPoint.y = bounds.y + bounds.height / 2;
   
      }
      
      
    }
    
  }
}
