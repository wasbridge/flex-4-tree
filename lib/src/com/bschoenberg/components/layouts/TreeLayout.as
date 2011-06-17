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
        
        private var _verticalScrollAfterLayout:Number = 0;        
        private var _layoutCompleteFunction:Function;
        
        private var _paddingTop:Number = 0;
        private var _paddingBottom:Number = 0;
        private var _paddingLeft:Number = 0;
        private var _paddingRight:Number = 0;
        private var _rowHeight:Number = 80;
        
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
            if (!dropIndicator)
                return;
            
            // Make the drop indicator invisible, we'll make it visible 
            // only if successfully sized and positioned
            dropIndicator.visible = false;
            
            // Check for drag scrolling
            var dragScrollElapsedTime:int = 0;
            if (_dragScrollTimer)
                dragScrollElapsedTime = _dragScrollTimer.currentCount * _dragScrollTimer.delay;
            
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
        }
        
        /**
         *  @inherit
         */
        public override function hideDropIndicator():void
        {
            stopDragScrolling();
            if (dropIndicator)
                dropIndicator.visible = false;
        }
        
        /**
         * @inherit
         */
        protected override function calculateDropIndex(x:Number, y:Number):int
        {
            var tdl:TreeDropLocation = calculateTreeDropIndicies(x,y);
            if(tdl.parentDropIndex == -1)
                return tdl.dropIndex;
            
            // Iterate over the visible elements
            var layoutTarget:GroupBase = target;
            var count:int = layoutTarget.numElements;
            
            // If there are no items, insert at index 0
            if (count == 0 || y <= 0)
            {
                return 0;
            }
            
            // Go through the visible elements
            var minDistance:Number = Number.MAX_VALUE;
            var bestIndex:int = -1;
            var start:int = 0;//this.firstIndexInView;
            var end:int = target.numElements;//this.lastIndexInView;
            
            //the first element is always top level
            var element:ITreeLayoutElement;
            
            for (var i:int = start; i <= end; i++)
            {
                element = ITreeLayoutElement(target.getElementAt(i));
                
                var elementBounds:Rectangle = this.getElementBounds(i);
                if (!elementBounds || !element)
                    continue;
                
                //if we are in an element insert into that element if we are
                //in the middle 50%
                if (elementBounds.top <= y && y <= elementBounds.bottom)
                {
                    var lowerBound:Number = elementBounds.y + elementBounds.height / 4;
                    var upperBound:Number = elementBounds.y + (3 * elementBounds.height / 4);
                    
                    // we are in the middle 50%
                    if(y > lowerBound && y < upperBound)
                    {
                        //return the new parent elements index + 1
                        return i + 1;
                    }
                        //we are in the top 25%, we will be dropping on top
                    else if (y > elementBounds.y && y < lowerBound)
                    {
                        return i - 1;
                    }
                        //we are in the bottom 25% we will be dropping below this elements open children
                    else if(y > upperBound && y < elementBounds.y + elementBounds.height)
                    {
                        var expandedChildren:IList = element.expandedChildren;
                        var lastOpenElement:ITreeLayoutElement = 
                            ITreeLayoutElement(expandedChildren.getItemAt(expandedChildren.length - 1));
                        return target.getElementIndex(lastOpenElement) + 1;
                    }
                }
            }
            
            return layoutTarget.numElements - 1;
        }
        
        /**
         * @inherit
         */
        protected override function calculateDropIndicatorBounds(dropLocation:DropLocation):Rectangle
        {
            var bounds:Rectangle = this.getElementBounds(dropLocation.dropIndex);
            if(!bounds)
                return new Rectangle(0,target.height,target.width,2);
            bounds.height = 2;
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
            var retVal:TreeDropLocation = calculateTreeDropIndicies(dragEvent.stageX,dragEvent.stageY);
            retVal.dragEvent = dragEvent;
            retVal.dropPoint = target.globalToLocal(new Point(dragEvent.stageX,dragEvent.stageY));
            return retVal;
        }
        
        protected function calculateTreeDropIndicies(x:Number, y:Number):TreeDropLocation
        {
            var loc:TreeDropLocation = new TreeDropLocation();
            
            // Iterate over the visible elements
            var layoutTarget:GroupBase = target;
            var count:int = layoutTarget.numElements;
            
            // If there are no items, insert at index 0
            if (count == 0 || y <= 0)
            {
                loc.parentDropIndex = -1;
                loc.dropIndex = 0;
                return loc;
            }
            
            // Go through the visible elements
            var minDistance:Number = Number.MAX_VALUE;
            var bestIndex:int = -1;
            var start:int = 0;//this.firstIndexInView;
            var end:int = target.numElements;//this.lastIndexInView;
            
            //the first element is always top level
            var prevTopLevelElementCount:int = 0;
            var element:ITreeLayoutElement;
            
            for (var i:int = start; i <= end; i++)
            {
                element = ITreeLayoutElement(target.getElementAt(i));
                
                var elementBounds:Rectangle = this.getElementBounds(i);
                if (!elementBounds || !element)
                    continue;
                
                //if we are in an element insert into that element if we are
                //in the middle 50%
                if (elementBounds.top <= y && y <= elementBounds.bottom)
                {
                    var lowerBound:Number = elementBounds.y + elementBounds.height / 4;
                    var upperBound:Number = elementBounds.y + (3 * elementBounds.height / 4);
                    
                    if(y > lowerBound && y < upperBound)
                    {
                        //insert on ourself at 0
                        loc.parentDropIndex = i;
                        loc.dropIndex = 0;
                        return loc;
                    }
                    else if (y > elementBounds.y && y < lowerBound)
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
                    else if(y > upperBound && y < elementBounds.y + elementBounds.height)
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
            verticalScrollPosition += _verticalScrollAfterLayout;
            if(_layoutCompleteFunction != null)
                _layoutCompleteFunction();
            
            _layoutCompleteFunction = null;
        }
        
        public override function measure():void
        {
            target.measuredHeight = target.numElements * rowHeight + paddingTop + paddingBottom;    
            target.measuredMinHeight = paddingTop + paddingBottom;   
        }
        
        public override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            if(target.numElements == 0)
                return layoutCompleted();
            
            var y:Number = paddingTop;
            var layoutElement:ITreeLayoutElement;
            var index:int;
            for (index=0; index < target.numElements; index++)
            {
                layoutElement = ITreeLayoutElement(target.getElementAt(index));
                if (!layoutElement || !layoutElement.includeInLayout)
                    continue;
                
                var xOffset:Number = (indent * layoutElement.indentLevel);
                layoutElement.indent = xOffset;
                layoutElement.x = paddingLeft;
                layoutElement.y = y;
                layoutElement.height = rowHeight;
                layoutElement.width = unscaledWidth - paddingLeft - paddingRight;
                
                y += rowHeight;
            }
            
            var contentHeight:Number = Math.max(target.measuredHeight, y + paddingBottom);
            
            target.setContentSize(unscaledWidth,
                contentHeight);
            
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
            var hasSlid:Boolean;
            
            if(animationType == COLLAPSING_DOWN)
            {
                regenerateEffects(true);
                _verticalScrollAfterLayout = -calcSlideDownHeight().down;
                hasSlid = parameterizeSlideDownEffect();
            }
            else if(animationType == NONE)
            {
                hasSlid = false;
                _verticalScrollAfterLayout = 0;
            }
            else
            {
                regenerateEffects(false);
                _verticalScrollAfterLayout = 0;
                hasSlid = parameterizeSlideUpEffect(animationType);
            }
            
            if(hasSlid)
                _slideEffect.play();
            return hasSlid;
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