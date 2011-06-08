package com.bschoenberg.components
{    
    import com.bschoenberg.components.supportClasses.ITreeItem;
    import com.bschoenberg.components.supportClasses.ITreeLayoutElement;
    
    import flash.events.MouseEvent;
    
    import mx.collections.ArrayCollection;
    import mx.collections.IList;
    
    import spark.components.Image;
    import spark.components.Label;
    import spark.components.supportClasses.ItemRenderer;
    import spark.components.supportClasses.TextBase;
    
    public class BaseTreeItemRenderer extends ItemRenderer implements ITreeLayoutElement
    {   
        protected var expandButton:ExpandButton;
        
        protected var item:ITreeItem;
        protected var horizontalGap:Number;
        
        private var _indent:Number;
        private var _itemChanged:Boolean;
        
        public function BaseTreeItemRenderer()
        {
            super();
            horizontalGap = 10;
        }
        
        protected override function createChildren():void
        {
            super.createChildren();
            
            expandButton = new ExpandButton();
            expandButton.addEventListener(MouseEvent.CLICK, expandButtonClickHandler);
            addElement(expandButton);
            
            labelDisplay = new Label();
            labelDisplay.styleParent = tree;
            addElement(labelDisplay);
        }
        
        protected override function commitProperties():void
        {
            super.commitProperties();
            
            if(_itemChanged && item)
            {
                expandButton.expanded = item.expanded;
                labelDisplay.text = tree.itemToLabel(item);
                _itemChanged = false;
            }
        }
        
        protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            super.updateDisplayList(unscaledWidth,unscaledHeight);
            
            expandButton.setLayoutBoundsSize(unscaledHeight * .3,unscaledHeight *.3);
            expandButton.setLayoutBoundsPosition(horizontalGap + indent, 
                unscaledHeight/2 - expandButton.height/2);
            
            labelDisplay.setLayoutBoundsPosition(expandButton.x + expandButton.width + horizontalGap,
                unscaledHeight/2 - labelDisplay.height/2);
            labelDisplay.width = unscaledWidth - labelDisplay.x;
        }
        
        protected function expandButtonClickHandler(e:MouseEvent):void
        {            
            item.expanded = expandButton.expanded;            
        }
        
        protected function removeEventListeners(item:ITreeItem):void
        {
            
        }
        
        protected function addEventListeners(item:ITreeItem):void
        {
            
        }
        
        protected function get tree():Tree 
        { 
            return owner as Tree; 
        }
        
        public function get indent():Number { return _indent; }
        public function set indent(value:Number):void
        {
            _indent = value;
            invalidateDisplayList();
        }
        
        public function get indentLevel():int
        {
            if(item == null)
                return 0;
            
            return item.indentLevel;
        }
        
        public function get childElements():IList
        {
            var elements:ArrayCollection = new ArrayCollection();
            for each(var child:ITreeItem in item.items)
            {
                elements.addItem(tree.getTreeLayoutElement(child));
            }
            return elements;
        }
        
        public function get parentElement():ITreeLayoutElement
        {
            if(item.parent)
                return tree.getTreeLayoutElement(item.parent);
            
            return null;
        }
        
        public override function set data(value:Object):void
        {
            if(item)
                removeEventListeners(item);
            
            super.data = value;
            item = ITreeItem(value);
            
            if(item)
                addEventListeners(item);
            
            _itemChanged = true;
            invalidateProperties();
            invalidateDisplayList();
        }
    }
}