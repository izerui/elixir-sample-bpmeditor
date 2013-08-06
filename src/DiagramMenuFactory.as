///////////////////////////////////////////////////////////////////////////////
// Licensed Materials - Property of IBM
// 5724-Z78
// © Copyright IBM Corporation 2007, 2013. All Rights Reserved.
//
// Note to U.S. Government Users Restricted Rights:
// Use, duplication or disclosure restricted by GSA ADP Schedule
// Contract with IBM Corp.
///////////////////////////////////////////////////////////////////////////////
package
{
  import bpm.graphic.SubProcess;
  
  import com.ibm.ilog.elixir.diagram.Diagram;
  import com.ibm.ilog.elixir.diagram.Node;
  import com.ibm.ilog.elixir.diagram.Renderer;
  import com.ibm.ilog.elixir.diagram.Subgraph;
  import com.ibm.ilog.elixir.diagram.editor.DiagramEditor;
  
  import flash.events.ContextMenuEvent;
  import flash.events.MouseEvent;
  import flash.geom.Point;
  import flash.ui.ContextMenu;
  import flash.ui.ContextMenuItem;
  
  import mx.core.FlexGlobals;
  import mx.resources.IResourceManager;
  
  /**
   * Creates the popup menu for the Diagram. 
   */
  public class DiagramMenuFactory
  {
    private var diageditor:DiagramEditor;
    private var resourceManager:IResourceManager;
    private var diagramPopupMenu:ContextMenu;
    
    // Custom menu items
    private var selectAllMenuItem:ContextMenuItem;
    private var deleteMenuItem:ContextMenuItem;
    private var cutMenuItem:ContextMenuItem;
    private var copyMenuItem:ContextMenuItem;
    private var pasteMenuItem:ContextMenuItem;
    private var groupSubMenuItem:ContextMenuItem;
    private var ungroupMenuItem:ContextMenuItem;
    private var layoutMenuItem:ContextMenuItem;
    private var connectMenuItem:ContextMenuItem;
    private var renameMenuItem:ContextMenuItem;
    
    // Cache for labels used in popup menu
    private var deleteSelectedObjectsLabel:String;
    private var deleteObjectLabel:String;
    private var cutSelectedObjectsLabel:String;
    private var cutObjectLabel:String;
    private var copySelectedObjectsLabel:String;
    private var copyObjectLabel:String;
    private var layoutAllLabel:String;
    private var layoutObjectLabel:String;
    
    // Renderer that is currently with the mouse
    private var currentObject:Object;
    private var currentMouseLocationX:Number = NaN;
    private var currentMouseLocationY:Number = NaN;
    private var menuLocationX:Number = NaN;
    private var menuLocationY:Number = NaN;
    
    /**
     * Factory to create the Diagram popup menu 
     */
    public function DiagramMenuFactory(resourceMgr:IResourceManager, 
                                       editor:DiagramEditor, 
                                       diagram:Diagram)
    {
      diageditor = editor;
      resourceManager = resourceMgr;
      diagram.addEventListener(MouseEvent.MOUSE_MOVE, diagramMouseMoveHandler);
    }
        
    private function diagramMouseMoveHandler(event:MouseEvent):void
    {
      currentMouseLocationX = event.stageX;        
      currentMouseLocationY = event.stageY;
      currentObject = diageditor.graph.getHitRenderer(event.target);
    }
    
    // -----------------------------------------------------
    // Popup Menu for the Diagram
    // -----------------------------------------------------
    
    private function populatePopupMenu():void
    {
      diagramPopupMenu = new ContextMenu();
      diagramPopupMenu.hideBuiltInItems();
      addCustomItems(diagramPopupMenu);
      diagramPopupMenu.addEventListener(ContextMenuEvent.MENU_SELECT, popupMenu_menuSelect);  
    }
    
    /**
     * Enables or disables the menu items according to
     * the number of selected objects. 
     */
    private function popupMenu_menuSelect(evt:ContextMenuEvent):void {
      // Store the position of the mouse at the moment when the menu is opened
      menuLocationX = currentMouseLocationX;
      menuLocationY = currentMouseLocationY;
            
      var selObjs:Vector.<Renderer>;
      if (currentObject != null) {
        // The popup menu has been opened for a specific object.        
        selObjs = diageditor.getSelectedObjects();
        if (selObjs.indexOf(currentObject) < 0) {
          // The object is not in the selected objects list
          diageditor.deselectAll();
          diageditor.setSelected(currentObject as Renderer, true);
          deleteMenuItem.caption = deleteObjectLabel;
          copyMenuItem.caption = copyObjectLabel;
          cutMenuItem.caption = cutObjectLabel;
          renameMenuItem.visible = true;
        } else if (selObjs.length == 1) {
          // This is the only selected object
          deleteMenuItem.caption = deleteObjectLabel;
          copyMenuItem.caption = copyObjectLabel;
          cutMenuItem.caption = cutObjectLabel;
          renameMenuItem.visible = true;
        } else {
          // The object is in the selected list, so apply popup menu
          // functions to all selected objects
          deleteMenuItem.caption = deleteSelectedObjectsLabel;
          copyMenuItem.caption = copySelectedObjectsLabel;
          cutMenuItem.caption = cutSelectedObjectsLabel;
          renameMenuItem.visible = false;
        }
        selectAllMenuItem.visible = diageditor.canUngroup;
        layoutMenuItem.caption = layoutObjectLabel;
        layoutMenuItem.visible = diageditor.canUngroup;
        
        // Enable layout item only when something is configured
        selObjs = diageditor.getSelectedObjects();
        var layoutEnabled:Boolean = false;
        for each (var s:Renderer in selObjs) {
          if (s is Subgraph) {
            if ((Subgraph(s).graph.getCurrentLinkLayout() != null) ||
                (Subgraph(s).graph.getCurrentNodeLayout() != null)) {
              layoutEnabled = true;
              break;
            }
          }
        }
        layoutMenuItem.enabled = layoutEnabled;
      } else {
        // This is the background popup menu
        renameMenuItem.visible = false;
        selectAllMenuItem.visible = true;
        selectAllMenuItem.enabled = (diageditor.graph.numElements > 0);
        deleteMenuItem.caption = deleteSelectedObjectsLabel;
        copyMenuItem.caption = copySelectedObjectsLabel;
        cutMenuItem.caption = cutSelectedObjectsLabel;
        layoutMenuItem.caption = layoutAllLabel;
        layoutMenuItem.visible = true;
        layoutMenuItem.enabled = ((diageditor.graph.numElements > 0) && ((diageditor.graph.nodeLayout != null) || (diageditor.graph.linkLayout != null)));
      }
      // Connect objects is only available if two nodes are selected
      selObjs = diageditor.getSelectedObjects();
      if (selObjs.length == 2) {
        if (selObjs[0] is Node && selObjs[1] is Node) {
          connectMenuItem.visible = true;
        } else {
          connectMenuItem.visible = false;
        }
      } else {
        connectMenuItem.visible = false;
      }
      
      var hasSelection:Boolean = diageditor.hasSelection;
      deleteMenuItem.enabled = hasSelection;
      cutMenuItem.enabled = diageditor.canCopy;
      copyMenuItem.enabled = diageditor.canCopy;
      pasteMenuItem.enabled = diageditor.canPaste;

      groupSubMenuItem.enabled = FlexGlobals.topLevelApplication.canGroup;
      ungroupMenuItem.visible = diageditor.canUngroup;      
      
      copyApplicationCustomItems();
    }

    // The first visible item of the diagran context menu,
    // used by copyApplicationCustomItems to set/clear the separator.
    private var firstVisibleItem:ContextMenuItem = null;
    
    /**
     * Copies the custom menu items from the toplevel application's context menu
     * (typically the View Source and About Elixir Enterprise... items) 
     */    
    private function copyApplicationCustomItems() : void
    {
      var appMenu:ContextMenu = FlexGlobals.topLevelApplication.contextMenu;
      if(appMenu){
        var index:int = -1;
        // scan custom items in the application context menu
        for each(var item:ContextMenuItem in appMenu.customItems){
          // has the item already been copied to the diagram context menu?
          index = -1;
          for(var i:int = 0; i < diagramPopupMenu.customItems.length; i++){
            if(ContextMenuItem(diagramPopupMenu.customItems[i]).caption == item.caption){
              index = i;
              break;
            }
          }
          if(index < 0){
            // item has not yet been copied: copy it.
            index = appMenu.customItems.indexOf(item);
            var newItem:ContextMenuItem = item.clone();
            newItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
              function(event:ContextMenuEvent):void {
                // when the copied item is selected, we redispatch the event to the original
                // item in the application menu (we find it by its caption)
                for each(var appItem:ContextMenuItem in appMenu.customItems){
                  if(appItem.caption == ContextMenuItem(event.currentTarget).caption){
                    appItem.dispatchEvent(event);
                    break;
                  }
                }
              });
            // add the copied item at the same position as in the application menu:
            diagramPopupMenu.customItems.splice(index, 0, newItem);
          }
        }
        // separate the application items from the diagram items by putting a separator
        // on the first visible item of the diagram menu:
        if(index >= 0){
          if(firstVisibleItem)
            firstVisibleItem.separatorBefore = false;
          for(var j:int = index+1; j < diagramPopupMenu.customItems.length; j++){
            var nextItem:ContextMenuItem = ContextMenuItem(diagramPopupMenu.customItems[j]);
            if(nextItem.visible){
              nextItem.separatorBefore = true;
              firstVisibleItem = nextItem;
              break;
            }
          }
        }
      }
    }
    
    /**
     * Add custom items for nodes. 
     */
    private function addCustomItems(cmenu:ContextMenu):void
    {
      renameMenuItem = new ContextMenuItem(resourceManager.getString("bpmeditor", "bpmeditor.renameCurrent.label"));
      cmenu.customItems.push(renameMenuItem);
      renameMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemRenameHandler);

      connectMenuItem = new ContextMenuItem(resourceManager.getString("bpmeditor", "bpmeditor.connect.label"));
      cmenu.customItems.push(connectMenuItem);
      connectMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemConnectHandler);

      selectAllMenuItem = new ContextMenuItem(resourceManager.getString("bpmeditor", "bpmeditor.selectall.label"));
      cmenu.customItems.push(selectAllMenuItem);
      selectAllMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemSelectAllHandler);

      deleteSelectedObjectsLabel = resourceManager.getString("bpmeditor", "bpmeditor.delete.label");
      deleteObjectLabel = resourceManager.getString("bpmeditor", "bpmeditor.deleteCurrent.label");    
      deleteMenuItem = new ContextMenuItem(deleteSelectedObjectsLabel);
      cmenu.customItems.push(deleteMenuItem);
      deleteMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemDeleteHandler);
      
      cutSelectedObjectsLabel = resourceManager.getString("bpmeditor", "bpmeditor.cut.label");
      cutObjectLabel = resourceManager.getString("bpmeditor", "bpmeditor.cutCurrent.label");
      cutMenuItem = new ContextMenuItem(cutSelectedObjectsLabel);
      cmenu.customItems.push(cutMenuItem);
      cutMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemCutHandler);
      
      copySelectedObjectsLabel = resourceManager.getString("bpmeditor", "bpmeditor.copy.label");
      copyObjectLabel = resourceManager.getString("bpmeditor", "bpmeditor.copyCurrent.label");
      copyMenuItem = new ContextMenuItem(label);
      cmenu.customItems.push(copyMenuItem);
      copyMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemCopyHandler);
      
      var label:String = resourceManager.getString("bpmeditor", "bpmeditor.paste.label");
      pasteMenuItem = new ContextMenuItem(label);
      cmenu.customItems.push(pasteMenuItem);
      pasteMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemPasteHandler);
      
      label = resourceManager.getString("bpmeditor", "bpmeditor.groupSubprocess.label");
      groupSubMenuItem = new ContextMenuItem(label);
      groupSubMenuItem.separatorBefore = true;
      cmenu.customItems.push(groupSubMenuItem);
      groupSubMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemGroupSubgraphHandler);
      
      label = resourceManager.getString("bpmeditor", "bpmeditor.ungroup.label");
      ungroupMenuItem = new ContextMenuItem(label);
      cmenu.customItems.push(ungroupMenuItem);
      ungroupMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemUngroupHandler);
      
      layoutAllLabel = resourceManager.getString("bpmeditor", "bpmeditor.layout.label");
      layoutObjectLabel = resourceManager.getString("bpmeditor", "bpmeditor.layoutCurrent.label");
      layoutMenuItem = new ContextMenuItem(layoutAllLabel);
      layoutMenuItem.separatorBefore = true;
      cmenu.customItems.push(layoutMenuItem);
      layoutMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, applMenuItemLayoutHandler);
    }
    
    /**
     * Open text editor to edit object text.
     */
    private function applMenuItemRenameHandler(event:ContextMenuEvent):void 
    {
      diageditor.startEditingText(diageditor.getSelectedObjects()[0]);
    }    

    /**
     * Connect two selected nodes.
     */
    private function applMenuItemConnectHandler(event:ContextMenuEvent):void 
    {
      FlexGlobals.topLevelApplication.connectNodes();
    }    

    /**
     * Select all objects in the graph or subgraph.
     * Selection does not recursive in subgraphs.
     */
    private function applMenuItemSelectAllHandler(event:ContextMenuEvent):void 
    {
      if (currentObject is Subgraph) {
        diageditor.deselectAll();
        for each (var node:Renderer in Subgraph(currentObject).graph.getNodes()) {
          diageditor.setSelected(node, true); 
        }
        for each (var link:Renderer in Subgraph(currentObject).graph.getLinks()) {
          diageditor.setSelected(link, true);           
        }
      } else {
        diageditor.deselectAll();
        diageditor.selectAll();
      }
    }

    /**
     * Delete selected objects.
     */
    private function applMenuItemDeleteHandler(event:ContextMenuEvent):void 
    {
      diageditor.deleteSelection();
    }
    
    /**
     * Cut selected objects. 
     */
    private function applMenuItemCutHandler(event:ContextMenuEvent):void 
    {
      diageditor.cut();
    }
    
    /**
     * Copy selected objects. 
     */
    private function applMenuItemCopyHandler(event:ContextMenuEvent):void 
    {
      diageditor.copy();
    }
    
    /**
     * Paste selected objects. 
     */
    private function applMenuItemPasteHandler(event:ContextMenuEvent):void 
    {
      // Do it
      diageditor.paste();
      
      // Coordinate space of the parent
      var minx:Number = Number.MAX_VALUE;
      var miny:Number = Number.MAX_VALUE;
      var maxx:Number = Number.MIN_VALUE;
      var maxy:Number = Number.MIN_VALUE;
      
      var pastedObjects:Vector.<Renderer> = diageditor.getSelectedObjects();
      var pasted:Renderer = null;
      for each(pasted in pastedObjects){
        if (pasted is Node) {
          minx = Math.min(minx, Number(pasted.x));
          miny = Math.min(miny, Number(pasted.y));
          maxx = Math.max(maxx, Number(pasted.x + pasted.width));
          maxy = Math.max(maxy, Number(pasted.y + pasted.height));
        }
      }
      if (pasted != null) { 
        var p:Point = pasted.parent.globalToLocal(new Point(menuLocationX, menuLocationY));
        var dx:Number = p.x - minx;
        var dy:Number = p.y - miny;
        diageditor.translateSelectionOfDelta(dx, dy);        
      }
    }
    
    /**
     * Group selected objects as children of a subgraph.
     */
    private function applMenuItemGroupSubgraphHandler(event:ContextMenuEvent):void 
    {
      var subgraph:Subgraph = new SubProcess();
      subgraph.collapsed = false;
      subgraph.width = resourceManager.getNumber("bpmeditor", "bpmeditor.subprocess.default.width");
      subgraph.height = resourceManager.getNumber("bpmeditor", "bpmeditor.subprocess.default.height");
      subgraph.label = resourceManager.getString("bpmeditor", "bpmeditor.subprocess.default.label"); 
      FlexGlobals.topLevelApplication.groupObjects(subgraph);
    }
        
    /**
     * Ungroup any selected subgraphs.
     */
    private function applMenuItemUngroupHandler(event:ContextMenuEvent):void 
    {
      diageditor.ungroup();
    }
    
    /**
     * Perform layout on the whole diagram or on the selected subgraph.
     */
    private function applMenuItemLayoutHandler(event:ContextMenuEvent):void 
    {
      if (currentObject == null) {
        FlexGlobals.topLevelApplication.layoutAll();
      } else {
        FlexGlobals.topLevelApplication.layoutSelectedSubgraph();
      }
    }

    /**
     * Returns the menu displayed for the diagram. 
     */
    public function getPopupMenu():ContextMenu
    {
      if (diagramPopupMenu == null)
        populatePopupMenu();
      return diagramPopupMenu;
    }
  }
}
