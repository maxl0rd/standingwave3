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
    import com.noteflight.standingwave3.utils.AudioUtils;
    
    /**
     * An AudioPerformer takes a Performance containing a queryable collection of
     * PerformableAudioSources (i.e. timed playbacks of audio sources) and exposes
     * it as an IAudioSource that can realize time samples of the performance output.
     * The main job of the AudioPerformer is to mix together all the performance
     * elements, time-shifted appropriately.
     */
    public class AudioPerformer implements IAudioSource
    {
    	/** Fixed gain factor to apply to all sources while mixing into the output buss */
    	public var mixGain:Number = 0.0;
    	
        private var _performance:IPerformance;
        private var _position:Number = 0;
        private var _frameCount:Number = 0;
        private var _activeElements:Vector.<PerformableAudioSource>;
		private var _descriptor:AudioDescriptor;
                
        /**
         * Construct a new AudioPerformer for a performance.
         *  
         * @param performance the IPerformance implementation to be performed when this
         * AudioPerformer is rendered as an IAudioSource.
         * @param descriptor the audio descriptor of the output samples
         */
        public function AudioPerformer(performance:IPerformance, descriptor:AudioDescriptor)
        {
            _performance = performance;
            _frameCount = performance.frameCount;
            _descriptor = descriptor;
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
         * This can be set explicitly (for performance reasons) or default to whatever it
         * finds in the performance (which can be annoying at times)
         */
        public function get descriptor():AudioDescriptor
        {
        	return _descriptor;
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
            _activeElements = new Vector.<PerformableAudioSource>();
        }
        
        
        
        /**
         * @inheritDoc
        */
        public function getSample(numFrames:Number):Sample
        {
        	
            // create our result sample and zero its samples out so we can add in the
            // audio from performance events that intersect our time interval.
            var sample:Sample = new Sample(_descriptor, numFrames);
                        
            // Maintain a list of all PerformableAudioSources known to be active at the current
            // audio cursor position.
            var _stillActive:Vector.<PerformableAudioSource> = new Vector.<PerformableAudioSource>();
            
            var element:PerformableAudioSource;
            var i:Number;
            var j:Number;
            var c:Number;
            
            // Prior to generating any audio date, update the active element list with 
            // any PerformableAudioSources that intersect the time interval of interest.
            //
            var elements:Vector.<PerformableAudioSource> = _performance.getElementsInRange(_position, _position + numFrames);
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
      				// Mix the element into the output mix bus
                	mix(sample, element, activeOffset, activeLength);	
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
        
        /** Mix buss. Can mix stereo samples, mono samples, or pan out mono sources to a stereo buss.
        */
        private function mix(sample:Sample, element:PerformableAudioSource, activeOffset:Number, activeLength:Number, stereoize:Boolean=false):void
        {
        	// Calculate gain which is the element's mix gain plus the total mix bus gain
        	var fgain:Number = AudioUtils.decibelsToFactor( mixGain + element.gain );
        	var p:Number;
        	var elementSample:Sample;
        	
        	if (_descriptor.channels == 2 && element.source.descriptor.channels == 1) {
         		// Do a stereo panning mix of mono elements. 
         		// Look at the pan position of each element and call mixInPan instead
         		if (descriptor.rate == element.source.descriptor.rate) {
	         		var gains:Object = AudioUtils.panToFactors(element.pan);
	         		gains.right *= fgain;
	         		gains.left *= fgain;
	            	if (testIDirect(element, activeLength)) {
	            		p = element.source.position;
	            		IDirectAccessSource(element.source).useSample(activeLength);
	            		sample.mixInPanDirectAccessSource(IDirectAccessSource(element.source), p, gains.left, gains.right, activeOffset, activeLength);
	            	} else {
	                	elementSample = element.source.getSample(activeLength);
	                	sample.mixInPan(elementSample, gains.left, gains.right, activeOffset);
	                	elementSample.destroy();
	                }	
	          	} else {
	          		throw new Error("Cannot mix sources with incompatible AudioDescriptors.");
	          	}
         	} else {
         		// Mix congruent descriptors straight through
    			// Optimize the mixing of IDirectAccessSources vs IAudioSources
    			if (AudioDescriptor.compare(descriptor, element.source.descriptor)) {
	            	if (testIDirect(element, activeLength)) {
	            		p = element.source.position;
	            		IDirectAccessSource(element.source).useSample(activeLength);
	            		// Mix it in, without using an intermediate sample
	            		sample.mixInDirectAccessSource(IDirectAccessSource(element.source), p, fgain, activeOffset, activeLength);
	            	} else {
	            		// Do a regular getSample, mix, and destroy
	                	elementSample = element.source.getSample(activeLength);
	                	sample.mixIn(elementSample, fgain, activeOffset);
	                	elementSample.destroy();
	                }	
	      		} else {
	      			throw new Error("Cannot mix sources with incompatible AudioDescriptors.");
	      		}
         	}
        }
        
        /** 
         * Determine whether an element's source is usable as an IDirectSource for this range 
         */
        private function testIDirect(element:PerformableAudioSource, numFrames:Number):Boolean 
        {
        	
        	// LET'S TRY TO GET THIS WORKING RIGHT 
        	
        	var source:IDirectAccessSource;
        	if (element.source is IDirectAccessSource) {
        		// Fill the source to this point, and then check that the pointer is valid
        		source = IDirectAccessSource(element.source);
				source.fill(element.source.position + numFrames);
        		if ( source.getSamplePointer(element.source.position + numFrames - 1) ) {
        			// We can get a pointer to the complete range of the sample we need
        			return true;
        		} else {
        			// This range is not valid for direct access for some reason
        			// Treat it as an IAudioSource
        			return false;
        		}
        	} else {
        		// Not an IDirectAudioSource
        		return false;
        	}
        	
        }
        
        public function clone():IAudioSource
        {
            var p:AudioPerformer = new AudioPerformer(_performance.clone(), _descriptor);
            p._frameCount = _frameCount; 
            return p;
        }
    }
}