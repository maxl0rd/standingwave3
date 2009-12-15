////////////////////////////////////////////////////////////////////////////////
//
//  NOTEFLIGHT LLC
//  Copyright 2009 Noteflight LLC
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////


package com.noteflight.standingwave3.performance
{
    import __AS3__.vec.Vector;
    
    import com.noteflight.standingwave3.elements.*;
    
    /**
     * An AudioPerformer takes a Performance containing a queryable collection of
     * PerformanceElements (i.e. timed playbacks of audio sources) and exposes
     * it as an IAudioSource that can realize time samples of the performance output.
     * The main job of the AudioPerformer is to mix together all the performance
     * elements, time-shifted appropriately.
     */
    public class AudioPerformer implements IAudioSource
    {
    	/** Fixed gain factor to apply to all sources while mixing into the output buss */
    	public var mixGain:Number = 1.0;
    	
        private var _performance:IPerformance;
        private var _position:Number = 0;
        private var _frameCount:Number = 0;
        private var _activeElements:Vector.<PerformanceElement>;
                
        /**
         * Construct a new AudioPerformer for a performance.
         *  
         * @param performance the IPerformance implementation to be performed when this
         * AudioPerformer is rendered as an IAudioSource.
         */
        public function AudioPerformer(performance:IPerformance)
        {
            _performance = performance;
            _frameCount = performance.frameCount;
            resetPosition();
        }
        
        /**
         * The total duration of this performance.  The duration may be decreased from its default
         * to truncate the performance, or increased in order to extend it with silence. 
         */
        public function get duration():Number
        {
            return frameCount / descriptor.rate;
        }
        
        public function set duration(value:Number):void
        {
            frameCount = Math.floor(value * descriptor.rate);
        }
        
        /**
         * The AudioDescriptor describing the audio characteristics of this source.
         */
        public function get descriptor():AudioDescriptor
        {
            return _performance.descriptor;
        }
        
        /**
         * Return the number of sample frames in this source.
         */
        public function get frameCount():Number
        {
            return _frameCount;
        }
        
        public function set frameCount(value:Number):void
        {
            _frameCount = value;
        }
        
        /**
         * @inheritDoc
         */
        public function get position():Number
        {
            return _position;
        }
        
        /**
         * @inheritDoc
         */
        public function resetPosition():void
        {
            _position = 0;
            _activeElements = new Vector.<PerformanceElement>();
        }
        
        
        
        /**
         * @inheritDoc
        */
        public function getSample(numFrames:Number):Sample
        {
            // create our result sample and zero its samples out so we can add in the
            // audio from performance events that intersect our time interval.
            var sample:Sample = new Sample(descriptor, numFrames);
            
            // Maintain a list of all PerformanceElements known to be active at the current
            // audio cursor position.
            var _stillActive:Vector.<PerformanceElement> = new Vector.<PerformanceElement>();
            
            var element:PerformanceElement;
            var i:Number;
            var j:Number;
            var c:Number;
            
            // Prior to generating any audio date, update the active element list with 
            // any PerformanceElements that intersect the time interval of interest.
            //
            var elements:Vector.<PerformanceElement> = _performance.getElementsInRange(_position, _position + numFrames);
            for (i = 0; i < elements.length; i++)
            {
                elements[i].source.resetPosition();
                _activeElements.push(elements[i]);
            }

            // Process all active elements by adding the active section of their signal
            // into our result sample, and retaining them in the next copy of the active list
            // if they continue past this time window.
            //
            for each (element in _activeElements)
            {
                // First, determine the offset within our result where we'll put this element's first frame
                var activeOffset:Number = Math.max(0, element.start - _position);
                
                // And determine the number of frames for this element that can be processed in this chunk
                var activeLength:Number = Math.round( Math.min(numFrames - activeOffset, element.end - (_position + activeOffset)) );
                
                // If anything to do, then add the element's signal into our result.
                if (activeLength > 0)
                {
                	// Optimize the mixing of IDirectAccessSources vs IAudioSources
                	if (element.source is IDirectAccessSource) {
                		var p:Number = element.source.position;
                		// Mix it in, without using an intermediate sample
                		IDirectAccessSource(element.source).useSample(activeLength); // element.source.position advances and caches if needed
                		sample.mixInDirectAccessSource(IDirectAccessSource(element.source), p, mixGain, activeOffset, activeLength);
                	} else {
                		// Do a regular getSample, mix, and destroy
                    	var elementSample:Sample = element.source.getSample(activeLength);
                    	sample.mixIn(elementSample, mixGain, activeOffset);
                    	elementSample.destroy();
                    }
                }
                
                // If this element is still going to be active in the next batch of frames, take note of that.
                if (element.end > _position + numFrames)
                {
                    _stillActive.push(element);
                }
            }
            
            _activeElements = _stillActive;
            _position += numFrames;

            return sample;
        }
        
        
        public function clone():IAudioSource
        {
            var p:AudioPerformer = new AudioPerformer(_performance.clone());
            p._frameCount = _frameCount; 
            return p;
        }
    }
}