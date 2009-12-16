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
    import com.noteflight.standingwave3.utils.AudioUtils;
    
    /**
     * AmpFilter multiplies the input with any generator.
     * Use with an EnvelopeGenerator to make an ADSR filter,
     * or with another audio rate generator to make a ring modulator.
     */
    public class AmpFilter extends AbstractFilter
    {
    
        /** Our envelope generator */
        private var _envelope:IDirectAccessSource;
        
        /** An additional fixed gain change applied, in db **/
        public var gain:Number;
        
        /**
         * Create a new AmpFilter. 
         * @param source the underlying audio source
         * @param envelope the envelope generator
         */
        public function AmpFilter(source:IAudioSource, envelope:IDirectAccessSource)
        {
            super(source);
            this._envelope = envelope;
            this.gain = 0.0;
            if (!AudioDescriptor.compare(source.descriptor, envelope.descriptor)) {
            	throw new Error ("Incompatible source and envelope descriptors.");
            }
        }
        
        override public function get frameCount():Number {
        	// Return the shorter of the source or the envelope
        	return Math.floor( Math.min(_source.frameCount, _envelope.frameCount) );
        }
        
        override public function getSample(numFrames:Number):Sample
        {
        	var startPosition:Number = _source.position;
        	
        	// Pull our sample from the source downstream
            var sample:Sample = _source.getSample(numFrames);
            
            // Make sure our envelope has generated its shape up to this position
            // If it has to gen a lot of samples, this could be slow
            // But if reusing an envelope, this will be fast
            _envelope.fill(_source.position); 
            
            // Shape our sample with the envelope signal
            var fgain:Number = AudioUtils.decibelsToFactor(gain);
            sample.multiplyInDirectAccessSource(_envelope, startPosition, fgain, 0.0, numFrames);
            
            return sample;
        }

		/**
		 * Cloning the AmpFilter also clones the source,
		 *   but points to the same envelope generator.
		 */
        override public function clone():IAudioSource
        {
            return new AmpFilter(_source.clone(), _envelope);
        }
    }
}
