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


package com.noteflight.standingwave3.generators
{
    import com.noteflight.standingwave3.elements.*;
    
    import flash.media.Sound;
    
    
    public class SoundGenerator  implements IRandomAccessSource, IDirectAccessSource
    {
        /** Underlying sound for this source. */
        protected var _sound:Sound;
        
        protected var _descriptor:AudioDescriptor;
        
        /** The sample cache for the extracted sound */
        protected var _sample:Sample;
        
        protected var _extractPosition:Number;
        protected var _position:Number;

		/**
    	 * A SoundGenerator serves as a source of sound extracted from an underlying
    	 * Flash Player Sound object, usually a loaded mp3.
    	 * Has an internal cache for the extracted sound, making it essential for wavetable usage.
     	 */
        public function SoundGenerator(sound:Sound, ad:AudioDescriptor = null)
        {
        	if (!ad) {
        		ad = new AudioDescriptor(44100, 2);
        	}
        	_descriptor = ad; 
            _sound = sound;
            _sample = new Sample(ad, sound.length * 44.1)
            _extractPosition = 0;
            _position = 0;
        }

        public function get sound():Sound
        {
            return _sound;
        }
        
        public function get frameCount():Number {
        	return _sample.frameCount;
        }
        
        public function get descriptor():AudioDescriptor {
        	return _descriptor;
        }
        
        public function getSampleRange(fromOffset:Number, toOffset:Number):Sample {
        	var numFrames:Number = toOffset-fromOffset;
        	toOffset = Math.min(toOffset, frameCount);  // clip to sample length
        	fill(toOffset); // Make sure we've extracted the sound to there
        	var resultSample:Sample = new Sample(_descriptor, numFrames);
            resultSample.mixInDirectAccessSource(_sample, fromOffset, 1.0, 0, toOffset-fromOffset);
            return resultSample;
        }
        
        public function getSamplePointer(frameOffset:Number=0):uint 
        {
        	if (frameOffset > _extractPosition) {
        		// We're not giving you a pointer to sample memory we haven't filled yet
        		return null;
        	} else {
        		return _sample.getSamplePointer(frameOffset);
        	}
        }
        
        /**
         * Fill the next run of audio if necessary, but do not return it 
         * Advance our playback
         */
        public function useSample(numFrames:Number):void
        {
        	fill(_position + numFrames);
        	_position += numFrames;
        }
        
        /**
         * Instruct the sample to fill itself up to the given frame offset  
         * @param toOffset a sample frame index; if negative/omitted, reads the entire sound
         */
        public function fill(toOffset:Number = -1):void
        {
            if (toOffset < 0)
            {
            	// Fill the entire sample buffer by extracting the entire sound
                toOffset = frameCount;
            }
            if (toOffset > _extractPosition)
            {
                // We need to extract more from the sound
                var numFrames:Number = frameCount - _extractPosition;
                _sample.extractSound(_sound, _extractPosition, numFrames);
                _extractPosition += numFrames;
            }
        }
        
        /**
        * Should be destroyed when no longer needed,
        * to free the sample memory.
        */
        public function destroy():void {
        	_sample.destroy();
        	_sample = null;
        }
       
    }
}
