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
  import com.ibm.ilog.elixir.diagram.Graph;
  import com.ibm.ilog.elixir.diagram.GraphEvent;
  import com.ibm.ilog.elixir.diagram.SubgraphEvent;
  import com.ibm.ilog.elixir.diagram.editor.DiagramEditor;
  import com.ibm.ilog.elixir.diagram.editor.DiagramEditorEvent;
  
  import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
  
  import mx.core.UIComponent;
  import mx.events.SandboxMouseEvent;
  
  /**
   * <li>The UndoManager class implements a simple undo/redo mechanism for a DiagramEditor.
   * 
   * The undo manager must be attached to a DiagramEditor instance by setting the editor property.
   * The graph is serialized (using an XMLSerializer object) when changes
   * have been done in the editor. The undo() and redo() methods restore the previous
   * state by deserializing the serialized graph.
   * 
   * <li>UndoManager 针对流程编辑器，实现了 撤消/重做 流程结构信息的功能。
   * UndoManager 作为一个property属性被设置在编辑器中，
   * 图形会被序列化（通过 XMLSerializer 对象）当编辑器发生修改后。
   * 撤消和重做会恢复到序列化/反序列化之前的状态。
   */
  public class UndoManager extends UIComponent
  {
    // The diagram editor to which to undo manager is attached
	// 加载流程编辑器对象
    private var _editor:DiagramEditor;
    
    // Contains the successive states of the graph.
	// 包含图形元素的持续性更改状态，撤消/重做需要使用上
    private var _states:Vector.<Object> = new Vector.<Object>();
    
    // Index of the current state.
	// 当前状态的index值
    private var _currentState:int = -1;
    
    // Was the graph modified since the last state change?
	// 较上次状态，该图形是否被更改过
    private var _modified:Boolean = false;
    
    private var _mouseDown:Boolean = false;
    
    private var _undoEnabled:Boolean = true;
    
    private var _undoLimit:uint = 100;
    
    protected var _serializer:XMLSerializer = new XMLSerializer();
        
    /**
     * <li>The Graph instance being modified. 
	 * <li>被更改过的图形对象
     */
    public function get graph(): Graph
    {
      return _editor.graph;
    }

    /**
     * <li>The DiagramEditor instance to which this undo manager is attached.
	 * <li>撤消管理器所包含的编辑器对象
     */
    public function get editor() : DiagramEditor
    {
      return _editor;
    }
        
    /**
     * @private
     */
    public function set editor(editor:DiagramEditor) : void 
    {
      if(_editor != null){
        editor.removeEventListener("enterFrame", enterFrameHandler);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_CREATE, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_DELETE, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_MOVE, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_RESIZE, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_REPARENT, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_CONNECT_LINK, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_CHANGE_ZORDER, handleEventForUndo);
        editor.removeEventListener(DiagramEditorEvent.EDITOR_FINISH_TEXT_EDITING, handleEventForUndo);
        editor.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
        editor.removeEventListener(SubgraphEvent.COLLAPSE_ANIMATION_END, handleSubgraphExpandCollapse);
        editor.removeEventListener(SubgraphEvent.EXPAND_ANIMATION_END, handleSubgraphExpandCollapse);
        editor.removeEventListener(GraphEvent.GRAPH_LAYOUT_END, handleGraphLayoutEnd);
      }
      
      _editor = editor;
      
      if(_editor != null){
        editor.addEventListener("enterFrame", enterFrameHandler);
        editor.addEventListener(DiagramEditorEvent.EDITOR_CREATE, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_DELETE, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_MOVE, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_RESIZE, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_REPARENT, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_CONNECT_LINK, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_CHANGE_ZORDER, handleEventForUndo);
        editor.addEventListener(DiagramEditorEvent.EDITOR_FINISH_TEXT_EDITING, handleEventForUndo);
        editor.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
        editor.addEventListener(SubgraphEvent.COLLAPSE_ANIMATION_END, handleSubgraphExpandCollapse);
        editor.addEventListener(SubgraphEvent.EXPAND_ANIMATION_END, handleSubgraphExpandCollapse);
        editor.addEventListener(GraphEvent.GRAPH_LAYOUT_END, handleGraphLayoutEnd);
        _modified = true;
      }
    }
    
    [Bindable]
    /**
     * <li>Enables or disables undo/redo for this editor.
	 * <li>开启或关闭 撤消功能
     */
    public function get undoEnabled() : Boolean
    {
      return _undoEnabled;
    }
    
    /**
     * @private
     */
    public function set undoEnabled(enabled:Boolean) : void
    {
      _undoEnabled = enabled;
      if(enabled)
        updateFlags();
      else
        clearUndo();
    }
    
    /**
     * <li>The maximum number of changes that can be undone.
	 * <li>可以被撤消的最大限制数量
     */
    public function get undoLimit() : uint
    {
      return _undoLimit;
    }
    
    /**
     * @private
     */
    public function set undoLimit(limit:uint) : void
    {
      _undoLimit = limit;
      if(_states.length > _undoLimit){
        _currentState -= _states.length - _undoLimit;
        if(_currentState < -1)
          _currentState = -1;
        _states.splice(0, _states.length - _undoLimit);
      }
    }
    
    /**
     * <li>Undoes the last changes in the editor.
     * <li>撤消编辑器最后一次的修改
     * @see #redo()
     * @see #canUndo
     * @see #canRedo
     */
    public function undo() : void
    {
      if(canUndo){
        _editor.clear();
        
        _currentState--;
        deserialize(_states[_currentState]);
        _modified = false;
        
        updateFlags();
      }
    }
    
    /**
     * <li>Redoes the last undone changes in the editor.
     * <li>恢复到撤消之前的状态
     * @see #undo()
     * @see #canUndo
     * @see #canRedo
     */
    public function redo() : void
    {
      if(canRedo){
        _editor.clear();
        
        _currentState++;
        deserialize(_states[_currentState]);
        _modified = false;
        
        updateFlags();
      }
    }
    
    [Bindable]
    /**
     * <li>Indicates whether any changes can be undone.
     * <li>是否可以撤消的标志
     * @see #undo()
     */
    public var canUndo:Boolean = false;
    
    [Bindable]
    /**
     * <li>Indicates whether any undone changes can be redone.
     * <li>是否可以重做的标志
     * @see #redo()
     */
    public var canRedo:Boolean = false;
    
    private function updateFlags() : void
    {
      canUndo = _currentState > 0;
      canRedo = _currentState < _states.length - 1;
    } 
    
    /**
     * <li>Clears the undo stack.
	 * <li>清除撤消队列,将持续性更改状态重置
     */
    public function clearUndo() : void
    {
      _states = new Vector.<Object>();
      _currentState = -1;
      _modified = true;
      
      updateFlags();
    }
    
    /**
     * <li>Causes the editor to record its state so that a change can be undone.
     * This function should be called after external changes to the graph have been done
     * (like performing a graph layout for example), to allow the changes to be undone.
	 * 
	 * <li>恢复编辑器记录的变化状态。
	 * 执行此功能后,应该调用外部图形更改后的完成api(例如: 执行图形布局),并且允许回滚撤消更改.
     */
    public function recordUndo() : void
    {
      _editor.validateNow();
      _modified = true;
    }
    
    // Called whenever something changes in the editor
	// 每当编辑器发生修改,都会触发该事件
    private function handleEventForUndo(event:DiagramEditorEvent) : void
    {
      if(event.isDefaultPrevented())
        return;
      
      if(event.type == DiagramEditorEvent.EDITOR_FINISH_TEXT_EDITING && event.textEditCancelled)
        return;
      
      _modified = true;
    }
    
    private function handleSubgraphExpandCollapse(event:SubgraphEvent) : void
    {
      _modified = true;
    }
    
    private function handleGraphLayoutEnd(event:GraphEvent) : void
    {
      _modified = true;
    }
    
    private function mouseDownHandler(event:MouseEvent) : void
    {
      _mouseDown = true;
      
      var sandboxRoot:DisplayObject = _editor.systemManager.getSandboxRoot();
      sandboxRoot.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, true);
      sandboxRoot.addEventListener(SandboxMouseEvent.MOUSE_UP_SOMEWHERE, mouseUpHandler, true);
    }
    
    private function mouseUpHandler(event:MouseEvent) : void
    {
      _mouseDown = false;
      
      var sandboxRoot:DisplayObject = _editor.systemManager.getSandboxRoot();
      sandboxRoot.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, true);
      sandboxRoot.removeEventListener(SandboxMouseEvent.MOUSE_UP_SOMEWHERE, mouseUpHandler, true);
    }
    
    private function enterFrameHandler(event:Event) : void
    {
      if(!_mouseDown && _modified && _undoEnabled){
        
        _currentState++;
        _states.splice(_currentState, _states.length - _currentState, serialize());
        if(_states.length > _undoLimit){
          _currentState -= _states.length - _undoLimit;
          if(_currentState < -1)
            _currentState = -1;
          _states.splice(0, _states.length - _undoLimit);
        }
        _modified = false;
        
        updateFlags();
      }
    }
    
    protected function serialize() : Object
    {
      var xml:XML = _serializer.serialize(_editor.graph, "undo");
      return xml;
    }
    
    protected function deserialize(serialized:Object) : void
    {
      _serializer.deserialize(_editor.graph, XML(serialized)); 
    }
  }
}
