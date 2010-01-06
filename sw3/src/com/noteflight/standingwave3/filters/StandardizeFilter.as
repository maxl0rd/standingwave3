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
     * StandardizeFilter converts a source of any audio descriptor to a standard
     * stereo 44.1k audio source, suitable for output to AudioPlayer.
     */
    public class StandardizeFilter extends AbstractFilter
    {
    	// Overrides the source descriptor
    	private var _descriptor:AudioDescriptor;
         
        public function StandardizeFilter(source:IAudioSource)
        {
            super(source);
            this._descriptor = new AudioDescriptor(AudioDescriptor.RATE_44100, AudioDescriptor.CHANNELS_STEREO);
        }
         
        override public function get descriptor():AudioDescriptor
        {
        	return _descriptor;
        } 
                
        override public function get frameCount():Number
        {
        	if (_source.descriptor.rate == AudioDescriptor.RATE_44100) {
        		return _source.frameCount;
        	} else if (_source.descriptor.rate == AudioDescriptor.RATE_22050) {
        		return _source.frameCount * 2;
        	}
        	return 0;
        }        
        
        override public function get position():Number
        {
        	if (_source.descriptor.rate == AudioDescriptor.RATE_44100) {
        		return _source.position;
        	} else if (_source.descriptor.rate == AudioDescriptor.RATE_22050) {
        		return _source.position * 2;
        	}
        	return 0;
        }
        
        override public function getSample(numFrames:Number):Sample
        {
        	var sample:Sample;
        	if (source.descriptor.rate == AudioDescriptor.RATE_44100) {
        		sample = _source.getSample(numFrames);
        	} else if (source.descriptor.rate == AudioDescriptor.RATE_22050) {
        		sample = _source.getSample(Math.floor(numFrames/2));
        	}
           	sample.standardize();
            return sample;
        }

        override public function clone():IAudioSource
        {
            return new StandardizeFilter(source.clone());
        }
    }
}
