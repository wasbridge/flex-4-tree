package com.bschoenberg.components.supportClasses
{
    import flash.events.IEventDispatcher;
    
    import mx.collections.IList;

    public interface ITreeItem extends IEventDispatcher
    {
        function hasDescendant(item:ITreeItem):Boolean;
        function addItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):void;
        function addItemAt(item:ITreeItem,index:int,dispatchTreeEvent:Boolean=true):void;
        function removeItem(item:ITreeItem,dispatchTreeEvent:Boolean=true):ITreeItem;
        function getItemAt(index:int):ITreeItem;
        
        function getAllItems():IList;
        function getAllExpandedItems():IList;
        
        function setParent(item:ITreeItem):void;
        function expandRecursive():void;
        
        function get expanded():Boolean;
        function set expanded(value:Boolean):void;
        
        function get indentLevel():int;
        
        function get items():IList;
        function get parent():ITreeItem;
    }
}