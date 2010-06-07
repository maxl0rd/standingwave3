package com.noteflight.standingwave3.modulation
{
    
    import __AS3__.vec.Vector;
    
    import com.noteflight.standingwave3.elements.*;
    
    /** The base class for concrete modulation data. */
    
    public class AbstractModulationData
    {
        protected var _keyframes:Vector.<ModulationKeyframe>;
        protected var _rate:uint;
        protected var _sorted:Boolean;
        
        public function AbstractModulationData(rate:uint = 44100)
        {
            this._rate = rate;
            this._keyframes = new Vector.<ModulationKeyframe>();
            this._sorted = true;
        }
        
        public function get rate():uint
        {
            return _rate;
        }
    
        public function getKeyframes(fromOffset:Number=0, toOffset:Number=-1):Array
        {
           
            sort();   
            
            // If toOffset is -1, then it means get all the keyframes after the fromOffset
            // We need to set toOffset to a point after the last position value
            
            if (toOffset == -1) {
                toOffset = ModulationKeyframe( _keyframes[ _keyframes.length ] ).position + 1;
            }
            
            var result:Array = new Array();
            var kf:ModulationKeyframe;
            
            for (var keyframeNum:int=0; keyframeNum < _keyframes.length; keyframeNum++) {
                kf = _keyframes[keyframeNum];
                if (kf.position >= fromOffset && kf.position <= toOffset) {
                    result.push(kf);
                } else if (kf.position > toOffset) {
                    return result;
                }
            }
            return result;
        }
        
        /** Find the keyframe exactly at this offset */
        protected function getKeyframeAt(offset:Number):ModulationKeyframe
        {
            var kf:ModulationKeyframe;
            for (var keyframeNum:int=0; keyframeNum < _keyframes.length; keyframeNum++) {
                kf = _keyframes[keyframeNum];
                if (kf.position == offset) {
                    return kf;
                }
            }
            return null;
        }
        
        /** Find the keyframe before this offset */
        protected function getKeyframeBefore(offset:Number):ModulationKeyframe
        {
           
            sort();
            
            // Start with the first one
            var result:ModulationKeyframe = _keyframes[0]; 
            var kf:ModulationKeyframe;
            
            for (var keyframeNum:int=0; keyframeNum < _keyframes.length; keyframeNum++) {
                kf = _keyframes[keyframeNum];
                if (kf.position < offset) {
                    result = kf;
                } else {
                    return result;
                }
            }
            
            return result;
            
        }
        
        /** Find the keyframe before this offset */
        protected function getKeyframeAfter(offset:Number):ModulationKeyframe
        {
            sort();
            
            var kf:ModulationKeyframe;
            for (var keyframeNum:int=0; keyframeNum < _keyframes.length; keyframeNum++) {
                kf = _keyframes[keyframeNum];
                if (kf.position > offset) {
                    return kf;
                }
            }
            
            return null;
            
        }
        
        /** 
         * Insert the new key frame
         */ 
        protected function insert(kf:ModulationKeyframe):void 
        {
            _keyframes.push(kf);
            sort();
            // _sorted = false;
        }
        
        protected function sort():void 
        {
            if (_sorted) {
                return;
            } else {
                _keyframes.sort(sortPositions);
                _sorted = true;   
            }
        }
        
        protected function sortPositions(x:ModulationKeyframe, y:ModulationKeyframe):Number
        {
            if (x.position > y.position) {
                return -1;
            } else if (x.position < y.position) {
                return 1;
            }
            return 0;
        }

    }
}