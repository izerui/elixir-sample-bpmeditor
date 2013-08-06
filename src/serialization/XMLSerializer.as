///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package serialization
{
  import com.ibm.ilog.elixir.diagram.Diagram;
  import com.ibm.ilog.elixir.diagram.Graph;
  import com.ibm.ilog.elixir.diagram.Link;
  import com.ibm.ilog.elixir.diagram.Node;
  import com.ibm.ilog.elixir.diagram.PortBase;
  import com.ibm.ilog.elixir.diagram.Renderer;
  import com.ibm.ilog.elixir.diagram.Subgraph;
  
  import flash.geom.Point;
  import flash.net.getClassByAlias;
  import flash.utils.Dictionary;
  import flash.utils.describeType;
  import flash.utils.getDefinitionByName;
  import flash.utils.getQualifiedClassName;
  
  import mx.core.IVisualElement;
  import mx.formatters.NumberFormatter;
  import mx.utils.ObjectUtil;

  public class XMLSerializer
  {
    private var defaults:Dictionary;
    private var excluded:Dictionary
    private var idsbyClassName:Dictionary;
    private var objectsByID:Dictionary;
    private var idsByObject:Dictionary;
    private var forwardReferences:Array;
    private var resolvingForwardReferences:Boolean;
    private var styleDictionary:Dictionary;
    private var rootProperties:Array;
    private var numberFormatter:NumberFormatter;
    private var stylePropertiesTypes:Dictionary;
    
    public function XMLSerializer()
    {
      styleDictionary = new Dictionary();
      numberFormatter = new NumberFormatter();
      numberFormatter.useThousandsSeparator = false;
    }
    
    /**
     * Register a set of properties for the root element. These
     * properties are always serialized. 
     */
    public function set rootConfiguration(properties:Array):void
    {
      rootProperties = properties;
    }
    
    /**
     * Register a set of style properties to be serialized for a given class.
     * When serialization of style properties is required, specify the list
     * of properties that will be serialized using this method. And also register
     * a default object initialization function, to initialize the style values
     * in the default object so that their type is correctly specified.
     * 
     */
    public function registerStyleProperties(className:String, properties:Array):void
    {
      styleDictionary[className] = properties;
    }
    
    private function reset() : void
    {
      defaults = new Dictionary();
      excluded = new Dictionary();
      idsbyClassName = new Dictionary();
      objectsByID = new Dictionary();
      idsByObject = new Dictionary();
      forwardReferences = new Array();
      resolvingForwardReferences = false;
      stylePropertiesTypes = new Dictionary();
      
    }
    
    /**
     * Retrieve a default object which will be used to indicated
     * when a parameter or style value has to be serialized. It
     * is also used to know the value type for the attribute or style.
     */
    private function getDefaultObject(className:String):Object {
      var defaultObject:Object = defaults[className];
      if(defaultObject == null){
        try{ 
          var objclass:Class = getDefinitionByName(className) as Class;
          if(objclass != null){
            defaultObject = new objclass();
            defaults[className] = defaultObject;
          }
        } catch(err:Error){
          return null;
        }
      }
      return defaultObject;
    }
    
        
    // ---------------------------------------------------------------------
    // Serialization
    // ---------------------------------------------------------------------
    
    /**
     * Serialize the given object with the tag and all its children.
     * It includes the root properties that have been configured.
     * 
     * @see #deserializeTree()
     */
    public function serializeTree(object:Object, rootTag:String) : XML
    {
      reset();
      
      var root:XML = new XML("<"+rootTag+"></"+rootTag+">");
      // Add top level attributes
      serializeConfiguration(object, root);
      // Add children nodes and links
      serializeChildren(object, root, root);
      return root;
    }

    /**
     * Serialize the given object with the tag. 
     * 
     */
    public function serialize(object:Object, rootTag:String, childrenOnly:Boolean = true) : XML
    {
      reset();
      
      var root:XML = new XML("<"+rootTag+"></"+rootTag+">");
      
      if(childrenOnly){
        serializeChildren(object, root, root);
      } else {
        var child:XML = serializeObject(object, root);
        if(child != null)
          root.appendChild(child);
      }
      return root;
    }
    
    protected function serializeObject(object:Object, root:XML) : XML
    {
      var className:String = getQualifiedClassName(object);

      var defaultObject:Object = getDefaultObject(className);      
      var nameSpace:Namespace = null;
      
      var dotIndex:int = className.lastIndexOf("::");
      if(dotIndex > 0){
        var packageName:String = className.substring(0, dotIndex);
        for each(var ns:Namespace in root.namespaceDeclarations()){
          if(ns.uri == packageName){
            nameSpace = ns;
            break;
          }
        }
        if(nameSpace == null){
          var prefix:String = "";
          for each(var s:String in packageName.split("."))
            prefix += s.charAt(0).toLowerCase();
          nameSpace = new Namespace(prefix, packageName);
          root.addNamespace(nameSpace);
        }
        
        className = className.substr(dotIndex + 2);
      }
     
      var xml:XML = new XML("<"+className+"></"+className+"/>");
      
      if(nameSpace != null)
        xml.setNamespace(nameSpace);
      
      var options:Object = new Object();
      options["includeReadOnly"] = false;
      
      var excludes:Array = excluded[className] as Array;
      if(excludes == null){
        excludes = getExcludedProperties(object);
        excluded[className] = excludes;
      }
      
      var classInfo:Object = mx.utils.ObjectUtil.getClassInfo(object, excludes, options);
      var properties:Array = classInfo["properties"];
      
      xml.@id = getID(object);
      
      for each(var property:QName in properties){
        var propertyName:String = property.localName;
        try {
          var v:Object = object[propertyName];
          var defaultValue:Object = defaultObject[propertyName];
          if(v != defaultValue){
            var sv:Object = serializeProperty(object, propertyName, v, defaultValue, root);
            if(sv is XML)
              xml.appendChild(sv);
            else if(sv is String)
              xml.@[propertyName] = sv;
          }
        } catch(err:Error){
          // ignore property
        }
      }
      
      serializeStyle(object, defaultObject, xml, root);
      serializeChildren(object, xml, root);
      
      return xml;
    }
    
    private function getID(object:Object) : String
    {
      var id:String = idsByObject[object];
      
      if(id == null){
        
        var className:String = getQualifiedClassName(object);
        
        var count:int = idsbyClassName[className];
        if(!count)
          count = 0;
        count++;
        
        var s:Array = className.split("::");
        className = s[s.length-1];
        
        id = className.charAt(0).toLowerCase() + className.substring(1) + count.toString();
        while(objectsByID[id] != null){
          count++;
          id = className.charAt(0).toLowerCase() + className.substring(1) + count.toString();
        }
        
        idsbyClassName[className] = count;
        
        idsByObject[object] = id;
        objectsByID[id] = object;
      }
      
      return id;
    }
    
    private function serializeChildren(object:Object, parent:XML, root:XML) : void
    {
      var children:Array = getChildrenToSerialize(object);
      if(children != null){
        for each(var childObject:Object in children)
        {
          var child:XML = serializeObject(childObject, root);
          if(child != null)
            parent.appendChild(child);
        }
      }
    }
    
    private function getGraph(object:Object) : Graph
    {
      if(object is Graph)
        return Graph(object);
      if(object is Diagram)
        return Diagram(object).graph;
      if(object is Subgraph){
        Subgraph(object).validateNow();
        return Subgraph(object).graph;
      }
      return null;
    }
    
    protected function getChildrenToSerialize(object:Object) : Array
    {
      var graph:Graph = getGraph(object);
      if(graph != null){
        var children:Array = new Array();
        for(var i:int = 0; i < graph.numElements; i++)
          children.push(graph.getElementAt(i));
        return children;
      }
      return null;
    }
    
    protected function getExcludedProperties(object:Object) : Array
    {
      if(object is Renderer)
        return getRendererProperties();
      else
        return new Array();
    }
    
    private var rendererProperties:Array = null;
    
    private function getRendererProperties() : Array 
    {
      if(rendererProperties == null){
        rendererProperties = new Array();
        for each(var name:QName in ObjectUtil.getClassInfo(new Renderer())["properties"]){
          var pname:String = name.localName;
          if(pname != "left" &&
            pname != "top" &&
            pname != "x" &&
            pname != "y" &&
            pname != "width" &&
            pname != "height")
            rendererProperties.push(pname);
        }
      }
      return rendererProperties;
    }
    
    protected function serializeProperty(object:Object, name:String, value:Object, defaultValue:Object, root:XML) : Object
    {
      if (object is Node && name == "ports") {
          var ports:XML = new XML("<ports></ports>");
          for each(var port:PortBase in Vector.<PortBase>(value)){
              var portXML:XML = serializeObject(port, root);
              if(portXML != null)
                  ports.appendChild(portXML);
          }
        return ports;
      }
      if (object is Link) {
        if (name == "width" || name == "height")
          return null;
        if (name == "startNode" || name == "endNode")
          return null; // ports will be saved instead.
        if(name == "startPort" || name == "endPort")
          return getID(value);
        if(name == "fallbackStartPoint" || name == "fallbackEndPoint")
            return serializePropertyAsElement(name, value, root);
        if(name == "intermediatePoints"){
          var ipoints:Vector.<Point> = Vector.<Point>(value);
          if(ipoints != null && ipoints.length > 0){
            var points:XML = new XML("<intermediatePoints></intermediatePoints>");
            for each(var point:Point in ipoints){
              var pointXML:XML = serializeObject(point, root);
              if(pointXML != null)
                points.appendChild(pointXML);
            }
            return points;
          }
        }
      }
      if ((object is Graph) || (object is Subgraph)) {
        if (name == "nodeLayout") {
          return serializePropertyAsElement(name, value, root);
        } else if (name == "linkLayout") {
          return serializePropertyAsElement(name, value, root);
        }
      }

      if(value is String) {
        var propXML:XML = new XML("<"+name+"></"+name+">");
        propXML.appendChild(String(value));
        return propXML;
      }
      if(value is int || value is Boolean)
        return value.toString();
      
      if(value is Number && !isNaN(Number(value))){
        //return Number(value).toFixed();
        return numberFormatter.format(value);
      }
      
      return null;
    }
  
    protected function serializePropertyAsElement(name:String, value:Object, root:XML) : XML
    {
      var propXML:XML = new XML("<"+name+"></"+name+">");
      var valueXML:XML = serializeObject(value, root);
      if(valueXML != null){
        propXML.appendChild(valueXML);
        return propXML;
      } else {
        return null;
      }
    }
    
    /**
     * Serialize the style information for the given object.
     * The style information required must have been previously
     * registered for the object class.
     */
    private function serializeStyle(object:Object, defaultObject:Object, parent:XML, root:XML): void
    {
      var className:String = getQualifiedClassName(object);
      var styleProperties:Array = styleDictionary[className];
      
    if (styleProperties) {
        var appendXML:Boolean = false;
        var styleXML:XML = new XML("<styles></styles>");
        
        for each(var styleName:String in styleProperties) {
          try {
            var v:Object = object.getStyle(styleName);
              var sv:Object = serializeProperty(object, styleName, v, null, root);
              if(sv is XML) {
                styleXML.appendChild(sv);
                appendXML = true;
              } else if(sv is String) {
                styleXML.@[styleName] = sv;
                appendXML = true;
              }
          } catch(err:Error){
            // ignore property
          }
        }
        if (appendXML)
          parent.appendChild(styleXML);        
      }
    }
    
    private function serializeConfiguration(object:Object, root:XML):void
    {
      var className:String = getQualifiedClassName(object);      
      var defaultObject:Object = getDefaultObject(className);
      
      for each(var propertyName:String in rootProperties){
        try {
          var v:Object = object[propertyName];
          var defaultValue:Object = defaultObject[propertyName];
          if (v != defaultValue) {
            var sv:Object = serializeProperty(object, propertyName, v, defaultValue, root);
            if(sv is XML)
              root.appendChild(sv);
            else if(sv is String)
              root.@[propertyName] = sv;
          }
        } catch(err:Error){
          // ignore property
        }
      }
    }

    // ---------------------------------------------------------
    // Deserialize
    // ---------------------------------------------------------
    
    /**
     * Deserialize the given object with its configuration and all its children.
     * @see #serializeTree()
     */
    public function deserializeTree(object:Object, xml:XML) : Object
    {
      reset();
      
      var result:Object;
      // This is the top level graph
      deserializeConfiguration(object, xml);
      for each(var child:XML in xml.elements()){
        if (object.hasOwnProperty(child.localName())) {
          continue;
        } else {
          var childObject:Object = deserializeObject(child);
          if(childObject != null){
            addDeserializedChild(object, childObject);
            deserializeChildren(childObject, child);
          }
        }
      }
      result = object;
            
      resolvingForwardReferences = true;
      
      for each(var ref:Object in forwardReferences){
        try {
          var obj:Object = ref["object"];
          var name:String = ref["name"];
          var xmlValue:String = ref["xmlValue"];
          var defaultValue:Object = ref["defaultValue"];
          var value:Object = deserializeProperty(obj, name, xmlValue, defaultValue);
          if(value != null)
            obj[name] = value;
        } catch(err:Error){}
        
        resolvingForwardReferences = true;
      }
      
      return result;
    }

    public function deserialize(object:Object, xml:XML, childrenOnly:Boolean = true) : Object
    {
      reset();
      
      var result:Object;
      
      
      if(childrenOnly){ 
        for each(var child:XML in xml.elements()){
          var childObject:Object = deserializeObject(child);
          if(childObject != null){
            addDeserializedChild(object, childObject);
            deserializeChildren(childObject, child);
          }
        }
        result = object;
      } else {
        result = deserializeObject(xml);
      }
      
      resolvingForwardReferences = true;
      
      for each(var ref:Object in forwardReferences){
        try {
          var obj:Object = ref["object"];
          var name:String = ref["name"];
          var xmlValue:String = ref["xmlValue"];
          var defaultValue:Object = ref["defaultValue"];
          var value:Object = deserializeProperty(obj, name, xmlValue, defaultValue);
          if(value != null)
            obj[name] = value;
        } catch(err:Error){}
        
        resolvingForwardReferences = true;
      }
      
      return result;
    }
    
    protected function deserializeObject(xml:XML) : Object
    {
      var className:String = xml.localName();
      var ns:Namespace = xml.namespace();
      if(ns != null)
        className = ns.uri + "::" + className;
      
      try{ 
        var objclass:Class = getDefinitionByName(className) as Class;
        if(objclass != null){
          var object:Object = new objclass();

          var id:String = xml.attribute("id");
          if(id != null && id != "")
            objectsByID[id] = object;
          
          for each(var att:* in xml.attributes()){
            try {
              var name:String = att.name();
              var defaultValue:Object = object[name];
              var value:Object = deserializeProperty(object, name, xml.attribute(name), defaultValue);
              if(value != null)
                object[name] = value;
            } catch(err:Error){}
          }
          
          for each(var child:XML in xml.children()){
            if(object.hasOwnProperty(child.localName()))
            {
              try {
                var name1:String = child.localName();
                var defaultValue1:Object = object[name1];
                var value1:Object = deserializeProperty(object, name1, child, defaultValue1);
                if(value1 != null)
                  object[name1] = value1;
              } catch(err:Error){}
            } else if (child.localName()=="styles") {
              deserializeStyle(object,child);
            }
          }
          return object;
        }
      } catch(err:Error){
        trace(err);
      }
      
      return null;
    }

    protected function deserializeChildren(object:Object, xml:XML) : void
    {
      for each(var child:XML in xml.children()) {
        // Style properties for the object are deserialized in deserializeObject
        if (child.localName()=="styles")
          continue;
        else if(!object.hasOwnProperty(child.localName()))
        {
          var childObject:Object = deserializeObject(child);
          if(childObject != null){
            addDeserializedChild(object, childObject);
            deserializeChildren(childObject, child);
          }
        }
      }
    }
    
    protected function addDeserializedChild(object:Object, child:Object) : void
    {
      var graph:Graph = getGraph(object);
      if(graph != null && child is IVisualElement)
        graph.addElement(IVisualElement(child));
    }
    
    protected function deserializeProperty(object:Object, name:String, xmlValue:Object, defaultValue:Object) : Object
    {
      if(object is Node && name == "ports" && (xmlValue is XML)){
        var ports:Vector.<PortBase> = new Vector.<PortBase>();
        for each(var portXML:XML in XML(xmlValue).elements()){
          var port:PortBase = deserializeObject(portXML) as PortBase;
          if(port != null)
            ports.push(port);
        }
        return ports;
      }
      
      if(object is Link){
        if(name == "startNode" || name == "endNode" ||
           name == "startPort" || name == "endPort"){
          var obj:Object = objectsByID[xmlValue];
          if(obj != null){
            return obj;
          } else if(!resolvingForwardReferences) {
            var ref:Object = new Object();
            ref["object"] = object;
            ref["name"] = name;
            ref["xmlValue"] = xmlValue;
            ref["defaultValue"] = defaultValue;
            forwardReferences.push(ref);
            return null;
          }
        } else if(name == "fallbackStartPoint" || name == "fallbackEndPoint"){
          if(xmlValue is XML)
                return deserializePropertyAsElement(XML(xmlValue));
        } else if(name == "intermediatePoints"){
          if(xmlValue is XML){
            var points:Vector.<Point> = new Vector.<Point>();
            for each(var pointXML:XML in XML(xmlValue).elements()){
              var point:Point = deserializeObject(pointXML) as Point;
              if(point != null)
                points.push(point);
            }
            return points;
            
          }
        }
      }
      
      if ((object is Graph) || (object is Subgraph)) {
        if ((name == "nodeLayout") || (name == "linkLayout")) {
          if (xmlValue is XML)
            return deserializePropertyAsElement(XML(xmlValue));
        }
      }
      
      var stringValue:String = String(xmlValue);
      
      if(stringValue != null){
        if(defaultValue is String)
          return stringValue;
        
        if(defaultValue is int)
          return parseInt(stringValue);
        
        if(defaultValue is Boolean)
            return stringValue == "true" || stringValue == "True";
        
        if(defaultValue is Number || name == "left" || name == "top")
          return parseFloat(stringValue);
      }
      
      return xmlValue;
    }
    
    protected function deserializePropertyAsElement(xmlValue:XML) : Object
    {
        var elements:XMLList = xmlValue.elements();
        if(elements.length() > 0)
            return deserializeObject(elements[0]);
        else
            return null;
    }
     
    /**
     * Deserialize attributes and children elements from the 
     * <code>styles</code> element. 
     */
    private function deserializeStyle(object:Object, xml:XML):void
    {
      var name:String;
      var value:Object;
      
      for each(var att:* in xml.attributes()){
        try {
          name = att.name();
          value = parseValueFromMedadata(object,name,xml.attribute(name));
          
          if(value != null)
            object.setStyle(name, value);
        } catch(err:Error){}
      }
      
      // String values are serialized as separate elements.
      for each(var child:XML in xml.children()){
        try {
          name = child.localName();
          value = parseValueFromMedadata(object,name,child);
          if(value != null)
            object.setStyle(name, value.toString());
        } catch(err:Error){}
      }      
    }
    
    private function parseValueFromMedadata(object:Object, propertyName:String, xmlValue:Object):Object
    {
      
      var result:Object;
      // try dictionary
      var objectClassName:String = getQualifiedClassName(object);
      var propertyType:String = stylePropertiesTypes[objectClassName +"." + propertyName];
      
      if (!propertyType) {
        // propertyType not found, need to introspect
        var describe:* = describeType(object);
        var objectMetadata:* = describe.metadata;
        
        // look for the style property on this object
        var styleProp:XMLList = objectMetadata.(@name=="Style").arg.(@key=="name").(@value==propertyName);
        
        if (styleProp.length() == 0) {
          // not found on current object, try ancestors classes
          var ancestorClass:Class;
          var ancestorClassName:String;
          var ancestors:XMLList = describe.extendsClass;
          for each(var ancestor:XML in ancestors){
            ancestorClassName = (ancestor.@type)[0];
            ancestorClass = Class(getDefinitionByName(ancestor.@type));
            objectMetadata = describeType(ancestorClass).factory.metadata;
            styleProp = objectMetadata.(@name=="Style").arg.(@key=="name").(@value==propertyName);
            if (styleProp.length() != 0) {
              break; 
            }
          }
        }
        
        if (styleProp.length() > 0) {
          propertyType = (styleProp.parent().arg.(@key=="type").@value)[0].toString(); 
        }
        
        // register in dictionary to speed-up future lookups
        stylePropertiesTypes[objectClassName +"." + propertyName] = propertyType;
      }
      
      var stringValue:String = String(xmlValue);
      result = stringValue; // fallback
      
      if(stringValue != null){
        if(propertyType == "String") {
          result = stringValue;
        } else if(propertyType == "uint" || propertyType == "int") {
          result = parseInt(stringValue);
        } else if(propertyType == "Boolean") {
          result = stringValue == "true" || stringValue == "True";
        } else if(propertyType == "Number") {
          result = parseFloat(stringValue);
        }
      }
      
      return result;
    }
    
    private function deserializeConfiguration(object:Object, root:XML):void
    {
      var className:String = getQualifiedClassName(object);      
      var defaultObject:Object = getDefaultObject(className);
      
      for each(var att:* in root.attributes()){
        try {
          var name:String = att.name();
          var defaultValue:Object = object[name];
          var value:Object = deserializeProperty(object, name, root.attribute(name), defaultValue);
          if(value != null)
            object[name] = value;
        } catch(err:Error){}
      }
      
      for each(var child:XML in root.children()){
        if(object.hasOwnProperty(child.localName()))
        {
          try {
            var name1:String = child.localName();
            var defaultValue1:Object = object[name1];
            var value1:Object = deserializeProperty(object, name1, child, defaultValue1);
            if(value1 != null)
              object[name1] = value1;
          } catch(err:Error){}
        }
      }      
    }
  }
}
