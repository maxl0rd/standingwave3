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
    import com.noteflight.standingwave3.modulation.*;
    import com.noteflight.standingwave3.filters.AbstractFilter;
    
    /**
     * FadeInFilter passes the signal unchanged after fading it in.
     * Many times a fade can be used in place of an Envelope + AmpFilter
     * and will be much more efficient, since it only calculates during the fading part.
     */
    public class FadeInFilter extends AbstractFilter
    {
    
        public static const MIN_SIGNAL:Number = -60; //db
 		
 		/** Fade time in frames */
 		private var _fadeDuration:Number;
 		
        /**
         * Create a new FadeInFilter. 
         * @param source the underlying audio source
         * @param fadeDuration the time in seconds for the fade to last
         */
        public function FadeInFilter(source:IAudioSource, fadeDuration:Number = .01)
        {
            super(source);
            this.fadeDuration = fadeDuration;
        }
  
        /**
        * Set fade time in seconds
        */
        public function set fadeDuration(t:Number):void 
        {
        	_fadeDuration = t * _source.descriptor.rate;
        }     
        
        /**
        * Get Fade time in seconds
        */
        public function get fadeDuration():Number
        {
        	return _fadeDuration / _source.descriptor.rate;
        }
		     
        override public function get frameCount():Number
		{
			return _source.frameCount;
		} 
        
        /**
         * Returns the decibel gain amount at any position
         */
        private function fadeGainAtPosition(p:Number):Number {
        	if (p > _fadeDuration) {
        		return 0;
        	}
        	return MIN_SIGNAL * (1 - (p/_fadeDuration));
        }
        
        override public function getSample(numFrames:Number):Sample
        {
        	var startPosition:Number = _source.position;    
        	var previousStartPosition:Number = startPosition - numFrames;
            var sample:Sample = _source.getSample(numFrames);
            var endPosition:Number = _source.position;
            var nextEndPosition:Number = endPosition + numFrames;
            var mp:Mod = new Mod(); // our modulation point for the spline segment
            
            if (startPosition < _fadeDuration) {
            	// Calculate the four spline points
				mp.y0 = fadeGainAtPosition(previousStartPosition);
            	mp.y1 = fadeGainAtPosition(startPosition);
            	mp.y2 = fadeGainAtPosition(endPosition);
            	mp.y3 = fadeGainAtPosition(nextEndPosition);
            	
            	// Run the fade
            	sample.envelope(mp, numFrames);
            }
            
            // And if not faded, any sample frames are passed unchanged.
            
            return sample;
        }

        override public function clone():IAudioSource
        {
            return new FadeInFilter(_source.clone(), _fadeDuration);
        }
    }
}
