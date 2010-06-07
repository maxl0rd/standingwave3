package com.noteflight.standingwave3.modulation
{
    public class BendModulation implements IPerformableModulation
    {
        public var startTime:Number;
        public var endTime:Number;
        public var startValue:Number;
        public var endValue:Number;
        
        /** A BendModulation indicates a change in value over startTime to endTime.  */
        public function BendModulation(startTime:Number, startValue:Number, endTime:Number, endValue:Number)
        {
            this.startTime = startTime;
            this.endTime = endTime;
            this.startValue = startValue;
            this.endValue = endValue;
        }

        /** 
         * Realization into data 
         */
        public function realize(data:IModulationData):void
        {
            var position:Number = Math.floor( startTime * data.rate );
            if (position > 0) 
            {
                // If necessary add a keyframe before, so the previous value stays constant until the bend starts
                var previousValue:Number = data.getValueAtPosition(position-1);
                data.addKeyframe( new ModulationKeyframe(position-1, previousValue) );
            }
            // Add the new start value keyframe
            data.addKeyframe( new ModulationKeyframe(position, startValue) );
            // Add the new end value keyframe
            position = Math.floor (endTime * data.rate);
            data.addKeyframe( new ModulationKeyframe(position, endValue ) );
            // Add the hold keyframe
            data.addKeyframe( new ModulationKeyframe( position+1, endValue ) );
        }

    }
}