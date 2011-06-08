package com.bschoenberg.components.supportClasses
{
    import mx.collections.IList;
    import mx.core.ILayoutElement;
    
    import spark.components.IItemRenderer;
    
    public interface ITreeLayoutElement extends ILayoutElement, IItemRenderer
    {
        function get indentLevel():int;
        
        function set indent(value:Number):void;
        
        function get parentElement():ITreeLayoutElement;
        function get childElements():IList;
            
    }
}