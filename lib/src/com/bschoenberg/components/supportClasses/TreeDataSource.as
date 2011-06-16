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
    
    /**
     * Dispatched when a child item is added
     *
     * @eventType com.bschoenberg.components.events.TreeDataEvent.ADD
     */ 
    [Event(name="add", type="com.bschoenberg.components.events.TreeDataEvent")]
    
    /**
     * Dispatched when a child item is removed
     *
     * @eventType com.bschoenberg.components.events.TreeDataEvent.REMOVE
     */ 
    [Event(name="remove", type="com.bschoenberg.components.events.TreeDataEvent")]
    
    /**
     * Dispatched when a child item is moved
     *
     * @eventType com.bschoenberg.components.events.TreeDataEvent.MOVE
     */ 
    [Event(name="move", type="com.bschoenberg.components.events.TreeDataEvent")]
    
    /**
     * Dispatched when the expanded property is set to true. This will animate an expansion
     *
     * @eventType com.bschoenberg.components.events.TreeEvent.NODE_EXPANDED
     */
    [Event(name="nodeExpanded", type="com.bschoenberg.components.events.TreeEvent")]
    
    /**
     * Dispatched when a child item is added. This will animate an insertion
     *
     * @eventType com.bschoenberg.components.events.TreeEvent.NODE_INSERTED
     */
    [Event(name="nodeInserted", type="com.bschoenberg.components.events.TreeEvent")]
    
    /**
     * Dispatched when the expanded property is set to false. This will animate a closure
     *
     * @eventType com.bschoenberg.components.events.TreeEvent.NODE_COLLAPSED
     */
    [Event(name="nodeCollapsed", type="com.bschoenberg.components.events.TreeEvent")]
    
    /**
     * Dispatched when an item is removed. This will animate a removal
     *
     * @eventType com.bschoenberg.components.events.TreeEvent.NODE_REMOVED
     */
    [Event(name="nodeRemoved", type="com.bschoenberg.components.events.TreeEvent")]
    
    /**
     * This is the default ITreeDataSource implementor.  It implements the tree data structure for the Tree.
     * 
     */ 
    public class TreeDataSource extends EventDispatcher implements ITreeDataSource
    {
        private var _items:IList;
        
        private var _allItems:ArrayCollection;
        private var _expandedItems:ArrayCollection;
        
        public function TreeDataSource()
        {
            _items = new ArrayCollection();
        }
        
        /**
         * This method is used to remove listeners added to an item.
         * This method is called when items are being removed from the tree
         * or when events do not need to be listened to.
         * 
         * @param item The item to remove the event listeners from
         */ 
        protected function removeEventListeners(item:ITreeItem):void
        {
            item.removeEventListener(TreeDataEvent.ADD, handler);
            item.removeEventListener(TreeDataEvent.REMOVE, handler);
            
            item.removeEventListener(TreeEvent.NODE_INSERTED, handler);
            item.removeEventListener(TreeEvent.NODE_EXPANDED, handler);
            item.removeEventListener(TreeEvent.NODE_COLLAPSED, handler);
            item.removeEventListener(TreeEvent.NODE_REMOVED, handler);
        }
        
        /**
         * This method is used to add listeners to an item.
         * This method is called when items are being added to the tree
         *  
         * @param item The item to add the event listeners to
         */ 
        protected function addEventListeners(item:ITreeItem):void
        {
            item.addEventListener(TreeDataEvent.ADD, handler);
            item.addEventListener(TreeDataEvent.REMOVE, handler);
            
            item.addEventListener(TreeEvent.NODE_INSERTED, handler);
            item.addEventListener(TreeEvent.NODE_EXPANDED, handler);
            item.addEventListener(TreeEvent.NODE_COLLAPSED, handler);
            item.addEventListener(TreeEvent.NODE_REMOVED, handler);
        }
        
        /**
         * @inheritDoc
         */ 
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
        
        /**
         * @inheritDoc
         */ 
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
        
        /**
         * @inheritDoc
         */ 
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
        
        /**
         * This method silently removes an item from the data structure.  It makes sure that no events are dispatched.
         * This method is used by the move method
         * 
         * @param item The item to remove
         */ 
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
        
        /**
         * This method silently adds an item to the data structure.  It makes sure that no events are dispatched.
         * This method is used by the move method
         * 
         * @param item The item to add
         * @param index The index to add the item at
         * @param parent The item to add the item to
         */ 
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
        
        /**
         * @inheritDoc
         */ 
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
        
        /**
         * The default event handler.  It redispatches all child events and clears any caches
         */ 
        private function handler(e:Event):void
        {
            clearCaches();
            dispatchEvent(e);
        }
        
        /**
         * Clears cached data
         */ 
        private function clearCaches():void
        {
            _allItems = null;
            _expandedItems = null;
        }
        
        /**
         * Generates cached versions of allItems and expandedItems
         */ 
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
        
        /**
         * @inheritDoc
         */ 
        public function get items():IList 
        { 
            return _items; 
        }
        
        /**
         * @private
         */ 
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
        
        /**
         * @inheritDoc
         */ 
        public function get allItems():IList
        {
            if(_allItems == null ||
                _allItems.length == 0)
                generateCaches();
            return _allItems;
        }
        
        /**
         * @inheritDoc
         */ 
        public function get expandedItems():IList
        {
            if(_expandedItems == null ||
                _expandedItems.length == 0)
                generateCaches();
            return _expandedItems;
        }
    }
}