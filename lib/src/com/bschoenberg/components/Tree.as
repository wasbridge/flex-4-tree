/*
Copyright (C) 2011 by Billy Schoenberg

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package com.bschoenberg.components
{
    import com.bschoenberg.components.events.TreeEvent;
    import com.bschoenberg.components.layouts.TreeLayout;
    import com.bschoenberg.components.layouts.supportClasses.TreeDropLocation;
    import com.bschoenberg.components.supportClasses.ITreeDataSource;
    import com.bschoenberg.components.supportClasses.ITreeItem;
    import com.bschoenberg.components.supportClasses.ITreeLayoutElement;
    import com.bschoenberg.components.supportClasses.TreeDataSource;
    
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    
    import mx.collections.IList;
    import mx.core.ClassFactory;
    import mx.core.DragSource;
    import mx.core.FlexGlobals;
    import mx.core.IFlexDisplayObject;
    import mx.core.UIComponent;
    import mx.core.mx_internal;
    import mx.effects.AnimateProperty;
    import mx.events.DragEvent;
    import mx.events.EffectEvent;
    import mx.events.TouchInteractionEvent;
    import mx.managers.DragManager;
    
    import spark.components.List;
    import spark.components.MobileApplication;
    import spark.events.RendererExistenceEvent;
    
    public class Tree extends List
    {
        private var _dataProviderChanged:Boolean;
        private var _dataSource:ITreeDataSource;
        
        private var _nodeExpanded:Boolean;
        private var _nodeCollapsed:Boolean;
        
        private var _expandNode:ITreeItem;
        private var _collapseNode:ITreeItem;
        
        private var _nodeInserted:Boolean;
        private var _insertedNode:ITreeItem;
        private var _parentNode:ITreeItem;
        
        private var _yAnimation:AnimateProperty;
        
        private var _oldVerticalScrollPosition:Number;
        private var _mouseDownPoint:Point;
        
        [Event(name="nodeCollapsed", type="com.bschoenberg.components.events.TreeEvent")]
        [Event(name="nodeExpanded", type="com.bschoenberg.components.events.TreeEvent")]
        [Event(name="nodeInserted", type="com.bschoenberg.components.events.TreeEvent")]
        
        public function Tree()
        {   
            super();
            
            layout = new TreeLayout();
            
            itemRenderer = new ClassFactory(BaseTreeItemRenderer);
            
            _yAnimation = new AnimateProperty();
            _yAnimation.addEventListener(EffectEvent.EFFECT_END, scrollAnimationEndHandler);
            
            addEventListener(TouchInteractionEvent.TOUCH_INTERACTION_STARTING,touchInteractionStarting,false,int.MAX_VALUE);
        }
        
        private function touchInteractionStarting(e:TouchInteractionEvent):void
        {
            if(DragManager.isDragging)
                e.preventDefault();
        }
        
        protected function calculateDropLocation(event:DragEvent):TreeDropLocation
        {
            return TreeLayout(layout).calculateTreeDropLocation(event);
        }
        
        protected override function partAdded(partName:String, instance:Object):void
        {
            super.partAdded(partName, instance);
            
            if (instance == dataGroup)
            {
                dataGroup.addEventListener(
                    RendererExistenceEvent.RENDERER_ADD, dataGroup_rendererAddHandler);
                dataGroup.addEventListener(
                    RendererExistenceEvent.RENDERER_REMOVE, dataGroup_rendererRemoveHandler);
            }
        }
        
        override protected function partRemoved(partName:String, instance:Object):void
        {
            if (instance == dataGroup)
            {
                dataGroup.removeEventListener(
                    RendererExistenceEvent.RENDERER_ADD, dataGroup_rendererAddHandler);
                dataGroup.removeEventListener(
                    RendererExistenceEvent.RENDERER_REMOVE, dataGroup_rendererRemoveHandler);
            }
            
            super.partRemoved(partName, instance);
        }
        
        private function dataGroup_rendererAddHandler(e:RendererExistenceEvent):void
        {
            if(!e.renderer)
                return;
            //ours must come first because list's will turn off our dragging
            e.renderer.addEventListener(MouseEvent.MOUSE_DOWN,rendererMouseDown,false,int.MAX_VALUE);
        }
        
        private function dataGroup_rendererRemoveHandler(e:RendererExistenceEvent):void
        {
            if(!e.renderer)
                return;
            e.renderer.removeEventListener(MouseEvent.MOUSE_DOWN,rendererMouseDown);
        }
        
        private function rendererMouseDown(event:MouseEvent):void
        {
            if (event.isDefaultPrevented())
                return;
            
            if(DragManager.isDragging)
            {
                event.preventDefault();
                return;
            }
            
            var renderer:ITreeLayoutElement = ITreeLayoutElement(event.currentTarget);
            renderer.addEventListener(MouseEvent.MOUSE_MOVE,rendererMouseMove,false,int.MAX_VALUE,true);
            renderer.addEventListener(MouseEvent.MOUSE_UP,rendererMouseUp,false,0,true);
            
            _mouseDownPoint = event.target.localToGlobal(new Point(event.localX, event.localY));
        }
        
        private function rendererMouseMove(event:MouseEvent):void
        {   
            if (!_mouseDownPoint || !dragEnabled)
                return;
            
            if (event.isDefaultPrevented())
                return;
            
            if(DragManager.isDragging)
            {
                event.preventDefault();
                return;
            }
            
            var pt:Point = new Point(event.localX, event.localY);
            pt = DisplayObject(event.target).localToGlobal(pt);
            
            const DRAG_THRESHOLD:int = 5;
            
            if (Math.abs(_mouseDownPoint.x - pt.x) > DRAG_THRESHOLD ||
                Math.abs(_mouseDownPoint.y - pt.y) > DRAG_THRESHOLD)
            {
                //This prevents a drag start from happening in list
                //because the silly flex developers do not check if the 
                //event is prevent defaulted
                mx_internal::mouseDownPoint = null;
                    
                var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_START);
                dragEvent.dragInitiator = this;
                dragEvent.draggedItem = event.currentTarget;
                var localMouseDownPoint:Point = this.globalToLocal(_mouseDownPoint);
                
                dragEvent.localX = localMouseDownPoint.x;
                dragEvent.localY = localMouseDownPoint.y;
                dragEvent.buttonDown = true;
                
                // We're starting a drag operation, remove the handlers
                // that are monitoring the mouse move, we don't need them anymore:
                dispatchEvent(dragEvent);
                
                // Finally, remove the mouse handlers
                var renderer:ITreeLayoutElement = ITreeLayoutElement(event.currentTarget);
                renderer.removeEventListener(MouseEvent.MOUSE_MOVE,rendererMouseMove);
                renderer.removeEventListener(MouseEvent.MOUSE_UP,rendererMouseUp);
            }
        }
        
        private function rendererMouseUp(e:MouseEvent):void
        {
            var renderer:ITreeLayoutElement = ITreeLayoutElement(e.currentTarget);
            renderer.removeEventListener(MouseEvent.MOUSE_MOVE,rendererMouseMove);
            renderer.removeEventListener(MouseEvent.MOUSE_UP,rendererMouseUp);
        }
        
        public override function createDragIndicator():IFlexDisplayObject
        {
            var di:UIComponent = dataGroup.itemRenderer.newInstance();
            di.width = width * .75;
            di.height = TreeLayout(layout).rowHeight;
            di.owner = this;
            di.setStyle("contentBackgroundColor",getStyle("contentBackgroundColor"));
            di.setStyle("contentBackgroundAlpha",getStyle("contentBackgroundAlpha"));
            ITreeLayoutElement(di).dragging = true;
            return IFlexDisplayObject(di);
        }
        
        protected override function dragStartHandler(event:DragEvent):void
        {
            if(event.draggedItem == null)
                return;
            
            var renderer:ITreeLayoutElement = ITreeLayoutElement(event.draggedItem);
            addEventListener(DragEvent.DRAG_DROP,dragDropHandler);
            
            var di:IFlexDisplayObject = createDragIndicator();
            ITreeLayoutElement(di).data = renderer.data;
            
            var ds:DragSource = new DragSource();
            ds.addData(renderer.data,"tree-item");
            
            var xOffset:Number = -mouseX + 12;
            var yOffset:Number = -mouseY + di.height/2;
            
            DragManager.doDrag(this,ds,event,di,xOffset,yOffset,1); 
        }
        
        protected override function dragEnterHandler(event:DragEvent):void
        {
            if(event.dragInitiator ==  this && !dragMoveEnabled)
            {
                DragManager.showFeedback(DragManager.NONE);
                return;
            }
            
            DragManager.acceptDragDrop(this);
        }
        
        protected override function dragOverHandler(event:DragEvent):void
        {
            if (event.isDefaultPrevented())
                return;
            
            var dropLocation:TreeDropLocation = calculateDropLocation(event);
            
            // Notify manager we can drop
            DragManager.showFeedback(DragManager.COPY);
            
            // Show drop indicator
            TreeLayout(layout).showTreeDropIndicator(dropLocation);
        }
        
        protected override function dragExitHandler(event:DragEvent):void
        {
            if (event.isDefaultPrevented())
                return;
            
            // Hide if previously showing
            layout.hideDropIndicator();
            
            // Hide focus
            drawFocus(false);
            
            // Destroy the dropIndicator instance
            destroyDropIndicator();
        }
        
        protected override function dragDropHandler(event:DragEvent):void
        {
            if(event.dragInitiator ==  this && !dragMoveEnabled)
                return;
            
            var itemToAdd:ITreeItem = ITreeItem(event.dragSource.dataForFormat("tree-item"));
            
            var dl:TreeDropLocation = TreeLayout(layout).calculateTreeDropLocation(event);
            if(dl.parentDropIndex == -1)
            {
                if(_dataSource == null)
                    dataSource = new TreeDataSource();
                if(dl.dropIndex > dataSource.items.length)
                    dl.dropIndex = dataSource.items.length;
                
                if(event.dragInitiator == this)
                    dataSource.moveItem(itemToAdd,dl.dropIndex);
                else
                    dataSource.addItemAt(itemToAdd,dl.dropIndex,null,false);
            }
            else
            {
                var dropRenderer:ITreeLayoutElement = ITreeLayoutElement(dataGroup.getElementAt(dl.parentDropIndex));
                var parentItem:ITreeItem = ITreeItem(dropRenderer.data);
                parentItem.expanded = true;
                if(dl.dropIndex > parentItem.items.length)
                    dl.dropIndex = dataSource.items.length;
                
                if(itemToAdd == parentItem ||
                    itemToAdd.hasDescendant(parentItem))
                    return;
                
                if(event.dragInitiator == this)
                    dataSource.moveItem(itemToAdd,dl.dropIndex,parentItem);
                else
                    parentItem.addItemAt(itemToAdd,dl.dropIndex,false);
            }
            
            //since we are scolling ourself here, just do the update
            //manager the scroll locations
            var oldVerticalScrollPosition:Number = dataGroup.verticalScrollPosition;
            super.dataProvider = dataSource.expandedItems;
            dataGroup.invalidateDisplayList();
            dataGroup.validateNow();
            dataGroup.verticalScrollPosition = oldVerticalScrollPosition;
            _dataProviderChanged = false;
            
            var rowHeight:Number = TreeLayout(layout).rowHeight;
            var myIndex:int = dataSource.expandedItems.getItemIndex(itemToAdd);
            
            var myY:Number = (myIndex + .5) * rowHeight;            
            var scrollY:Number = Math.max(0, myY - mouseY);
            
            //don't scroll just halfway down the first item
            //that looks like garbage
            if(scrollY - rowHeight <=0)
                return;
            scroll(scrollY);
        }
        
        protected function nodeInsertedHandler(e:TreeEvent):void
        {
            _nodeInserted = true;
            _insertedNode = e.node;
            //trace("INSERTED: " + Object(_insertedNode).id);
            invalidateProperties();
        }
        
        protected function nodeExpandedHandler(e:TreeEvent):void
        {
            _nodeExpanded = true;
            _expandNode = e.node;
            //trace("EXPANDED: " + Object(_expandNode).id);
            invalidateProperties();
        }
        
        protected function nodeCollapsedHandler(e:TreeEvent):void
        {
            _nodeCollapsed = true;
            _collapseNode = e.node;
            //trace("COLLAPSED: " + Object(_expandNode).id);
            invalidateProperties();
        }
        
        public function scroll(verticalScrollPosition:Number, 
                               animate:Boolean=true):void
        {
            if(!animate)
            {
                dataGroup.verticalScrollPosition = verticalScrollPosition;
                dispatchEvent(new TreeEvent(TreeEvent.SCROLL_COMPLETE,null,null,false));
                return;
            }
            
            var duration:Number = Math.abs(verticalScrollPosition - dataGroup.verticalScrollPosition) * 10;
            _yAnimation.addEventListener(EffectEvent.EFFECT_UPDATE,scrollEffectHandler,false,0,true);
            _yAnimation.addEventListener(EffectEvent.EFFECT_END,scrollEffectHandler,false,0,true);
            _yAnimation.duration = Math.min(1000,Math.max(100,duration));
            _yAnimation.fromValue = dataGroup.verticalScrollPosition;
            _yAnimation.toValue = verticalScrollPosition;
            _yAnimation.property = "verticalScrollPosition";
            _yAnimation.target = dataGroup;
            _yAnimation.play();
        }
        
        private function scrollEffectHandler(e:Event):void
        {
            skin.invalidateDisplayList();
        }
        
        private function scrollAnimationEndHandler(e:EffectEvent):void
        {
            //we get this listener called twice which means we execute its handler too many
            //times
            dispatchEvent(new TreeEvent(TreeEvent.SCROLL_COMPLETE,null,null,false));
        }
        
        public function getTreeLayoutElement(item:ITreeItem):ITreeLayoutElement
        {
            var element:ITreeLayoutElement;
            for (var i:int = 0; i < dataGroup.numElements; i++)
            {
                element = ITreeLayoutElement(dataGroup.getElementAt(i));
                if(element && element.data == item)
                    return element;
            }
            
            return null;
        }
        
        protected override function commitProperties():void
        {
            super.commitProperties();
            
            var tLayout:TreeLayout = TreeLayout(layout);
            
            if(_dataProviderChanged && 
                !_nodeCollapsed &&
                !_nodeExpanded)
            {
                updateDataProvider();
            }
            
            if(_nodeCollapsed && _nodeExpanded)
            {
                _nodeExpanded = false;
                _nodeCollapsed = false;
                //oddball case
                updateDataProvider();
                
            }
            else if(_nodeCollapsed)
            {
                _nodeCollapsed = false;
                tLayout.collapsingNodes = _collapseNode.getAllExpandedItems();
                
                if(tLayout.animate)
                    //we cannot just update the data provider here, we need to 
                    //wait for the tree layout to tell us that it has animated them all
                    //away and its okay to remove them now
                    tLayout.runAfterLayoutComplete(updateDataProvider);
                else
                    updateDataProvider();
            }
            else if(_nodeExpanded)
            {
                _nodeExpanded = false;
                tLayout.expandingNodes = _expandNode.getAllExpandedItems();
                //here we want to update the data provider so that the node renderers
                //are created
                updateDataProvider();
            }
            else if(_nodeInserted)
            {
                _nodeInserted = false;
                tLayout.insertedNode = _insertedNode;
                //here we want to update the data provider so that the node renderers
                //are created
                updateDataProvider();
            }
        }
        
        private function updateDataProvider():void
        {
            if($dataProvider != _dataSource.expandedItems)
            {
                dataGroup.invalidateDisplayList();
                skin.invalidateDisplayList();
                $dataProvider = _dataSource.expandedItems;
            }
            _dataProviderChanged = false;
        }
        
        public override function set dataProvider(value:IList):void
        {  
            throw new Error("No set data provider");
        }
        
        [Bindable]
        public function get dataSource():ITreeDataSource
        {
            return _dataSource;
        }
        
        private function purgeEventListeners():void
        {
            dataSource.removeEventListener(TreeEvent.NODE_INSERTED,nodeInsertedHandler);
            dataSource.removeEventListener(TreeEvent.NODE_EXPANDED, nodeExpandedHandler);
            dataSource.removeEventListener(TreeEvent.NODE_COLLAPSED, nodeCollapsedHandler);
        }
        
        private function addEventListeners():void
        {
            dataSource.addEventListener(TreeEvent.NODE_INSERTED,nodeInsertedHandler);
            dataSource.addEventListener(TreeEvent.NODE_EXPANDED, nodeExpandedHandler);
            dataSource.addEventListener(TreeEvent.NODE_COLLAPSED, nodeCollapsedHandler);
        }
        
        public function set dataSource(value:ITreeDataSource):void
        {
            if(_dataSource)
                purgeEventListeners();
            _dataSource = value;
            if(_dataSource)
                addEventListeners();
            
            _dataProviderChanged = true;
            invalidateProperties();
        }
        
        private function dataSourceChangeHandler(e:Event):void
        {
            _dataProviderChanged = true;
            invalidateProperties();
        }
        
        private function get $dataProvider():IList 
        {
            return super.dataProvider;
        }
        
        private function set $dataProvider(value:IList):void
        {
            _oldVerticalScrollPosition = dataGroup.verticalScrollPosition;
            super.dataProvider = value;
            dataGroup.addEventListener(Event.RENDER,updateCompleteHandler);
            dataGroup.invalidateProperties();
            dataGroup.invalidateDisplayList();
        }
        
        private function updateCompleteHandler(e:Event):void
        {
            dataGroup.removeEventListener(Event.RENDER,updateCompleteHandler);
            if(isNaN(_oldVerticalScrollPosition))
                return;
            dataGroup.verticalScrollPosition = _oldVerticalScrollPosition;
            _oldVerticalScrollPosition = NaN;
        }
    }
}