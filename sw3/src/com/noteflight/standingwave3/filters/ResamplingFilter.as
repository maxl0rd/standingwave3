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
     * This filter implementation resamples an input source by interpolating its samples
     * using a sampling frequency that is some factor higher or lower than its actual
     * sample rate.  The result is a signal whose speed and pitch are both shifted relative
     * to the original.
     */
    public class ResamplingFilter implements IAudioSource, IRandomAccessSource
    {
        /**
         * The factor by which the source's frequency is to be resampled.  Higher factors
         * shift frequency upwards.
         */
         
        /** Resample factor */
        public var factor:Number;
         		
		/** A cache for the underlying source */
        private var _sourceCache:IRandomAccessSource;

        /** The position of this filter */
        private var _position:Number;
        
        /** The underlying source */
        private var _source:IAudioSource;

        /**
         * Create a new ResamplingFilter to adjust the frequency of its input. 
         * 
         * @param source the input source for this filter
         * @param factor the factor by which the input frequency should be multiplied.
         */        
        public function ResamplingFilter(source:IAudioSource = null, factor:Number = 1)
        {
            this.factor = factor;
            this.source = source;
        }
        
        /**
         * The underlying audio source for this filter. 
         */
        public function get source():IAudioSource
        {
            return _source;
        }
        
        public function set source(s:IAudioSource):void
        {
            if (s != null)
            {
                _source = s;
                _sourceCache = AudioUtils.toRandomAccessSource(s);
                resetPosition();
            }
            else
            {
                _source = null;
                _sourceCache = null;
            }            
        }

        /**
         * Get the AudioDescriptor for this Sample.
         */
        public function get descriptor():AudioDescriptor
        {
            return _source.descriptor;
        }
        
        /**
         * Get the number of sample frames in this AudioSource.
         */
        public function get frameCount():Number
        {
            return Math.floor((_source.frameCount - 1) / factor) + 1;
        }
        
        public function get position():Number
        {
            return _position;
        }
        
        public function resetPosition():void
        {
            _position = 0;
        }
        
        public function getSampleRange(fromOffset:Number, toOffset:Number):Sample
        {	
            var srcStart:Number;
            var srcEnd:Number;
            var numFrames:Number = toOffset - fromOffset;
            
            if (factor == 1) {
            	// optimize the trivial case
            	return _sourceCache.getSampleRange(fromOffset, toOffset);
            } else {
            	var outputSample:Sample = new Sample(descriptor, numFrames);
            	// Optimize the resampling of IDirectAccessSource vs. IAudioSource
            	if (_sourceCache is IDirectAccessSource) {
            		// this can take a fractional srcStart, so let's calculate exact start point
            		srcStart = fromOffset * factor;
           			srcEnd = Math.ceil((fromOffset+numFrames-1) * factor) + 1;
           			IDirectAccessSource(_sourceCache).fill(srcEnd);
            		outputSample.resampleInDirectAccessSource(IDirectAccessSource(_sourceCache), srcStart, factor, 0, numFrames); // resample in a slice of memory
            	} else {
            		// we need integer start and end points to getSample()
            		srcStart = Math.floor(fromOffset * factor);
            		srcEnd = Math.ceil((fromOffset+numFrames-1) * factor) + 1;
            		var sourceSample:Sample = IRandomAccessSource(_sourceCache).getSampleRange(srcStart, srcEnd); // get a chunk
            		outputSample.resampleIn(sourceSample, factor); // and resample it all in
            		sourceSample.destroy(); // clean up
            	}
            	return outputSample;
            }
        }
        
        public function getSample(numFrames:Number):Sample 
        {
        	var sample:Sample = getSampleRange(_position, _position + numFrames);
        	_position += numFrames;
        	return sample;
        }   
            
        public function clone():IAudioSource
        {
            return new ResamplingFilter(_source.clone(), factor);
        }
    }
}
