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

package com.bschoenberg.components.layouts
{
    import com.bschoenberg.components.layouts.supportClasses.TreeDropLocation;
    import com.bschoenberg.components.supportClasses.ITreeLayoutElement;
    
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.Timer;
    
    import mx.collections.ArrayCollection;
    import mx.collections.IList;
    import mx.core.ILayoutElement;
    import mx.core.InteractionMode;
    import mx.core.UIComponent;
    import mx.core.mx_internal;
    import mx.events.DragEvent;
    import mx.events.EffectEvent;
    
    import spark.components.supportClasses.GroupBase;
    import spark.effects.Move;
    import spark.layouts.supportClasses.DropLocation;
    import spark.layouts.supportClasses.LayoutBase;
    
    public class TreeLayout extends LayoutBase
    {
        private static const NONE:int = -1;
        private static const INSERTING:int = 1;
        private static const EXPANDING:int = 2;
        private static const COLLAPSING:int = 3;
        private static const COLLAPSING_DOWN:int = 4;
        
        private var _dragScrollTimer:Timer;
        private var _dragScrollDelta:Point;
        private var _dragScrollEvent:DragEvent;
        
        //need to track this so i can move the mask as we scroll
        private var _previousVerticalScrollPosition:Number = -1;
        private var _currentVerticalScrollPosition:Number = -1;
        
        private var _animate:Boolean = true;
        
        private var _indent:int = 40;
        
        private var _slideEffect:Move;
        
        private var _insertedNode:Object;
        private var _expandingNodes:IList;
        private var _collapsingNodes:IList;
        
        private var _masks:Dictionary;
        
        private var _addtDistVScrollAfterLayout:Number = 0;        
        private var _layoutCompleteFunction:Function;
        
        private var _paddingTop:Number = 0;
        private var _paddingBottom:Number = 0;
        private var _paddingLeft:Number = 0;
        private var _paddingRight:Number = 0;
        private var _rowHeight:Number = 80;

        private var _dropLocation:DropLocation;

        public function TreeLayout()
        {
            super();
            _masks = new Dictionary();
        }
        
        private function maskElement(element:DisplayObject, bounds:Rectangle):void
        {
            var offset:Point = target.localToGlobal(new Point(0,0));
            var mask:Sprite = new Sprite();
            mask.cacheAsBitmap = true;
            mask.x = offset.x + bounds.x;
            mask.y = offset.y + bounds.y;
            mask.graphics.beginFill(0xFF0000);
            mask.graphics.drawRect(0,0,
                bounds.width,bounds.height);
            target.stage.addChild(mask);
            element.mask = mask;
            _masks[element] = new MaskData(mask, bounds);
        }
        
        protected function regenerateEffects(useUpdateHandler:Boolean):void
        {         
            _currentVerticalScrollPosition = -1;
            _previousVerticalScrollPosition = -1;
            //this moves all the added or removed items at once
            _slideEffect = new Move();
            //_slideEffect.duration = 4000;
            _slideEffect.disableLayout = true;
            _slideEffect.applyChangesPostLayout = false;
            _slideEffect.addEventListener(EffectEvent.EFFECT_END,effectCompleteHandler);            
            if(!useUpdateHandler)
                return;
            _slideEffect.addEventListener(EffectEvent.EFFECT_UPDATE,effectUpdateHandler);
        }
        
        private function effectUpdateHandler(e:Event):void
        {
            var ratio:Number = _slideEffect.playheadTime/_slideEffect.duration;
            ratio = _slideEffect.easer.ease(ratio);
            
            if(isNaN(ratio))
                return;
            
            var mask:Sprite;
            var maskBounds:Rectangle;
            
            var offset:Point = target.localToGlobal(new Point(0,0));
            for each(var maskObj:MaskData in _masks)
            {
                maskBounds = maskObj.bounds;
                mask = maskObj.mask;
                
                mask.y = offset.y + maskBounds.y + (ratio * maskBounds.height);
                
                mask.graphics.clear();
                mask.graphics.beginFill(0xFF0000);
                mask.graphics.drawRect(0,0, maskBounds.width, (1-ratio) * maskBounds.height);
                mask.graphics.endFill();
            }
        }
        
        private function effectCompleteHandler(e:EffectEvent):void
        {
            for (var element:Object in _masks)
            {
                element.mask = null;
                target.stage.removeChild(_masks[element].mask);
            }
            _masks = new Dictionary();
            layoutCompleted();            
        }
        
        /**
         *  @inherit
         */
        public override function showDropIndicator(dropLocation:DropLocation):void
        {
            if (!dropIndicator || !dropLocation)
                return;
            
            // Check for drag scrolling
            var dragScrollElapsedTime:int = 0;
            if (_dragScrollTimer)
                dragScrollElapsedTime = _dragScrollTimer.currentCount * _dragScrollTimer.delay;
            
            if(target.getStyle("interactionMode") == InteractionMode.TOUCH)
            {
                mx_internal::dragScrollRegionSizeHorizontal = 50;
                mx_internal::dragScrollRegionSizeVertical = rowHeight * 3;
                mx_internal::dragScrollInitialDelay = 5;
                mx_internal::dragScrollSpeed = 20;
            }
            else
            {
                mx_internal::dragScrollRegionSizeVertical = rowHeight * 2;
                mx_internal::dragScrollSpeed = 20;
            }
            
            _dragScrollDelta = calculateDragScrollDelta(dropLocation,
                dragScrollElapsedTime);
            
            if (_dragScrollDelta)
            {
                // Update the drag-scroll event
                _dragScrollEvent = dropLocation.dragEvent;
                if (!dragScrollingInProgress())
                {
                    // Creates a timer, immediately updates the scroll position
                    // based on _dragScrollDelta and redispatches the event.
                    startDragScrolling();
                    return;
                }
                else
                {
                    if (mx_internal::dragScrollHidesIndicator)
                        return;
                }
            }
            else
                stopDragScrolling();
            
            // Show the drop indicator
            var bounds:Rectangle = calculateDropIndicatorBounds(dropLocation);
            if (!bounds)
                return;
            
            if (dropIndicator is ILayoutElement)
            {
                var element:ILayoutElement = ILayoutElement(dropIndicator);
                element.setLayoutBoundsSize(bounds.width, bounds.height);
                element.setLayoutBoundsPosition(bounds.x, bounds.y);
            }
            else
            {
                dropIndicator.width = bounds.width;
                dropIndicator.height = bounds.height;
                dropIndicator.x = bounds.x;
                dropIndicator.y = bounds.y;
            }
            
            dropIndicator.visible = true;
            
            _dropLocation = dropLocation;
            target.invalidateDisplayList();
        }
        
        /**
         *  @inherit
         */
        public override function hideDropIndicator():void
        {
            stopDragScrolling();
            if (dropIndicator)
                dropIndicator.visible = false;
            
            _dropLocation = null;
            target.invalidateDisplayList();
            
            invalidateDisplayList();
        }
        
        public override function calculateDropLocation(dragEvent:DragEvent):DropLocation
        {
            // Find the drop index
            var dropPoint:Point = target.globalToLocal(new Point(dragEvent.stageX, dragEvent.stageY));
            var dropIndex:int = calculateDropIndex(dropPoint.x, dropPoint.y);
            if (dropIndex == -1)
                return null;
            
            // Create and fill the drop location info
            var dropLocation:DropLocation = new DropLocation();
            dropLocation.dragEvent = dragEvent;
            dropLocation.dropPoint = dropPoint;
            dropLocation.dropIndex = dropIndex;
            return dropLocation;
        }
        
        /**
         * @inherit
         */
        protected override function calculateDropIndex(x:Number, y:Number):int
        {
            // Iterate over the visible elements            
            // If there are no items, insert at index 0
            if (target.numElements == 0 || y <= 0)
                return 0;
            
            var index:int = Math.floor(y/rowHeight);
            var leftOvers:Number = y % rowHeight;
            
            if(index >= target.numElements)
                return target.numElements;
            
            if(leftOvers <= rowHeight * .25)
            {
                return Math.min(index, target.numElements);
            }
            else if(leftOvers >= rowHeight * .75)
            {
                var element:ITreeLayoutElement = ITreeLayoutElement(target.getElementAt(index));
                var expandedChildren:IList = element.visibleChildren;
                var lastOpenElement:ITreeLayoutElement = element;
                
                if(expandedChildren.length == 0)
                    return Math.min(index + 1, target.numElements);
                
                lastOpenElement = ITreeLayoutElement(expandedChildren.getItemAt(expandedChildren.length - 1));
                return Math.min(target.getElementIndex(lastOpenElement) + 1, target.numElements);
            }
            else 
            {
                return Math.min(index + 1, target.numElements);
            }
        }
        
        /**
         * @inherit
         */
        protected override function calculateDropIndicatorBounds(dropLocation:DropLocation):Rectangle
        {
            if(dropLocation == null)
                return null;
            
            var bounds:Rectangle;
            var index:int = dropLocation.dropIndex;
            if(index == target.numElements)
            {
                bounds = this.getElementBounds(index - 1);
                bounds.y -= 2;
                bounds.height = 2;
            }
            else
            {
                bounds = this.getElementBounds(index);
                bounds.y -= 2;
                bounds.height = 2;
            }
            return bounds;
        }
        /**
         *  @private 
         *  True if the drag-scroll timer is running. 
         */
        private function dragScrollingInProgress():Boolean
        {
            return _dragScrollTimer != null;
        }
        
        /**
         *  @private 
         *  Starts the drag-scroll timer.
         */
        private function startDragScrolling():void
        {
            if (_dragScrollTimer)
                return;
            
            // Setup the timer to handle the subsequet scrolling
            _dragScrollTimer = new Timer(mx_internal::dragScrollInterval);
            _dragScrollTimer.addEventListener(TimerEvent.TIMER, dragScroll);
            _dragScrollTimer.start();
            
            // Scroll once on start. Scroll after the _dragScrollTimer is
            // initialized to prevent stack overflow as a new event will be
            // dispatched to the list and it may try to start drag scrolling
            // again.
            dragScroll(null);
        }
        
        /**
         *  @private
         *  Updates the scroll position and dispatches a DragEvent.
         */
        private function dragScroll(event:TimerEvent):void
        {
            // Scroll the target
            horizontalScrollPosition += _dragScrollDelta.x;
            verticalScrollPosition += _dragScrollDelta.y;
            
            // Validate target before dispatching the event
            target.validateNow();
            
            // Re-dispatch the event so that the drag initiator handles it as if
            // the DragProxy is dispatching in response to user input.
            // Always switch over to DRAG_OVER, don't re-dispatch DRAG_ENTER
            var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_OVER,
                _dragScrollEvent.bubbles,
                _dragScrollEvent.cancelable, 
                _dragScrollEvent.dragInitiator, 
                _dragScrollEvent.dragSource, 
                _dragScrollEvent.action, 
                _dragScrollEvent.ctrlKey, 
                _dragScrollEvent.altKey, 
                _dragScrollEvent.shiftKey);
            
            dragEvent.draggedItem = _dragScrollEvent.draggedItem;
            dragEvent.localX = _dragScrollEvent.localX;
            dragEvent.localY = _dragScrollEvent.localY;
            dragEvent.relatedObject = _dragScrollEvent.relatedObject;
            _dragScrollEvent.target.dispatchEvent(dragEvent);
        }
        
        /**
         *  @private
         *  Stops the drag-scroll timer. 
         */
        private function stopDragScrolling():void
        {
            if (_dragScrollTimer)
            {
                _dragScrollTimer.stop();
                _dragScrollTimer.removeEventListener(TimerEvent.TIMER, dragScroll);
                _dragScrollTimer = null;
            }
            
            _dragScrollEvent = null;
            _dragScrollDelta = null;
        }
        
        public function calculateTreeDropLocation(dragEvent:DragEvent):TreeDropLocation
        {
            var p:Point = new Point(dragEvent.stageX,dragEvent.stageY);
            p = target.globalToLocal(p);
            var retVal:TreeDropLocation = calculateTreeDropIndicies(p.x,p.y);
            retVal.dragEvent = dragEvent;
            retVal.dropPoint = p;
            return retVal;
        }
        
        protected function calculateTreeDropIndicies(x:Number, y:Number):TreeDropLocation
        {
            var loc:TreeDropLocation = new TreeDropLocation();
            
            // Iterate over the visible elements
            var count:int = target.numElements;
            
            // If there are no items, insert at index 0
            if (count == 0 || y <= 0)
            {
                loc.parentDropIndex = -1;
                loc.dropIndex = 0;
                return loc;
            }
            
            // Go through the visible elements
            var start:int = 0;//this.firstIndexInView;
            var end:int = target.numElements;//this.lastIndexInView;
            
            //the first element is always top level
            var prevTopLevelElementCount:int = 0;
            var element:ITreeLayoutElement;
            
            for (var i:int = start; i < end; i++)
            {
                element = ITreeLayoutElement(target.getElementAt(i));
                
                if (!element)
                    continue;
                
                //if our y is below this element, or above this element
                if(y < element.y || y > element.y + element.height)
                {
                    if(!element.parentElement)
                        prevTopLevelElementCount++;
                    continue;
                }
                
                var pct25:Number = element.y + (element.height * .25);
                var pct75:Number = element.y + (element.height * .75);
                var pct100:Number = element.y + element.height;
                
                if (y < pct25)
                {
                    //get the current elements parent element and 
                    //insert into that at our index
                    loc.parentDropIndex = target.getElementIndex(element.parentElement);
                    //if we have a parent, the drop index is in its children
                    if(element.parentElement)
                        loc.dropIndex = element.parentElement.childElements.getItemIndex(element);
                        //if we have no parent, the drop index is in the dataProvider
                    else
                        loc.dropIndex = prevTopLevelElementCount;
                    return loc;
                }
                else if(y >= pct25 && y <= pct75)
                {
                    //insert on ourself at 0
                    loc.parentDropIndex = i;
                    loc.dropIndex = 0;
                    return loc;
                }
                else if(y > pct75)
                {
                    //get the current elements parent element
                    //insert into that at our index
                    loc.parentDropIndex = target.getElementIndex(element.parentElement);
                    if(element.parentElement)
                        loc.dropIndex = element.parentElement.childElements.getItemIndex(element) + 1;
                        //if we have no parent, the drop index is in the dataProvider
                    else
                        loc.dropIndex = prevTopLevelElementCount + 1;
                    return loc;
                }
                
                if(!element.parentElement)
                    prevTopLevelElementCount++;
                
            }
            
            //if we didn't find it just add it as the last topLevel
            loc.parentDropIndex = -1;
            loc.dropIndex = prevTopLevelElementCount;
            return loc;
        }
        
        private function layoutCompleted():void
        {
            verticalScrollPosition += _addtDistVScrollAfterLayout;
            if(_layoutCompleteFunction != null)
                _layoutCompleteFunction();
            
            _layoutCompleteFunction = null;
        }
        
        public override function measure():void
        {
            target.measuredHeight = target.numElements * rowHeight + paddingTop + paddingBottom;    
            target.measuredMinHeight = paddingTop + paddingBottom;   
        }
        
        protected function performLayout(unscaledWidth:Number, unscaledHeight:Number):void
        {
            var y:Number = paddingTop;
            var layoutElement:ITreeLayoutElement;
            var index:int;
            
            for (index=0; index <= target.numElements; index++)
            {
                if(_dropLocation && _dropLocation.dropIndex == index)
                {
                    dropIndicator.visible = true;
                    dropIndicator.x = paddingLeft;
                    if(dropLocationInsideElement(_dropLocation))
                        dropIndicator.y = y - rowHeight/2;
                    else
                        dropIndicator.y = y;
                    dropIndicator.height = 2;
                    dropIndicator.width = unscaledWidth - paddingLeft - paddingRight;
                    //y+= rowHeight;
                }
                
                layoutElement = ITreeLayoutElement(target.getElementAt(index));
                if (!layoutElement || !layoutElement.includeInLayout)
                    continue;
                
                var xOffset:Number = (indent * layoutElement.indentLevel);
                layoutElement.indent = xOffset;
                layoutElement.setLayoutBoundsPosition(paddingLeft,y);
                layoutElement.setLayoutBoundsSize(unscaledWidth - paddingLeft - paddingRight,
                    rowHeight);
                
                y += rowHeight;
            }
            
            var contentHeight:Number = Math.max(target.measuredHeight, y + paddingBottom);
            target.setContentSize(unscaledWidth, contentHeight);
        }
        
        protected function dropLocationInsideElement(dropLocation:DropLocation):Boolean
        {
            var y:Number = dropLocation.dropPoint.y;
            if(y/rowHeight >= target.numElements)
                return false;
            
            var leftOvers:Number = y % rowHeight;
            if(leftOvers > rowHeight * .25 && leftOvers < rowHeight * .75)
                return true;
            return false;
        }
        
        public override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            if(target.numElements == 0)
                return layoutCompleted();
            
            performLayout(unscaledWidth, unscaledHeight);
            
            if(!_animate)
            {
                expandingNodes = null;
                collapsingNodes = null;
                insertedNode = null;
                return layoutCompleted();
            } 
            
            if(_slideEffect && _slideEffect.isPlaying)
                return _slideEffect.stop();
            
            var delayCompletion:Boolean = animateLayoutChange();
            
            _expandingNodes = null;
            _collapsingNodes = null;
            _insertedNode = null;
            
            if(!delayCompletion)
                layoutCompleted();
        }
        
        public function runAfterLayoutComplete(f:Function):void
        {
            _layoutCompleteFunction = f;
        }
        
        private function animateLayoutChange():Boolean
        {
            var animationType:int = getAnimationType();
            var willSlide:Boolean;
            
            if(animationType == COLLAPSING_DOWN)
            {
                regenerateEffects(true);
                _addtDistVScrollAfterLayout = -calcSlideDownHeight().down;
                willSlide = parameterizeSlideDownEffect();
            }
            else if(animationType == NONE)
            {
                willSlide = false;
                _addtDistVScrollAfterLayout = 0;
            }
            else
            {
                regenerateEffects(false);
                _addtDistVScrollAfterLayout = 0;
                willSlide = parameterizeSlideUpEffect(animationType);
            }
            
            if(willSlide)
                _slideEffect.play();
            return willSlide;
        }
        
        private function isEmptyList(value:IList):Boolean
        {
            if(!value)
                return true;
            if(value.length == 0)
                return true;
            
            return false;
        }
        
        private function getAnimationType():int
        {
            if(_insertedNode)
                return INSERTING;
            if(!isEmptyList(_expandingNodes))
                return EXPANDING;
            if(!isEmptyList(_collapsingNodes))
            {
                if(shouldSlideDown())
                    return COLLAPSING_DOWN;
                
                return COLLAPSING;
                
            }
            return NONE;
        }
        
        private function keyNodeForEffect():Object
        {
            if(_insertedNode)
                return _insertedNode;
            if(!isEmptyList(_expandingNodes))
                return _expandingNodes[0];
            if(!isEmptyList(_collapsingNodes))
                return _collapsingNodes[0];
            return null;
        }
        
        private function allElementsAfter(element:ITreeLayoutElement,includeElement:Boolean=false):Array
        {
            var index:int = target.getElementIndex(element);
            var retVal:Array = new Array();
            if(includeElement)
                retVal.push(element);
            
            for(var i:int = index + 1; i < target.numElements; i++)
            {
                if(target.getElementAt(i))
                    retVal.push(target.getElementAt(i));
            }
            return retVal;
        }
        
        private function allElementsBefore(element:ITreeLayoutElement,includeElement:Boolean=false):Array
        {
            var index:int = target.getElementIndex(element);
            var retVal:Array = new Array();
            
            for(var i:int = 0; i < index; i++)
            {
                if(target.getElementAt(i))
                    retVal.push(target.getElementAt(i));
            }
            
            if(includeElement)
                retVal.push(element);
            return retVal;
        }
        
        private function elementsFor(objects:IList):IList
        {
            var element:ITreeLayoutElement;
            var ret:ArrayCollection = new ArrayCollection();
            for each(var obj:Object in objects)
            {
                element = ITreeLayoutElement(getTreeLayoutElement(obj));
                if(element)
                    ret.addItem(element); 
            }
            return ret;
        }
        
        private function parameterizeSlideDownEffect():Boolean
        {
            var element:ITreeLayoutElement;
            var result:SlideDownResult = calcSlideDownHeight();
            var slideDownHeight:Number = result.down;
            var slideUpHeight:Number = result.up;
            
            var bottomCollapsingElement:ITreeLayoutElement = getTreeLayoutElement(_collapsingNodes[_collapsingNodes.length - 1]);
            var changedParentChild:ITreeLayoutElement = getTreeLayoutElement(_collapsingNodes[0]);
            
            if(changedParentChild == null)
                return false;
            
            var changedParentElement:ITreeLayoutElement = changedParentChild.parentElement;
            var lastChangedElement:ITreeLayoutElement = getTreeLayoutElement(_collapsingNodes[_collapsingNodes.length - 1]);
            var elementsToSlideDown:Array = allElementsBefore(changedParentElement,true);
            var elementsToSlideUp:Array = allElementsAfter(bottomCollapsingElement);
            var collaspingElements:Array = new Array();
            var slideDownMask:Rectangle = new Rectangle();
            
            if(!changedParentElement || !lastChangedElement)
                return false;
            
            for each(var node:Object in _collapsingNodes)
            {
                element = getTreeLayoutElement(node);
                if(!element)
                    continue;
                collaspingElements.push(element);
            }
            
            slideDownMask.x = 0;
            slideDownMask.width = changedParentElement.width;
            slideDownMask.y = collaspingElements[0].y;
            slideDownMask.height = _collapsingNodes.length * rowHeight;
            
            for each(element in collaspingElements)
            {
                maskElement(DisplayObject(element),slideDownMask);
            }
            
            //move element to the start
            for each(element in elementsToSlideDown)
            {
                _slideEffect.targets.push(element);
            }
            
            for each(element in elementsToSlideUp)
            {
                _slideEffect.targets.push(element);
            }
            _slideEffect.captureStartValues();
            
            //move elements to the end
            for each(element in elementsToSlideDown)
            {
                element.y += slideDownHeight;
            }
            
            for each(element in elementsToSlideUp)
            {
                element.y -= slideUpHeight;
            }
            _slideEffect.captureEndValues();
            return true;
            
        }
        
        private function parameterizeSlideUpEffect(animationType:int):Boolean
        {
            if(animationType == NONE)
                return false;
            
            var element:ITreeLayoutElement;
            
            var dist:Number;
            var maxDist:Number = 0;
            var maxElement:ITreeLayoutElement;
            
            var elementsToMeaure:IList = animationType == EXPANDING ? elementsFor(_expandingNodes) : 
                animationType == COLLAPSING ? elementsFor(_collapsingNodes) :
                new ArrayCollection([getTreeLayoutElement(_insertedNode)]);
            
            var changedParentChild:ITreeLayoutElement = getTreeLayoutElement(keyNodeForEffect());
            if(changedParentChild == null)
                return false;
            
            var changedParentElement:ITreeLayoutElement = changedParentChild.parentElement;
            var elementsToChange:Array = allElementsAfter(changedParentElement);
            var maskRect:Rectangle = new Rectangle();
            
            if(!changedParentElement)
                return false;
            
            maskRect.x = 0;
            maskRect.y = changedParentElement.y + changedParentElement.height;
            maskRect.height = UIComponent.DEFAULT_MAX_HEIGHT;
            maskRect.width = changedParentElement.width;
            
            //find out the max distance to move
            for each(element in elementsToMeaure)
            {
                dist = element.y - changedParentElement.y;
                if(dist > maxDist)
                {
                    maxDist = dist;
                    maxElement = element;
                }
            }
            
            //move element to the start
            for each(element in elementsToChange)
            {
                if(animationType == EXPANDING ||
                    animationType == INSERTING)
                    element.y -= maxDist;
                
                maskElement(DisplayObject(element),maskRect);
                _slideEffect.targets.push(element);
            }
            
            _slideEffect.captureStartValues();
            
            
            //move elements to the end
            for each(element in elementsToChange)
            {
                if(animationType == COLLAPSING)
                    element.y -= maxDist;
                else
                    element.y += maxDist;
            }
            
            _slideEffect.captureEndValues();
            
            return true;
        }
        
        private function getElementIndex(element:ITreeLayoutElement):int
        {
            if(target)
                return target.getElementIndex(element);
            return -1;
        }
        
        private function invalidateSize():void
        {
            if(target)
                target.invalidateSize();
        }
        
        private function invalidateDisplayList():void
        {
            if(target)
                target.invalidateDisplayList();
        }
        
        private function getTreeLayoutElement(obj:Object):ITreeLayoutElement
        {
            var element:ITreeLayoutElement;
            for (var i:int = 0; i < target.numElements; i++)
            {
                element = ITreeLayoutElement(target.getElementAt(i));
                if(element && element.data == obj)
                    return element;
            }
            
            return null;
        }
        
        public function get indent():int
        {
            return _indent;
        }
        
        public function set indent(value:int):void
        {
            _indent = value;
            invalidateDisplayList();
        }
        
        public function get expandingNodes():IList
        {
            return _expandingNodes;
        }
        
        public function set expandingNodes(value:IList):void
        {
            _expandingNodes = value;
            invalidateDisplayList();
        }
        
        public function get collapsingNodes():IList
        {
            return _collapsingNodes;
        }
        
        public function set collapsingNodes(value:IList):void
        {  
            _collapsingNodes = value;
            invalidateDisplayList();
        }
        
        private function shouldSlideDown():Boolean
        {
            var lastNode:ITreeLayoutElement = getTreeLayoutElement(_collapsingNodes[_collapsingNodes.length - 1]);
            var index:int = target.getElementIndex(lastNode);
            
            if(index == -1)
                return false;
            
            var viewHeight:Number = target.height;
            var heightChange:Number = _collapsingNodes.length * rowHeight;
            var height:Number = target.contentHeight;
            var newHeight:Number = Math.max(viewHeight,height - heightChange);
            
            //if the vertical scroll position plus the viewHeight is greater then new height,
            //that means there would be extra space if we closed up, and we do not want that
            if(verticalScrollPosition + viewHeight > newHeight)
                return true;
            
            return false;
        }
        
        private function calcSlideDownHeight():SlideDownResult
        {
            var lastNode:ITreeLayoutElement = getTreeLayoutElement(_collapsingNodes[_collapsingNodes.length - 1]);
            var index:int = target.getElementIndex(lastNode);
            
            if(index == -1)
                return new SlideDownResult(0,0);
            
            var value:Number = _collapsingNodes.length * rowHeight;
            
            if(verticalScrollPosition - value <= 0)
                return new SlideDownResult(verticalScrollPosition,value - verticalScrollPosition);
            
            return new SlideDownResult(value,0);
        }
        
        public function get animate():Boolean
        {
            return _animate;
        }
        
        public function set animate(value:Boolean):void
        {
            _animate = value;
        }
        
        protected override function scrollPositionChanged():void
        {
            super.scrollPositionChanged();
            var haveMasks:Boolean = false;
            for each(var test:Object in _masks)
            {
                haveMasks = true;
                break;
            }
            
            if(!haveMasks)
                return;
            
            _previousVerticalScrollPosition = _currentVerticalScrollPosition;
            _currentVerticalScrollPosition = verticalScrollPosition;
            
            if(_currentVerticalScrollPosition < 0 || _previousVerticalScrollPosition < 0)
                return;
            
            var mask:Sprite;
            for each(var maskObj:Object in _masks)
            {
                mask = maskObj.mask;
                mask.y -= _currentVerticalScrollPosition - _previousVerticalScrollPosition;
            }
        }
        
        /**
         * Tree layout does not support virtual layouts
         */ 
        public override function get useVirtualLayout():Boolean 
        { 
            return false; 
        }
        
        public override function set useVirtualLayout(value:Boolean):void
        {
            super.useVirtualLayout = false;
        }
        
        public function get insertedNode():Object
        {
            return _insertedNode;
        }
        
        public function set insertedNode(value:Object):void
        {
            _insertedNode = value;
            invalidateDisplayList();
        }
        
        public function get paddingTop():Number
        {
            return _paddingTop;
        }
        
        public function set paddingTop(value:Number):void
        {
            _paddingTop = value;
            invalidateSize();
            invalidateDisplayList();
        }
        
        public function get paddingBottom():Number
        {
            return _paddingBottom;
        }
        
        public function set paddingBottom(value:Number):void
        {
            _paddingBottom = value;
            invalidateSize();
            invalidateDisplayList();
        }
        
        public function get paddingLeft():Number
        {
            return _paddingLeft;
        }
        
        public function set paddingLeft(value:Number):void
        {
            _paddingLeft = value;
            invalidateSize();
            invalidateDisplayList();
        }
        
        public function get paddingRight():Number
        {
            return _paddingRight;
        }
        
        public function set paddingRight(value:Number):void
        {
            _paddingRight = value;
            invalidateSize();
            invalidateDisplayList();
        }
        
        public function get rowHeight():Number
        {
            return _rowHeight;
        }
        
        public function set rowHeight(value:Number):void
        {
            _rowHeight = value;
            invalidateSize();
            invalidateDisplayList();
        }
    }
}

import flash.display.Sprite;
import flash.geom.Rectangle;

class SlideDownResult
{
    public var down:Number;
    public var up:Number;
    
    public function SlideDownResult(down:Number,up:Number)
    {
        this.down = down;
        this.up = up;
    }
}

class MaskData
{
    public var mask:Sprite;
    public var bounds:Rectangle;
    
    public function MaskData(mask:Sprite,bounds:Rectangle)
    {
        this.mask = mask;
        this.bounds = bounds;
    }
}