package com.bschoenberg.components.events
{
    import com.bschoenberg.components.supportClasses.ITreeItem;
    
    import flash.events.Event;
    
    public class TreeEvent extends Event
    {
        public static const SCROLL_COMPLETE:String = "scrollComplete";
        
        public static const NODE_INSERTED:String = "nodeInserted";
        public static const NODE_EXPANDED:String = "nodeExpanded";
        public static const NODE_COLLAPSED:String = "nodeCollapsed";
        public static const NODE_REMOVED:String = "nodeRemoved";
        
        private var _node:ITreeItem;
        private var _parentNode:ITreeItem;
        
        public function TreeEvent(type:String, node:ITreeItem=null, parentNode:ITreeItem=null,
                                  bubbles:Boolean=true, cancelable:Boolean=false)
        {
            super(type, bubbles, cancelable);
            
            _parentNode = parentNode;
            _node = node;
        }
        
        public override function clone():Event
        {
            return new TreeEvent(type,node, parentNode, bubbles,cancelable);
        }
        
        public function get node():ITreeItem
        {
            return _node; 
        }
        
        public function get parentNode():ITreeItem
        {
            return _parentNode; 
        }
    }
}