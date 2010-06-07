package com.noteflight.standingwave3.modulation
{
    import __AS3__.vec.Vector;    

    public class LineData extends AbstractModulationData implements IModulationData
    {
        public function LineData(rate:uint = 44100)
        {
            super(rate);
            this._keyframes[0] = new ModulationKeyframe(0, 0);
        }
        
        // Getter, mainly for debugging
        public function get keyframes():Vector.<ModulationKeyframe>
        {
            sort();
            return _keyframes;
        }
        
        public function addKeyframe(kf:ModulationKeyframe):void
        {
            insert(kf);
        }
        
        /** Return the value of the modulation data at the specififed position */
        public function getValueAtPosition(position:Number):Number
        {
            // See if there's a keyframe at this position
            var kfAt:ModulationKeyframe = getKeyframeAt(position);
            if (kfAt) {
                return kfAt.value;
            }
            // Get the keyframes on either side of this position
            var kfBefore:ModulationKeyframe = getKeyframeBefore(position);
            var kfAfter:ModulationKeyframe = getKeyframeAfter(position);
            // Else, are we after the last keyframe?
            if (kfAfter == null) {
                return kfBefore.value;
            } 
            // Else interpolate the value in between
            var fractionalPosition:Number =  (position - kfBefore.position) / (kfAfter.position - kfBefore.position);
            var value:Number = linearInterpolate( kfBefore.value, kfAfter.value, fractionalPosition);
            return value;
        }
        
        // Return all of the segments for a range... ie from end to end including keyframes
        public function getSegments(fromOffset:Number, toOffset:Number):Array
        {
            var result:Array = [ fromOffset, toOffset ];
            var keyframesInRange:Array = getKeyframes(fromOffset, toOffset);
            if (keyframesInRange.length == 0) {
                // No keyframes in range
                return result; 
            }
            // Else, add all the keyframes in 
            for each (var kf:ModulationKeyframe in keyframesInRange) {
                if (kf.position > fromOffset && kf.position < toOffset) {
                    // Avoid duplicating end points, and accidental out-of-bounds conditions
                    result.push(kf.position);
                }
            }
            // Make sure all the segments are in order
            result.sort( Array.NUMERIC );
            if (result.length % 2 != 0) {
                trace("Missing modulation keyframe condition.");
                result.unshift();
            }
            return result;
        }
        
        public function getModForRange(fromOffset:Number, toOffset:Number):Mod
        {
            // A line segment through these points.
            // Doesn't check if it's violating keyframes. Think...
            var m:Mod = new Mod();
            m.y0 = m.y1 = getValueAtPosition(fromOffset);
            m.y2 = m.y3 = getValueAtPosition(toOffset);
            return m;
        } 
        
        protected function linearInterpolate(x1:Number, x2:Number, fraction:Number):Number
        {
            return ( x1 + (x2-x1)*fraction );
        }

    }
}