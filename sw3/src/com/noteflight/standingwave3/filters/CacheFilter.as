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
     * This audio filter does not transform its underlying source.  It merely caches its
     * audio data in a stored Sample object, which is expanded as needed to cover a range
     * from the first frame up to the last frame requested via a call to getSample().  This
     * is useful for performance reasons, and is also a way to turn any IAudioSource
     * into an IRandomAccessSource.
     * Because allocating the sample memory can be expensive, you can set a max size for a cache
     * and allow it to resize or not.
     */
    public class CacheFilter implements IAudioFilter, IRandomAccessSource, IDirectAccessSource
    {
    	// This is the maximum amount of data a cache will hold
    	// The cache will not increase in size beyond this number of frames
    	
    	public static var MAX_CACHE:Number = 65536; // 64k frames ~= 1.5 sec
    	public static var INITIAL_SIZE:Number = 65536;
    	
    	/** The maximum number of frames the cache will ever cache or grow to */
    	public var maxFrameCount:Number = MAX_CACHE;
    	
    	/** The initial number of frames the cache sample will start at */
    	public var initialFrameCount:Number = INITIAL_SIZE;
    	
    	/** A boolean representing whether a cache is allowed to grow or not.
    	 * Reallocating sample memory during playback can cause major problems
    	 * so be careful with this. Defaults to false. */
    	public var resizable:Boolean = false; 
    	
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
                if (_cache) {
                	_cache.destroy();
                }
                if (_source.frameCount >= maxFrameCount) {
                	// An infinite or very long source needs to initialize a cache, and then realloc as it grows.
                	_cache = new Sample(_source.descriptor, initialFrameCount, true);
                } else {
                	// We know how long the source is, and it's small, so we'll make a cache sample exactly the right size
                	_cache = new Sample(_source.descriptor, _source.frameCount, true);
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
            return Math.min(source.frameCount, _cache.frameCount);
        }
        
        public function getSamplePointer(frameOffset:Number = 0):uint 
        {
        	if (frameOffset > _source.position) {
        		// We're not giving you a pointer to sample memory we haven't filled yet!
        		// trace("No pointer, source position exceeded");
        		return 0;
        	} else if (frameOffset > _cache.frameCount) {
        		// We cannot give you a pointer to cache that doesn't exist! Too far out
        		// trace("No pointer, cache size exceeded");
        		return 0;
        	}
        	return _cache.getSamplePointer(frameOffset);
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
            if (toOffset <= _cache.frameCount) {
            	// Return a slice from the cache
           		return _cache.getSampleRange(fromOffset, toOffset);
            } else {
            	// We're outside the cache range. Throw an error
            	throw new Error("CacheFilter.getSampleRange() called beyond cache bounds.");
            }
            return null;
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
            
            if (toOffset > _cache.frameCount) { 
            	if (!resizable) {
            		throw new Error("Fill called beyond the bounds of an unresizable CacheFilter");
            		return;
            	}
            	// We need to grow the cache sample to accommodate this source	
            	// New size is the lesser of twice the existing size, or the mix size
            	var newSize:Number = Math.min(_cache.frameCount*2, maxFrameCount);
            	
            	// var oldTime:Number = getTimer();  
            	_cache.realloc(newSize);
            	// var delta:Number = getTimer() - oldTime;
            	// trace("Reallocated cache sample to " + _cache.frameCount + " in " + delta + " ms.");
            	
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
