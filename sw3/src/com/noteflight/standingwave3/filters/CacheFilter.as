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
 	import com.noteflight.standingwave3.elements.*
    
    /**
     * This audio filter does not transform its underlying source.  It merely caches its
     * audio data in a stored Sample object, which is expanded as needed to cover a range
     * from the first frame up to the last frame requested via a call to getSample().  This
     * is useful for performance reasons, and is also a way to turn any IAudioSource
     * into an IRandomAccessSource.
     */
    public class CacheFilter implements IAudioFilter, IRandomAccessSource, IDirectAccessSource
    {
        private var _cache:Sample;
        private var _position:Number;
        private var _source:IAudioSource;

        public function CacheFilter(source:IAudioSource = null)
        {
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
            _source = s;
            if (_source != null)
            {
                resetPosition();

                // reset our cached data if the source changes
                if (source.frameCount >= int.MAX_VALUE) {
                	throw new Error("Cache filter no longer works with infinite sources!");
                } else {
                	_cache = new Sample(source.descriptor, source.frameCount);
                }
                
                // Reset the source's position since we've cached none of it yet
                _source.resetPosition();
            }            
        }

        /**
         * Get the AudioDescriptor for this Sample.
         */
        public function get descriptor():AudioDescriptor
        {
            return source.descriptor;
        }
        
        /**
         * @inheritDoc
         */
        public function get frameCount():Number
        {
            return source.frameCount;
        }
        
        public function getSamplePointer(frameOffset:Number = 0):uint {
        	if (frameOffset > _source.position) {
        		// We're not giving you a pointer to sample memory we haven't filled yet
        		return null;
        	} else {
        		return _cache.getSamplePointer(frameOffset);
        	}
        	
        }
        
        /**
         * @inheritDoc
         */
        public function get position():Number
        {
            return _position;
        }
        
        public function resetPosition():void
        {
            _position = 0;
        }
        
        /**
         * Get the concrete audio data from this source that occurs within a given time interval.
         * The interval must lie within the bounds of the length of the underlying source.
         * 
         * @param fromOffset the inclusive start of the interval, in sample frames.
         * @param toOffset the exclusive end of the interval (that is, one past the last sample frame in the interval)
         * @return a Sample representing the data in the interval.
         */
        public function getSampleRange(fromOffset:Number, toOffset:Number):Sample
        {
            fill(toOffset);
            return _cache.getSampleRange(fromOffset, toOffset);
        }
         
        /**
         * Get the next run of audio by calling getSampleRange() based on the current cursor position. 
         */
        public function getSample(numFrames:Number):Sample
        {
            var sample:Sample = getSampleRange(_position, _position + numFrames);
            _position += numFrames;
            return sample;
        }
        
        /**
         * Fill the next run of audio if necessary, but do not return it 
         * Advance our playback
         */
        public function useSample(numFrames:Number):void
        {
        	fill(position + numFrames);
        	_position += numFrames;
        }
        
        /**
         * Instruct this cache to fill itself up to the given frame offset from its source. 
         * @param toOffset a sample frame index; if negative/omitted, reads the entire source.
         */
        public function fill(toOffset:Number = -1):void
        {
            if (toOffset < 0 || toOffset > source.frameCount) {
                toOffset = source.frameCount;
            }
            
            if (toOffset > source.position)
            {
                // An uncached run of data is being retrieved; add it to the cache by calling
                // getSample() on the source and copying that into the cache.  This advances the
                // cursor position of the source, which records how much of it has been cached
                // downstream in this CacheFilter.
                //
                var fromOffset:Number = source.position;
                var numFrames:Number = toOffset - source.position;
                
                var sample:Sample = source.getSample(numFrames);
                _cache.mixIn(sample, 1.0, fromOffset); // concats the sample to the cache
                sample.destroy();
             }
        }
        
        /**
         * A clone of a cache filter utilizes the same source and cache sample,
         * but has independent position and acts as an independent IAudioSource.
         * CacheFilters can be mixed very quickly by AudioPerformer, 
         * so caching and cloning notes that are reused is a *great* idea.
         */ 
        public function clone():IAudioSource
        {
            var c:CacheFilter = new CacheFilter();
            c._cache = _cache;
            c._source = _source;
            c.resetPosition();
            return c;
        }
        
        /**
        * If a Cache is no longer needed, it must be destroyed to free
        * up its sample memory.
        */
        public function destroy():void {
        	_cache.destroy();
        	_cache = null;
        }
    }
}
