package com.noteflight.standingwave3.modulation
{
    public class VibratoModulation implements IPerformableModulation
    {
        
        public var startTime:Number;
        public var endTime:Number;
        public var frequency:Number;
        public var maxValue:Number;
        public var minValue:Number;
        
        public function VibratoModulation(startTime:Number, endTime:Number, frequency:Number, minValue:Number, maxValue:Number)
        {
            this.startTime = startTime;
            this.endTime = endTime;
            this.frequency = frequency;
            this.maxValue = maxValue;
            this.minValue = minValue;
        }

        public function realize(data:IModulationData):void
        {
            var position:Number = Math.floor( startTime * data.rate );
            
            var framesPerHalfCycle:Number = Math.floor( 0.5 * data.rate / frequency );
            var endPosition:Number = endTime * data.rate;
            
            while (position <= endPosition) 
            {
                // Add the new keyframes to create a triangle shaped modulation
                // The realization will always complete a cycle of vibrato beyond the end time
                data.addKeyframe( new ModulationKeyframe(position-1, minValue) );
                data.addKeyframe( new ModulationKeyframe(position, minValue) );
                position += framesPerHalfCycle;
                data.addKeyframe( new ModulationKeyframe( position, maxValue ) );
                data.addKeyframe( new ModulationKeyframe( position+1, maxValue ) );
                position += framesPerHalfCycle;
            }
        }
        
    }
}