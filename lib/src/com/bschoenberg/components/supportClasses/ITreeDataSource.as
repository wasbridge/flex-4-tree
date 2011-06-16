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
     * This interface describes a Tree data structure which is used as the source of data for the Tree component
     * 
     * It acts on items which implement the ITreeItem interface.
     * 
     * Any changes to this data structure will change the visual output of the Tree.  
     */ 
    public interface ITreeDataSource extends IEventDispatcher
    {
        /**
         * This method adds an Item at any point in the data structure.  The item will be
         * added as the last child for the specified parent.
         * 
         * @param item The item to add to the data source
         * @param parent The parent item of the item being added.  If null this item will be top level
         * @param dispatchTreeEvent Whether or not the datastructure should dispatch a TreeEvent causing an 
         * animation or state change
         */ 
        function addItem(item:ITreeItem,parent:ITreeItem=null,dispatchTreeEvent:Boolean=true):void;
        
        /**
         * This method adds an Item at any point in the data structure at a specified index.
         * 
         * @param item The item to add to the data source
         * @param index The index to add the item at in the list of child items of the parent
         * @param parent The parent item of the item being added.  If null this item will be top level
         * @param dispatchTreeEvent Whether or not the datastructure should dispatch a TreeEvent causing an 
         * animation or state change
         */
        function addItemAt(item:ITreeItem,index:int,parent:ITreeItem=null,dispatchTreeEvent:Boolean=true):void;
        
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
         * This method moves an item from its current location to the specified parent and index
         * 
         * @param item The item to move
         * @param index The index to move the item to
         * @param parent The new parent item, null for top level
         */ 
        function moveItem(item:ITreeItem,index:int,newParent:ITreeItem=null):void;
        
        /**
         * A list of all of the top level items
         */     
        function get items():IList;
        
        /**
         * A list of every item in the tree regardless of its expanded state
         */ 
        function get allItems():IList;
        
        /**
         * A list of every visible item in the tree taking into account expanded
         */ 
        function get expandedItems():IList;
    }
}