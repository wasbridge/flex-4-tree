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
    
    public class TreeDataEvent extends Event
    {
        public static const ADD:String = "add";
        public static const REMOVE:String = "remove";
        public static const MOVE:String = "move";
        
        private var _parent:ITreeItem;
        private var _item:ITreeItem;
        private var _index:int;
        private var _oldParent:ITreeItem;
        
        public function TreeDataEvent(type:String, item:ITreeItem, 
            parent:ITreeItem=null, oldParent:ITreeItem=null, index:int=-1, 
            bubbles:Boolean=false, cancelable:Boolean=false)
        {
            super(type, bubbles, cancelable);
            _item = item;
            _parent = parent;
            _index = index;
            _oldParent = oldParent;
        }
        
        public override function clone():Event
        {
            return new TreeDataEvent(type,item,parent, oldParent, index);
        }
        
        public function get item():ITreeItem { return _item; }
        public function get oldParent():ITreeItem { return _oldParent; }
        public function get parent():ITreeItem { return _parent; }
        public function get index():int { return _index; }
    }
}