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


package com.noteflight.standingwave3.filters
{
    import com.noteflight.standingwave3.elements.*;
    import com.noteflight.standingwave3.modulation.Mod;
    
    /**
     * DecayFilter passes the signal unchanged until the fade is reached,
     * and then fades it out with the supplied envelope.
     */
    public class DecayFilter extends AbstractFilter implements IDirectAccessSource
    {
    
        public static const MIN_SIGNAL:Number = -50; //db
        
        /** Time to start fading, in frames. */
 		private var _fadeStart:Number;
 		
 		/** Fade time in frames */
 		private var _fadeDuration:Number;
 		
        /**
         * Create a new DecayFilter. 
         * @param source the underlying audio source
         * @param fadeStart the time in seconds to begin fade out
         * @param fadeDuration the time in seconds for the fade to last
         */
        public function DecayFilter(source:IAudioSource, fadeStart:Number = int.MAX_VALUE, fadeDuration:Number = int.MAX_VALUE)
        {
            super(source);
            this.fadeStart = fadeStart;
            this.fadeDuration = fadeDuration;
        }
        
        /**
        * Set fade start time in seconds
        */
        public function set fadeStart(t:Number):void 
        {
        	_fadeStart = t * _source.descriptor.rate;
        }
        
        /**
        * Set fade time in seconds
        */
        public function set fadeDuration(t:Number):void 
        {
        	_fadeDuration = t * _source.descriptor.rate;
        }
        
        /**
        * Get fade start time in seconds
        */
        public function get fadeStart():Number
        {
        	return _fadeStart /  _source.descriptor.rate;
        }
        
        /**
        * Get Fade time in seconds
        */
        public function get fadeDuration():Number
        {
        	return _fadeDuration / _source.descriptor.rate;
        }
		
		/**
		 * The filter crops the source after the fade end,
		 * and so can shorten the entire source duration.
		 */        
        override public function get frameCount():Number
		{
			// Return the lesser of the source length or the fade end
			return Math.min(_source.frameCount, _fadeStart + _fadeDuration);
		} 
        
        /**
         * Returns the decibel gain amount at any position
         */
        private function fadeGainAtPosition(p:Number):Number {
        	if (p < _fadeStart) {
        		return 0;
        	}
        	return MIN_SIGNAL * ((p - _fadeStart) / _fadeDuration);
        }
        
        override public function getSample(numFrames:Number):Sample
        {
        	/*
        	var startPosition:Number = _source.position;    
        	var previousStartPosition:Number = startPosition - numFrames;
            var sample:Sample = _source.getSample(numFrames);
            var endPosition:Number = _source.position;
            var nextEndPosition:Number = endPosition + numFrames;
            var mp:Mod = new Mod(); // our modulation point for the spline segment
            
            if (endPosition > _fadeStart) {
            	// Calculate the four spline points
				mp.y0 = fadeGainAtPosition(startPosition); // fadeGainAtPosition(previousStartPosition);
            	mp.y1 = fadeGainAtPosition(startPosition);
            	mp.y2 = fadeGainAtPosition(endPosition);
            	mp.y3 = fadeGainAtPosition(endPosition); // fadeGainAtPosition(nextEndPosition);
            	
            	trace("Decay Fade " + mp.y0 + " " + mp.y1 + " " + mp.y2 + " " + mp.y3);
            	
            	// Run the fade
            	sample.envelope(mp, numFrames);
            }
            
            // And if not faded, any sample frames are passed unchanged.
            
            return sample;
            */
            
            var startPosition:Number = _source.position;
            var framesToFade:Number;
            var sampleStartPosition:Number;
            var sample:Sample = _source.getSample(numFrames);
            var endPosition:Number = _source.position;
            var mp:Mod = new Mod(); // our decay envelope segment
            
            if (_source.position > _fadeStart) {
            	// we need to fade some of this sample
            	var envelopeStartPosition:Number = startPosition - _fadeStart;
            	if (envelopeStartPosition < 0) {
            		// a partial fade through this buffer
            		framesToFade = envelopeStartPosition + numFrames; // the remaining frames
            		sampleStartPosition = _fadeStart - startPosition;
            		mp.y0 = mp.y1 = 0;
            		// trace("Start fade at " + startPosition);
            	} else {
            		// fade whole buffer
            		framesToFade = numFrames;
            		sampleStartPosition = 0;
            		mp.y0 = mp.y1 = fadeGainAtPosition(startPosition);
            	} 
            	mp.y2 = mp.y3 = fadeGainAtPosition(endPosition);
            	// trace("Fade from " + mp.y1 + " to " + mp.y2);
            	
            	// Run the fade
            	sample.envelope(mp, framesToFade, sampleStartPosition);
            }
            
            return sample;
            
        }

		/* The following are hacks to allow a Filter to act as 
		 an IDirectAccessSource whenever possible, if its source is one. */
		
		public function fill(toOffset:Number=-1):void {
			if (_source is IDirectAccessSource) {
				IDirectAccessSource(_source).fill(toOffset);
			}
		}
		
		public function useSample(numFrames:Number):void {
			if (_source is IDirectAccessSource) {
				IDirectAccessSource(_source).useSample(numFrames);
			}
		}
		
		public function getSamplePointer(offset:Number=0):uint {
			var pointer:uint; // sample pointer
			if (_source is IDirectAccessSource) {
				pointer = IDirectAccessSource(_source).getSamplePointer(offset);
			} else {
				return 0;
			}
			// This is kind of a hack. If we are in the fade area, return a null sample pointer
			// And then the AudioPerformer will have to do a getSample() instead, and pick up the fade region
			if (offset < _fadeStart) {
				return pointer;
			} else {
				return 0;
			}
		}

		/**
		 * Cloning the filter also clones the source
		 */
        override public function clone():IAudioSource
        {
            return new DecayFilter(_source.clone(), _fadeStart, _fadeDuration);
        }
    }
}