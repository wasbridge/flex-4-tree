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

package com.bschoenberg.components.supportClasses
{
    import com.bschoenberg.components.events.TreeDataEvent;
    import com.bschoenberg.components.events.TreeEvent;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import mx.collections.ArrayCollection;
    import mx.collections.IList;
    import mx.events.FlexEvent;
    
    [Event(name="nodeExpanded", type="com.bschoenberg.components.events.TreeEvent")]
    [Event(name="nodeInserted", type="com.bschoenberg.components.events.TreeEvent")]
    [Event(name="nodeCollapsed", type="com.bschoenberg.components.events.TreeEvent")]
    [Event(name="nodeRemoved", type="com.bschoenberg.components.events.TreeEvent")]

    public dynamic class TreeItem extends EventDispatcher implements ITreeItem
    {
        private var _expanded:Boolean;
        private var _parent:ITreeItem;
        private var _children:IList;

        public function TreeItem()
        {
            _children = new ArrayCollection();
        }
        
        public function getItemAt(index:int):ITreeItem
        {
            return _children.getItemAt(index) as ITreeItem;
        }
        
        public function hasDescendant(item:ITreeItem):Boolean
        {
            for each(var child:ITreeItem in _children)
            {
                if(child == item)
                    return true;
                
                if(child.hasDescendant(item))
                    return true;
            }
            
            return false;
        }
        
        public function addItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):void
        {
            addEventListeners(item);
            
            item.setParent(this);
            _children.addItem(item);
            if(dispatchTreeEvent)
                dispatchEvent(new TreeEvent(TreeEvent.NODE_INSERTED,item));
            
            dispatchEvent(new TreeDataEvent(TreeDataEvent.ADD,item,this));
        }
        
        
        public function addItemAt(item:ITreeItem, index:int,dispatchTreeEvent:Boolean=true):void
        {
            if(index < 0)
                throw new Error("Tried to add child item at index: " + index);
            
            if(index > _children.length)
                throw new Error("Tried to add child item past children length: " + index + " children length: " + _children.length );
            
            addEventListeners(item);
            
            item.setParent(this);
            _children.addItemAt(item,index);
            if(dispatchTreeEvent)
                dispatchEvent(new TreeEvent(TreeEvent.NODE_INSERTED,item));
            
            dispatchEvent(new TreeDataEvent(TreeDataEvent.ADD,item,this));
        }
        
        public function removeItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):ITreeItem
        {
            var retVal:ITreeItem;
            var index:int = _children.getItemIndex(item);
            if(index == -1)
            {
                for each(var child:ITreeItem in _children)
                {
                    if(child.hasDescendant(item))
                    {
                        retVal = child.removeItem(item,dispatchTreeEvent)
                        return retVal;
                    } 
                }
            }
            else
            {
                retVal = ITreeItem(_children.removeItemAt(index));
                if(retVal)
                {
                    var parent:ITreeItem = retVal.parent;
                    retVal.setParent(null);
                    removeEventListeners(retVal);
                    dispatchEvent(new TreeDataEvent(TreeDataEvent.REMOVE,retVal,parent));
                    
                    if(dispatchTreeEvent)
                        dispatchEvent(new TreeEvent(TreeEvent.NODE_REMOVED,retVal,parent));
                }
            }
            return retVal;
        }
        
        public function setParent(item:ITreeItem):void
        {
            if(item == this)
                throw new Error("We cannot be our own parent");
            
            if(_parent)
                _parent.removeItem(item,false);    
            
            _parent = item;
        }
        
        public function getAllExpandedItems():IList
        {
            var retVal:ArrayCollection = new ArrayCollection();
            for each(var item:ITreeItem in items)
            {
                retVal.addItem(item);
                if(!item.expanded)
                    continue;
                retVal.addAll(item.getAllExpandedItems());
            }
            
            return retVal;
        }
        
        public function getAllItems():IList
        {
            var retVal:ArrayCollection = new ArrayCollection();
            for each(var item:ITreeItem in items)
            {
                retVal.addItem(item);
                retVal.addAll(item.getAllItems());
            }
            
            return retVal;
        }
        
        public function expandRecursive():void
        {
            expanded = true;
            for each(var item:ITreeItem in items)
            {
                item.expandRecursive();
            }
        }
        
        protected function removeEventListeners(item:ITreeItem):void
        {
            item.removeEventListener(TreeDataEvent.ADD, handler);
            item.removeEventListener(TreeDataEvent.REMOVE, handler);
            
            item.removeEventListener(TreeEvent.NODE_INSERTED, handler);
            item.removeEventListener(TreeEvent.NODE_EXPANDED, handler);
            item.removeEventListener(TreeEvent.NODE_COLLAPSED, handler);
            item.removeEventListener(TreeEvent.NODE_REMOVED, handler);
        }
        
        protected function addEventListeners(item:ITreeItem):void
        {
            item.addEventListener(TreeDataEvent.ADD, handler);
            item.addEventListener(TreeDataEvent.REMOVE, handler);
            
            item.addEventListener(TreeEvent.NODE_INSERTED, handler);
            item.addEventListener(TreeEvent.NODE_EXPANDED, handler);
            item.addEventListener(TreeEvent.NODE_COLLAPSED, handler);
            item.addEventListener(TreeEvent.NODE_REMOVED, handler);
        }
        
        protected function handler(e:Event):void
        {
            dispatchEvent(e);
        }
        
        public function get indentLevel():int
        {
            if(parent)
                return parent.indentLevel + 1;
            
            return 0;
        }
        
        [Bindable]
        public function get expanded():Boolean { return _expanded; }
        public function set expanded(value:Boolean):void 
        { 
            if(value == _expanded)
                return;
            
            _expanded = value;
            
            if(_expanded)
                dispatchEvent(new TreeEvent(TreeEvent.NODE_EXPANDED,this,parent));
            else
                dispatchEvent(new TreeEvent(TreeEvent.NODE_COLLAPSED,this,parent));
        }
        
        public function get parent():ITreeItem { return _parent; }
        
        public function get items():IList { return _children; }
        public function set items(value:IList):void
        {
            var item:ITreeItem;
            for each(item in _children)
            {
                removeItem(item);
            }
            
            for each(item in value)
            {
                addItem(item);
            }
        }
    }
}