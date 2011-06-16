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
    import flash.events.IEventDispatcher;
    
    import mx.collections.IList;
    
    /**
     * This interface describes a data structure which is displayable in the Tree component
     * 
     * It acts on items which implement the ITreeItem interface, and is acted on by the ITreeDataSource interface.
     * 
     * Any changes to this data structure will change the visual output of the Tree.  
     */
    public interface ITreeItem extends IEventDispatcher
    {
        /**
         * This methods tests whether this item has the specified item in its children, or childrens children.
         * 
         * @param item The item to test
         * 
         * @return true if found, false if not present
         */ 
        function hasDescendant(item:ITreeItem):Boolean;
        
        /**
         * This method adds an Item at any point in the data structure.  The item will be
         * added as the last child for the specified parent.
         * 
         * @param item The item to add to the data source
         * @param dispatchTreeEvent Whether or not the datastructure should dispatch a TreeEvent causing an 
         * animation or state change
         */ 
        function addItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):void;
        
        /**
         * This method adds an Item at any point in the data structure at a specified index.
         * 
         * @param item The item to add to the data source
         * @param index The index to add the item at in the list of child items of the parent
         * @param dispatchTreeEvent Whether or not the datastructure should dispatch a TreeEvent causing an 
         * animation or state change
         */
        function addItemAt(item:ITreeItem,index:int,dispatchTreeEvent:Boolean=true):void;
        
        /**
         * This method removes an item from any point in the data structure.  
         * 
         * @param item The item to remove from the data source
         * @param dispatchTreeEvent Whether or not the datastructure should dispatch a TreeEvent causing an 
         * animation or state change
         * 
         * @return The item that was actually removed, null if no item was removed.
         */
        function removeItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):ITreeItem;
        
        /**
         * This method gets the item at the specified index
         * 
         * @param index The index of the child item to retrieve.
         * 
         * @return The item
         */ 
        function getItemAt(index:int):ITreeItem;
        
        /**
         * This method returns all child items and their children.  This method does not take into account expanded
         * 
         * @return IList of all items.
         */ 
        function getAllItems():IList;
        
        /**
         * This method returns all child items and their children.  This method does take into account expanded
         * 
         * @return IList of all items.
         */ 
        function getAllExpandedItems():IList;
        
        /**
         * This method sets the parent item for this item.  It should only be called by that parent item.
         * 
         * @param The new parent
         */
        function setParent(item:ITreeItem):void;
        
        /**
         * This method expands all child items and this item
         */ 
        function expandRecursive():void;
        
        /**
         * Whether or not this item is showing or hiding its children
         */ 
        function get expanded():Boolean;
        function set expanded(value:Boolean):void;
        
        /**
         * How deep this item is in the tree
         */ 
        function get indentLevel():int;
        
        /**
         * The direct descendents of this item
         */
        function get items():IList;
        
        /**
         * The owner of this item
         */ 
        function get parent():ITreeItem;
    }
}