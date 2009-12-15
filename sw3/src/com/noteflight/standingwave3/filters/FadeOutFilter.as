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
    
    /**
     * FadeOutFilter passes the signal unchanged until the fade is reached,
     * and then fades it out with the supplied envelope.
     * Many times a fade can be used in place of an Envelope + AmpFilter
     * and will be much more efficient, since it only calculates during the fading part.
     */
    public class FadeOutFilter extends AbstractFilter
    {
    
        /** Our envelope generator. If this is not set, a suitable envelope will be created. */
        private var _envelope:IDirectAccessSource;
        
        /** Time to start fading, in frames. */
 		private var _fadeStart:Number = int.MAX_VALUE;
 		
 		/** Fade time in frames */
 		private var _fadeDuration:Number;
 		
        /**
         * Create a new FadeInFilter. 
         * @param source the underlying audio source
         * @param envelope the envelope generator
         * @param the time in seconds to begin fade out. defaults to ending the source at end of fade.
         */
        public function FadeOutFilter(source:IAudioSource, envelope:IDirectAccessSource, fadeStart:Number = -1)
        {
            super(source);
            this._envelope = envelope;
            if (!AudioDescriptor.compare(source.descriptor, envelope.descriptor)) {
            	throw new Error ("Incompatible source and envelope descriptors.");
            }
            if (fadeStart < 0) {
            	this._fadeStart = source.frameCount - envelope.frameCount;
            } else {
            	this._fadeStart = fadeStart * source.descriptor.rate;
            }
            this._fadeDuration = envelope.frameCount;
        }
        
        /**
        * Set fade start time in seconds
        */
        public function set fadeStart(t:Number):void 
        {
        	_fadeStart = t * _source.descriptor.rate;
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
        
        override public function getSample(numFrames:Number):Sample
        {
        	var startPosition:Number = _source.position;
            var framesToFade:Number;
            var sampleStartPosition:Number;
            
            var sample:Sample = _source.getSample(numFrames);
            
            if (_source.position > _fadeStart) {
            	// we need to fade some of this sample
            	var envelopeStartPosition:Number = startPosition - _fadeStart;
            	if (envelopeStartPosition < 0) {
            		// a partial fade through this buffer
            		framesToFade = envelopeStartPosition + numFrames; // the remaining frames
            		envelopeStartPosition = 0;
            		sampleStartPosition = _fadeStart - startPosition;
            	} else {
            		// fade whole buffer
            		framesToFade = numFrames;
            		sampleStartPosition = 0;
            	}
            	
            	// Fill our envelope to the needed point
            	_envelope.fill(envelopeStartPosition + framesToFade); 
            	
            	// Run the fade
            	sample.multiplyInDirectAccessSource(_envelope, envelopeStartPosition, 1.0, sampleStartPosition, framesToFade);
            }
            
            // And if not faded, any sample frames are passed unchanged.
            
            return sample;
        }

		/**
		 * Cloning the filter also clones the source,
		 *   but points to the same envelope generator.
		 */
        override public function clone():IAudioSource
        {
            return new FadeOutFilter(_source.clone(), _envelope);
        }
    }
}
