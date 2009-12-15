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
     * FadeInFilter first passes the source through an attack envelope
     * and then passes it unchanged after the fade.
     */
    public class FadeInFilter extends AbstractFilter
    {
    
        /** Our envelope generator. The fade in time is the length of this envelope. */
        private var _envelope:IDirectAccessSource;
        
        /** Fade time in seconds */
 		private var _fadeDuration:Number = 0.1;
 		
        /**
         * Create a new FadeInFilter. 
         * @param source the underlying audio source
         * @param envelope the envelope generator
         */
        public function FadeInFilter(source:IAudioSource, envelope:IDirectAccessSource)
        {
            super(source);
            this._envelope = envelope;
            this._fadeDuration = envelope.frameCount;
            if (!AudioDescriptor.compare(source.descriptor, envelope.descriptor)) {
            	throw new Error ("Incompatible source and envelope descriptors.");
            }
        }
        
        public function get fadeDuration():Number
        {
        	return _fadeDuration / _source.descriptor.rate;
        }
        
        override public function getSample(numFrames:Number):Sample
        {
        	var startPosition:Number = _source.position;
        	var framesToMake:Number = 0;
            
            var sample:Sample = _source.getSample(numFrames);
            
            if (startPosition < _fadeDuration) {
            	// we need to fade
            	framesToMake = _fadeDuration - startPosition;
            	framesToMake = Math.min(numFrames, framesToMake); // clamp to numFrames
            	_envelope.fill(_source.position); 
            	sample.multiplyInDirectAccessSource(_envelope, startPosition, 1.0, 0.0, framesToMake);
            }
            
            // And if not, any sample frames are passed unchanged.
            
            return sample;
        }

		/**
		 * Cloning the filter also clones the source,
		 *   but points to the same envelope generator.
		 */
        override public function clone():IAudioSource
        {
            return new FadeInFilter(_source.clone(), _envelope);
        }
    }
}
