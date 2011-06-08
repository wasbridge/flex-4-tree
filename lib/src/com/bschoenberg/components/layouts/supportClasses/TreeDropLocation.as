package com.bschoenberg.components.layouts.supportClasses
{
    import spark.layouts.supportClasses.DropLocation;
    
    public class TreeDropLocation extends DropLocation
    {   
        public var parentDropIndex:int;
        
        public function TreeDropLocation()
        {
            super();
        }
    }
}