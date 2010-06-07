package com.noteflight.standingwave3.modulation
{
    public class ModulationKeyframe
    {
        public var position:Number;
        public var value:Number;
        
        public function ModulationKeyframe(position:Number, value:Number=0)
        {
            this.position = position;
            this.value = value;
        }

    }
}