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


package com.noteflight.standingwave3.sources
{
    import com.noteflight.standingwave3.elements.*;
    
    import flash.media.Sound;
    
    /**
     * A SoundSource serves as a source of stereo 44.1k sound extracted from an underlying
     * Flash Player Sound object. To extract a sample at a lower resolution, or use the
     * extracted sound as a wavetable, you should probably use SoundGenerator instead.
     */
    public class SoundSource extends AbstractSource implements IRandomAccessSource
    {
        /** Underlying sound for this source. */
        protected var _sound:Sound;

        public function SoundSource(sound:Sound, ad:AudioDescriptor = null)
        {
        	if (!ad) {
        		ad = new AudioDescriptor(44100, 2);
        	}
            super(ad, (sound.length / 1000.0), 1.0);
            _sound = sound;
            _position = 0;
        }

        public function get sound():Sound
        {
            return _sound;
        }
        
        override public function get frameCount():Number { 
        	return _sound.length * 44.1;
        }
        
        public function getSampleRange(fromOffset:Number, toOffset:Number):Sample {
        	var numFrames:Number = toOffset-fromOffset;
        	toOffset = Math.min(toOffset, frameCount);  // clip to sample length
        	var resultSample:Sample = new Sample(descriptor, numFrames); 
            resultSample.extractSound(_sound, fromOffset, numFrames );
            return resultSample;
        }
        
        override public function getSample(numFrames:Number):Sample
        {
        	var fromOffset:Number = _position;
        	var toOffset:Number = _position + numFrames;
        	_position += numFrames;
            return getSampleRange(fromOffset, toOffset);
        }
        
        
        /**
         * A clone utilizes the same source.
         */ 
        override public function clone():IAudioSource
        {
            var ss:SoundSource = new SoundSource(_sound, _descriptor);
            return ss as IAudioSource;
        }
        
        
       
    }
}
