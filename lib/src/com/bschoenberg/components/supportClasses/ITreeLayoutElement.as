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
    import mx.collections.IList;
    import mx.core.ILayoutElement;
    
    import spark.components.IItemRenderer;
    
    /**
     * This interface is an extension of IItemRenderer used by the TreeLayout to layout elements in a tree like fashion
     */ 
    public interface ITreeLayoutElement extends ILayoutElement, IItemRenderer
    {
        /**
         * How deep the item is in the hierarchy
         */ 
        function get indentLevel():int;
        
        /**
         * How many pixels in this item should be
         */ 
        function set indent(value:Number):void;
        
        /**
         * The owning element of this element
         */ 
        function get parentElement():ITreeLayoutElement;
        
        /**
         * The direct descendents of this elements (as ITreeLayoutElements)
         */ 
        function get childElements():IList;
        
        /**
        * All of the expanded children of this element 
        */ 
        function get visibleChildren():IList;
    }
}