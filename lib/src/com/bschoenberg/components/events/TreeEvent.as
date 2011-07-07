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
        public static const NODE_MOVED:String = "nodeMoved";
        
        private var _node:ITreeItem;
        private var _parentNode:ITreeItem;
        
        private var _index:int;
        private var _oldParentNode:ITreeItem;
        
        public function TreeEvent(type:String, node:ITreeItem=null, parentNode:ITreeItem=null,
                                  oldParentNode:ITreeItem=null,index:int=-1,
                                  bubbles:Boolean=true, cancelable:Boolean=false)
        {
            super(type, bubbles, cancelable);
            
            _parentNode = parentNode;
            _node = node;
            
            _oldParentNode = oldParentNode;
            _index = index;
        }
        
        public override function clone():Event
        {
            return new TreeEvent(type,node, parentNode, oldParentNode, index, bubbles,cancelable);
        }
        
        public function get node():ITreeItem
        {
            return _node; 
        }
        
        public function get parentNode():ITreeItem
        {
            return _parentNode; 
        }
        
        public function get oldParentNode():ITreeItem
        {
            return _oldParentNode; 
        }
        
        public function get index():int 
        {
            return _index;
        }
    }
}