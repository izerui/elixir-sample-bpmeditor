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
  import com.ibm.ilog.elixir.diagram.LinkShapeType;

    public class MessageFlow extends ConnectingObject
    {
        public function MessageFlow()
        {
            super();
            shapeType = LinkShapeType.ORTHOGONAL;
        }
    }
}
