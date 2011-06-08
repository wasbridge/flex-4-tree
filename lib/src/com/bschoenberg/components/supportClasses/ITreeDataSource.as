package com.bschoenberg.components.supportClasses
{
    import flash.events.IEventDispatcher;
    
    import mx.collections.IList;

    public interface ITreeDataSource extends IEventDispatcher
    {
        function addItem(item:ITreeItem,parent:ITreeItem=null,dispatchTreeEvent:Boolean=true):void;
        function addItemAt(item:ITreeItem,index:int,parent:ITreeItem=null,dispatchTreeEvent:Boolean=true):void;
        function removeItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):ITreeItem; 
        function moveItem(item:ITreeItem,index:int,newParent:ITreeItem=null):void
        
        function get items():IList;
        function get allItems():IList;
        function get expandedItems():IList;
    }
}