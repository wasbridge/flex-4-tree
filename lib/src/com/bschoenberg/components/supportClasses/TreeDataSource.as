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
    
    [Event(name="add", type="com.bschoenberg.components.events.TreeDataEvent")]
    [Event(name="remove", type="com.bschoenberg.components.events.TreeDataEvent")]
    [Event(name="move", type="com.bschoenberg.components.events.TreeDataEvent")]
    
    
    [Event(name="nodeExpanded", type="com.bschoenberg.components.events.TreeEvent")]
    [Event(name="nodeInserted", type="com.bschoenberg.components.events.TreeEvent")]
    [Event(name="nodeCollapsed", type="com.bschoenberg.components.events.TreeEvent")]
    [Event(name="nodeRemoved", type="com.bschoenberg.components.events.TreeEvent")]

    public class TreeDataSource extends EventDispatcher implements ITreeDataSource
    {
        private var _items:IList;
        
        private var _allItems:ArrayCollection;
        private var _expandedItems:ArrayCollection;
        
        public function TreeDataSource()
        {
            _items = new ArrayCollection();
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
        
        public function addItem(item:ITreeItem,parent:ITreeItem=null,dispatchTreeEvent:Boolean=true):void
        {
            if(item == null)
                throw new Error("Tried to add null item");
            
            clearCaches();
            
            if(!parent)
            {
                addEventListeners(item);
                item.setParent(null);
                _items.addItem(item);
                
                if(dispatchTreeEvent)
                    dispatchEvent(new TreeEvent(TreeEvent.NODE_INSERTED,item));
                
                dispatchEvent(new TreeDataEvent(TreeDataEvent.ADD,item));
            }
            else
            {
                parent.addItem(item,dispatchTreeEvent);
            }
        }
        
        public function addItemAt(item:ITreeItem, index:int, parent:ITreeItem=null,dispatchTreeEvent:Boolean=true):void
        {
            if(item == null)
                throw new Error("Tried to add null item");
            
            clearCaches();
            
            if(!parent)
            {
                addEventListeners(item);
                item.setParent(null);
                _items.addItemAt(item,index);
                
                if(dispatchTreeEvent)
                    dispatchEvent(new TreeEvent(TreeEvent.NODE_INSERTED,item));
                
                dispatchEvent(new TreeDataEvent(TreeDataEvent.ADD,item));
                
            }
            else
            {
                parent.addItemAt(item,index,dispatchTreeEvent);
            }
        }
        
        public function removeItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):ITreeItem
        {
            clearCaches();
            
            var retVal:ITreeItem;
            var index:int = _items.getItemIndex(item);
            if(index == -1)
            {
                for each(var child:ITreeItem in _items)
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
                retVal = ITreeItem(_items.removeItemAt(index));
                var parent:ITreeItem = retVal.parent;
                retVal.setParent(null);
                removeEventListeners(retVal);
                dispatchEvent(new TreeDataEvent(TreeDataEvent.REMOVE,retVal,parent));
                
                if(dispatchTreeEvent)
                    dispatchEvent(new TreeEvent(TreeEvent.NODE_REMOVED,retVal,parent));
                return retVal;
            }
            
            return null;
        }
        
        protected function silentRemove(item:ITreeItem):void
        {
            var index:int = _items.getItemIndex(item);
            if(index == -1)
            {
                for each(var child:ITreeItem in _items)
                {
                    if(child.hasDescendant(item))
                    {
                        removeEventListeners(child)
                        child.removeItem(item,false)
                        addEventListeners(child);
                    } 
                }
            }
            else
            {
                item = ITreeItem(_items.removeItemAt(index));
                removeEventListeners(item);
                item.setParent(null);
            }
        }
        
        protected function silentAdd(item:ITreeItem,index:int,parent:ITreeItem):void
        {
            if(!parent)
            {
                addEventListeners(item);
                item.setParent(null);
                _items.addItemAt(item,index);
            }
            else
            {
                removeEventListeners(parent);
                parent.addItemAt(item,index,false);
                addEventListeners(parent);
            }
        } 
        
        public function moveItem(item:ITreeItem,index:int,parentItem:ITreeItem=null):void
        {
            if(item == null)
                return;
            
            if(index < 0)
                return;
            
            clearCaches();
            
            var oldParent:ITreeItem = item.parent;
            
            silentRemove(item);
            silentAdd(item,index,parentItem);
            
            dispatchEvent(new TreeDataEvent(TreeDataEvent.MOVE,item,parentItem,oldParent,index));
        }
        
        private function handler(e:Event):void
        {
            clearCaches();
            dispatchEvent(e);
        }
        
        private function clearCaches():void
        {
            _allItems = null;
            _expandedItems = null;
        }
        
        private function generateCaches():void
        {
            _allItems = new ArrayCollection();
            _expandedItems = new ArrayCollection();
            
            for each(var item:ITreeItem in items)
            {
                _allItems.addItem(item);
                _allItems.addAll(item.getAllItems());
            }
            
            for each(var item2:ITreeItem in items)
            {
                _expandedItems.addItem(item2);
                if(!item2.expanded)
                    continue;
                _expandedItems.addAll(item2.getAllExpandedItems());
            }
        }
        
        public function get items():IList 
        { 
            return _items; 
        }
        
        public function set items(value:IList):void
        {
            var item:ITreeItem;
            for each(item in _items)
            {
                removeItem(item);
            }
            
            for each(item in value)
            {
                addItem(item);
            }
        }
        
        public function get allItems():IList
        {
            if(_allItems == null ||
                _allItems.length == 0)
                generateCaches();
            return _allItems;
        }
        
        public function get expandedItems():IList
        {
            if(_expandedItems == null ||
                _expandedItems.length == 0)
                generateCaches();
            return _expandedItems;
        }
    }
}