package com.noteflight.standingwave3.modulation
{
    public class ValueModulation implements IPerformableModulation
    {
        public var time:Number;
        public var value:Number;
        
        /** A value modulation indicates a change in value at a certain time in seconds */
        public function ValueModulation(time:Number, value:Number)
        {
            this.time = time;
            this.value = value;
        }

        /** Realization into data */
        public function realize(data:IModulationData):void
        {
            var position:Number = Math.floor( time * data.rate );
            if (position > 1) 
            {
                // Add a keyframe before, so the previous value stays constant instead of ramping up
                var previousValue:Number = data.getValueAtPosition(position-1);
                if (previousValue != value)
                {
                    data.addKeyframe( new ModulationKeyframe(position-1, previousValue) );
                }
            }
            // Add the new value keyframe
            data.addKeyframe( new ModulationKeyframe(position, value) );
        }

    }
}