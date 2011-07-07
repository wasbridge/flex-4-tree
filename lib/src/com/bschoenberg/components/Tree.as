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
    import com.bschoenberg.components.skins.TreeSkin;
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
    import mx.core.IFlexDisplayObject;
    import mx.core.UIComponent;
    import mx.core.mx_internal;
    import mx.effects.AnimateProperty;
    import mx.events.DragEvent;
    import mx.events.EffectEvent;
    import mx.managers.DragManager;
    
    import spark.components.List;
    import spark.events.RendererExistenceEvent;
    import spark.layouts.supportClasses.DropLocation;
    
    /**
     * Flex 4 Spark Tree component.  It extends List.  
     * Its item renderers must implement ITreeLayoutElement.  It does not use
     * a dataProvider, but rather a dataSource which much implement the ITreeDataSource
     * interface.  All items renderered by the Tree must be of type ITreeItem
     */ 
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
        
        /**
         * Dispatched when the tree is done scrolling after a call to scroll()
         *
         * @eventType com.bschoenberg.components.events.TreeEvent.SCROLL_COMPLETE
         */
        [Event(name="scrollComplete", type="com.bschoenberg.components.events.TreeEvent")]
        
        public function Tree()
        {   
            super();
            
            layout = new TreeLayout();
            setStyle("skinClass",TreeSkin);
            itemRenderer = new ClassFactory(TreeItemRenderer);
            
            _yAnimation = new AnimateProperty();
            _yAnimation.addEventListener(EffectEvent.EFFECT_END, scrollAnimationEndHandler);
        }
        
        /**
         * This methods figures out where to drop an item based on its dragevent
         * 
         * @param event The DragEvent to use to figure out where in the dataSource to drop the item
         * 
         * @return A TreeDropLocation describing where the item will be placed
         */ 
        protected function calculateDropLocation(event:DragEvent):TreeDropLocation
        {
            return TreeLayout(layout).calculateTreeDropLocation(event);
        }
        
        /**
         * This handler allows us to hook into mouse down on item renderers.
         * 
         * Our handler must come first so that we can support dragging and drag scrolling
         */ 
        protected override function dataGroup_rendererAddHandler(e:RendererExistenceEvent):void
        {
            super.dataGroup_rendererAddHandler(e);
            if(!e.renderer)
                return;
            //ours must come first because list's will turn off our dragging
            e.renderer.addEventListener(MouseEvent.MOUSE_DOWN,rendererMouseDown,false,int.MAX_VALUE);            
        }
        
        /**
         * This handler allows us to clean up after ourself
         */ 
        protected override function dataGroup_rendererRemoveHandler(e:RendererExistenceEvent):void
        {
            super.dataGroup_rendererRemoveHandler(e);
            if(!e.renderer)
                return;
            e.renderer.removeEventListener(MouseEvent.MOUSE_DOWN,rendererMouseDown);
        }
        
        /**
         * Track and hold mouse down positions from the item renderers
         */ 
        private function rendererMouseDown(event:MouseEvent):void
        {
            //if the renderer has told us to stop, stop
            if (event.isDefaultPrevented())
                return;
            
            //if we are dragging stop our parents from reacting
            if(DragManager.isDragging)
            {
                event.preventDefault();
                return;
            }
            
            //get the renderer and listen for drags or releases
            var renderer:ITreeLayoutElement = ITreeLayoutElement(event.currentTarget);
            renderer.addEventListener(MouseEvent.MOUSE_MOVE,rendererMouseMove,false,int.MAX_VALUE,true);
            renderer.addEventListener(MouseEvent.MOUSE_UP,rendererMouseUp,false,0,true);
            
            _mouseDownPoint = event.target.localToGlobal(new Point(event.localX, event.localY));
        }
        
        /**
         * Handle dragging of the renderer
         */ 
        private function rendererMouseMove(event:MouseEvent):void
        {   
            //if we don't have a start point or dragging is not enabled
            if (!_mouseDownPoint || !dragEnabled)
                return;
            
            //f we have been told to stop, stop
            if (event.isDefaultPrevented())
                return;
            
            //if we are dragging stop and tell our parents to stop
            if(DragManager.isDragging)
            {
                event.preventDefault();
                return;
            }
            
            var pt:Point = new Point(event.localX, event.localY);
            pt = DisplayObject(event.target).localToGlobal(pt);
            const DRAG_THRESHOLD:int = 10;
            
            //if we are outside of the drag threshold (a drag event has started)
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
        
        /**
         * Clean up our event handlers on the renderer
         */ 
        private function rendererMouseUp(e:MouseEvent):void
        {
            var renderer:ITreeLayoutElement = ITreeLayoutElement(e.currentTarget);
            renderer.removeEventListener(MouseEvent.MOUSE_MOVE,rendererMouseMove);
            renderer.removeEventListener(MouseEvent.MOUSE_UP,rendererMouseUp);
        }
        
        /**
         * @inheritDoc
         */ 
        public override function createDragIndicator():IFlexDisplayObject
        {
            //make a new item renderer for dragging
            var di:UIComponent = dataGroup.itemRenderer.newInstance();
            di.width = width * .75;
            di.height = TreeLayout(layout).rowHeight;
            di.owner = this;
            di.setStyle("contentBackgroundColor",getStyle("contentBackgroundColor"));
            di.setStyle("contentBackgroundAlpha",getStyle("contentBackgroundAlpha"));
            ITreeLayoutElement(di).dragging = true;
            return IFlexDisplayObject(di);
        }
        
        /**
         * @inheritDoc
         */ 
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
            
            //do the drag using the drag indicator
            DragManager.doDrag(this,ds,event,di,xOffset,yOffset,1); 
        }
        
        /**
         * @inheritDoc
         */ 
        protected override function dragEnterHandler(event:DragEvent):void
        {
            if(event.dragInitiator ==  this && !dragMoveEnabled)
            {
                DragManager.showFeedback(DragManager.NONE);
                return;
            }
            
            DragManager.acceptDragDrop(this);
            
            // Create the dropIndicator instance. The layout will take care of
            // parenting, sizing, positioning and validating the dropIndicator.
            createDropIndicator();
            
            // Notify manager we can drop
            DragManager.showFeedback(event.ctrlKey ? DragManager.COPY : DragManager.MOVE);
            
            // Show drop indicator
            layout.showDropIndicator(layout.calculateDropLocation(event));
        }
        
        /**
         * @inheritDoc
         */ 
        protected override function dragOverHandler(event:DragEvent):void
        {
            if (event.isDefaultPrevented())
                return;
            
            var dropLocation:DropLocation = layout.calculateDropLocation(event);
            if (dropLocation)
            {
                // Notify manager we can drop
                DragManager.showFeedback(event.ctrlKey ? DragManager.COPY : DragManager.MOVE);
                
                // Show drop indicator
                layout.showDropIndicator(dropLocation);
            }
            else
            {
                // Hide if previously showing
                layout.hideDropIndicator();
                
                // Notify manager we can't drop
                DragManager.showFeedback(DragManager.NONE);
            }
        }
        
        /**
         * @inheritDoc
         */ 
        protected override function dragExitHandler(event:DragEvent):void
        {
            if (event.isDefaultPrevented())
                return;
            
            // Hide if previously showing
            layout.hideDropIndicator();
            
            // Destroy the dropIndicator instance
            destroyDropIndicator();
        }
        
        /**
         * @inheritDoc
         */ 
        protected override function dragDropHandler(event:DragEvent):void
        {
            if(event.dragInitiator ==  this && !dragMoveEnabled)
                return;
            
            layout.hideDropIndicator();
            
            var itemToAdd:ITreeItem = ITreeItem(event.dragSource.dataForFormat("tree-item"));
            
            var dl:TreeDropLocation = TreeLayout(layout).calculateTreeDropLocation(event);
            //new top level item
            
            if(dl.parentDropIndex == -1)
            {
                if(_dataSource == null)
                    dataSource = new TreeDataSource();
                
                if(dl.dropIndex > dataSource.items.length)
                    dl.dropIndex = dataSource.items.length;
                
                //if we are the initiator do a move, otherwise an add
                if(event.dragInitiator == this)
                {
                    if(dl.dropIndex < dataSource.items.length &&
                        itemToAdd == dataSource.items.getItemAt(dl.dropIndex))
                        return;
                    
                    dataSource.moveItem(itemToAdd,dl.dropIndex);
                }
                else
                {
                    dataSource.addItemAt(itemToAdd,dl.dropIndex,null,false);
                }
            }
            else
            {
                var parentRenderer:ITreeLayoutElement = 
                    ITreeLayoutElement(dataGroup.getElementAt(dl.parentDropIndex));
                var parentItem:ITreeItem = ITreeItem(parentRenderer.data);
                parentItem.expanded = true;
                if(dl.dropIndex > parentItem.items.length)
                    dl.dropIndex = dataSource.items.length;
                
                //move if we are the initiator
                if(event.dragInitiator == this)
                {
                    if(itemToAdd == parentItem ||
                        itemToAdd.hasDescendant(parentItem))
                        return;
                    
                    dataSource.moveItem(itemToAdd,dl.dropIndex,parentItem);
                }
                else
                {
                    parentItem.addItemAt(itemToAdd,dl.dropIndex,false);
                }
            }
            
            //since we are scolling ourself here, just do the update
            //manage the scroll locations
            
            //this saves our current scroll position
            var oldVerticalScrollPosition:Number = dataGroup.verticalScrollPosition;
            super.dataProvider = dataSource.expandedItems;
            
            //redraw the component with the new items
            dataGroup.invalidateDisplayList();
            dataGroup.validateNow();
            
            //reset the vertical scroll position
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
        
        /**
         * Called when a node has been inserted. From the dataSource
         */ 
        protected function nodeInsertedHandler(e:TreeEvent):void
        {
            _nodeInserted = true;
            _insertedNode = e.node;
            invalidateProperties();
        }
        
        /**
         * Called when a node has been expanded. From the dataSource
         */ 
        protected function nodeExpandedHandler(e:TreeEvent):void
        {
            _nodeExpanded = true;
            _expandNode = e.node;
            invalidateProperties();
        }
        
        /**
         * Called when a node has been collasped. From the dataSource
         */
        protected function nodeCollapsedHandler(e:TreeEvent):void
        {
            _nodeCollapsed = true;
            _collapseNode = e.node;
            invalidateProperties();
        }
        
        /**
         * Called when a node has been removed from the datasource
         */ 
        protected function nodeRemovedHandler(e:TreeEvent):void
        {
            _dataProviderChanged = true;
            invalidateProperties();
        }
        
        protected function nodeMovedHandler(e:TreeEvent):void
        {
            _dataProviderChanged = true;
            invalidateProperties();
        }
        
        /**
         * Scroll the tree and dispatch a SCROLL_COMPLETE when done
         * 
         * @param verticalScrollPosition The location to scroll to
         * @param animate Whether or not that scroll is animated
         */
        public function scroll(verticalScrollPosition:Number, 
                               animate:Boolean=true):void
        {
            //if we aren't animated just set it and dispatch
            if(!animate)
            {
                dataGroup.verticalScrollPosition = verticalScrollPosition;
                dispatchEvent(new TreeEvent(TreeEvent.SCROLL_COMPLETE,null,null,null,-1,false));
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
        
        /**
         * Update the UI as we scroll
         */ 
        private function scrollEffectHandler(e:Event):void
        {
            skin.invalidateDisplayList();
        }
        
        /**
         * Dispatch the scroll complete handler when the scroll animation is complete
         */
        private function scrollAnimationEndHandler(e:EffectEvent):void
        {
            //we get this listener called twice which means we execute its handler too many
            //times
            dispatchEvent(new TreeEvent(TreeEvent.SCROLL_COMPLETE,null,null,null,-1,false));
        }
        
        /**
         * Searches for the given ITreeItem ItemRenderer
         * 
         * @param item The item to find the ItemRenderer for
         */ 
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
        
        /**
         * @inheritDoc
         */ 
        protected override function commitProperties():void
        {
            super.commitProperties();
            
            var tLayout:TreeLayout = TreeLayout(layout);
            
            //if we have just changed the data provider do the update
            if(_dataProviderChanged && 
                !_nodeCollapsed &&
                !_nodeExpanded)
            {
                updateDataProvider();
            }
            
            //if we have something that opened and closed just update
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
        
        /**
         * This function updates the List dataProvider with the expanded items
         */ 
        private function updateDataProvider():void
        {
            //don't update if nothing changed
            if($dataProvider != _dataSource.expandedItems)
            {
                dataGroup.invalidateDisplayList();
                skin.invalidateDisplayList();
                $dataProvider = _dataSource.expandedItems;
            }
            _dataProviderChanged = false;
        }
        
        /**
         * You cannot set this value, it is controlled internally by the tree
         */ 
        public override function set dataProvider(value:IList):void
        {  
            throw new Error("Can't set the data provider");
        }
        
        /**
         * The data source for the tree which controls how the tree looks and when it animated
         */ 
        [Bindable]
        public function get dataSource():ITreeDataSource
        {
            return _dataSource;
        }
        
        /**
         * Cleans up all event listeners added onto the data source before it is set to something new
         */ 
        protected function removeEventListeners():void
        {
            dataSource.removeEventListener(TreeEvent.NODE_INSERTED,nodeInsertedHandler);
            dataSource.removeEventListener(TreeEvent.NODE_EXPANDED, nodeExpandedHandler);
            dataSource.removeEventListener(TreeEvent.NODE_COLLAPSED, nodeCollapsedHandler);
            dataSource.removeEventListener(TreeEvent.NODE_REMOVED, nodeRemovedHandler);
            dataSource.removeEventListener(TreeEvent.NODE_MOVED,nodeMovedHandler);
            
        }
        
        /**
         * Adds all the event listeners needed to the data source to control the tree
         */ 
        protected function addEventListeners():void
        {
            dataSource.addEventListener(TreeEvent.NODE_INSERTED,nodeInsertedHandler);
            dataSource.addEventListener(TreeEvent.NODE_EXPANDED, nodeExpandedHandler);
            dataSource.addEventListener(TreeEvent.NODE_COLLAPSED, nodeCollapsedHandler);
            dataSource.addEventListener(TreeEvent.NODE_REMOVED, nodeRemovedHandler);
            dataSource.addEventListener(TreeEvent.NODE_MOVED,nodeMovedHandler);
        }
        
        public function set dataSource(value:ITreeDataSource):void
        {
            if(_dataSource)
                removeEventListeners();
            _dataSource = value;
            if(_dataSource)
                addEventListeners();
            
            _dataProviderChanged = true;
            invalidateProperties();
        }
        
        /**
         * Reference to the List dataProvider
         */
        private function get $dataProvider():IList 
        {
            return super.dataProvider;
        }
        
        private function set $dataProvider(value:IList):void
        {
            //this saves our current scroll position
            var oldVerticalScrollPosition:Number = dataGroup.verticalScrollPosition;
            super.dataProvider = dataSource.expandedItems;
            
            //redraw the component with the new items
            dataGroup.invalidateDisplayList();
            dataGroup.validateNow();
            
            //reset the vertical scroll position
            dataGroup.verticalScrollPosition = oldVerticalScrollPosition;
        }
    }
}