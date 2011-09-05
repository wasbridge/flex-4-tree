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
    import com.bschoenberg.components.supportClasses.ITreeItem;
    import com.bschoenberg.components.supportClasses.ITreeLayoutElement;
    
    import flash.events.IEventDispatcher;
    import flash.events.MouseEvent;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    
    import mx.collections.ArrayCollection;
    import mx.collections.IList;
    import mx.core.InteractionMode;
    import mx.core.UIComponent;
    import mx.core.mx_internal;
    import mx.events.TouchInteractionEvent;
    import mx.events.TouchInteractionReason;
    
    import spark.components.Label;
    import spark.components.supportClasses.ItemRenderer;
    
    public class TreeItemRenderer extends ItemRenderer implements ITreeLayoutElement
    {   
        [Bindable]
        public var expandButton:ExpandButton;
        
        protected var item:ITreeItem;
        protected var horizontalGap:Number;
        
        private var _indent:Number;
        private var _itemChanged:Boolean;
        
        public function TreeItemRenderer()
        {
            super();
            horizontalGap = 10;
        }
        
        protected override function createChildren():void
        {
            super.createChildren();
            
            var touchMode:Boolean = getStyle("interactionMode") == InteractionMode.TOUCH;
            
            expandButton = new ExpandButton();
            expandButton.addEventListener(MouseEvent.CLICK, expandButtonClickHandler);
            addElement(expandButton);
            
            labelDisplay = new Label();
			labelDisplay.setStyle("color",this.getStyle('color'));
            labelDisplay.styleParent = tree;
            addElement(labelDisplay);
            
            if(touchMode)
            {
                attachDragListeners(expandButton);
                attachFixedListeners(labelDisplay);
            }
        }
        
        protected override function commitProperties():void
        {
            super.commitProperties();
            
            if(_itemChanged && item)
            {
                expandButton.expanded = item.expanded;
                labelDisplay.text = tree.itemToLabel(item);
                _itemChanged = false;
            }
        }
        
        protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            super.updateDisplayList(unscaledWidth,unscaledHeight);
            
            expandButton.setLayoutBoundsSize(unscaledHeight * .3,unscaledHeight *.3);
            expandButton.setLayoutBoundsPosition(horizontalGap + indent, 
                unscaledHeight/2 - expandButton.height/2);
            
            labelDisplay.setLayoutBoundsPosition(expandButton.x + expandButton.width + horizontalGap,
                unscaledHeight/2 - labelDisplay.height/2);
            labelDisplay.width = unscaledWidth - labelDisplay.x;
        }
        
        protected function expandButtonClickHandler(e:MouseEvent):void
        {            
            item.expanded = expandButton.expanded; 
            tree.mx_internal::setSelectedItem(item,true);
        }
        
        protected function removeEventListeners():void
        {
            
        }
        
        protected function addEventListeners():void
        {
            
        }
        
        protected function dragMouseDown(e:MouseEvent):void
        {
            tree.dragEnabled = true;
        }
        
        protected function dragMouseUp(e:MouseEvent):void
        {
            tree.dragEnabled = false;
        }
        
        protected function fixedMouseDown(e:MouseEvent):void
        {
            //this stops drags inside of the input from dragging
            //this item renderer;
            e.preventDefault();
            setSelected(true);
        }
        
        protected function setSelected(value:Boolean):void
        {
            tree.mx_internal::setSelectedItem(item,value);
        }
        
        protected function touchInteractionStarting(e:TouchInteractionEvent):void
        {
            if(e.reason == TouchInteractionReason.SCROLL)
                e.preventDefault();
        }
        
        protected function attachDragListeners(target:IEventDispatcher):void
        {
            target.addEventListener(MouseEvent.MOUSE_DOWN, dragMouseDown);
            target.addEventListener(MouseEvent.MOUSE_UP, dragMouseUp);
            target.addEventListener(TouchInteractionEvent.TOUCH_INTERACTION_STARTING,touchInteractionStarting);
        }
        
        protected function attachFixedListeners(target:IEventDispatcher):void
        {
            target.addEventListener(MouseEvent.MOUSE_DOWN, fixedMouseDown);
        }
        
        protected function get tree():Tree 
        { 
            return owner as Tree; 
        }
        
        [Bindable]
        public function get indent():Number { return _indent; }
        public function set indent(value:Number):void
        {
            _indent = value;
            invalidateDisplayList();
        }
        
        public function get indentLevel():int
        {
            if(item == null)
                return 0;
            
            return item.indentLevel;
        }
        
        public function get visibleChildren():IList
        {
            var elements:ArrayCollection = new ArrayCollection();
            for each(var child:ITreeItem in item.items)
            {
                var ele:ITreeLayoutElement = tree.getTreeLayoutElement(child);
                if(!ele)
                    continue;
                
                elements.addItem(ele);
                
                if(!child.expanded)
                    continue;
                
                elements.addAll(ele.visibleChildren);
            }
            return elements;
        }
        
        public function get childElements():IList
        {
            var elements:ArrayCollection = new ArrayCollection();
            for each(var child:ITreeItem in item.items)
            {
                elements.addItem(tree.getTreeLayoutElement(child));
            }
            return elements;
        }
        
        public function get parentElement():ITreeLayoutElement
        {
            if(item.parent)
                return tree.getTreeLayoutElement(item.parent);
            
            return null;
        }
        
        public override function set data(value:Object):void
        {
            if(item)
                removeEventListeners();
            
            super.data = value;
            item = ITreeItem(value);
            
            if(item)
                addEventListeners();
            
            _itemChanged = true;
            invalidateProperties();
            invalidateDisplayList();
        }
    }
}