package com.bschoenberg.components.events
{
    import com.bschoenberg.components.supportClasses.ITreeItem;
    
    import flash.events.Event;
    
    public class TreeDataEvent extends Event
    {
        public static const ADD:String = "add";
        public static const REMOVE:String = "remove";
        public static const MOVE:String = "move";
        
        private var _parent:ITreeItem;
        private var _item:ITreeItem;
        private var _index:int;
        
        public function TreeDataEvent(type:String, item:ITreeItem, parent:ITreeItem=null, index:int=-1, bubbles:Boolean=false, cancelable:Boolean=false)
        {
            super(type, bubbles, cancelable);
            _item = item;
            _parent = parent;
            _index = index;
        }
        
        public override function clone():Event
        {
            return new TreeDataEvent(type,item,parent, _index);
        }
        
        public function get item():ITreeItem { return _item; }
        public function get parent():ITreeItem { return _parent; }
        public function get index():int { return _index; }

    }
}