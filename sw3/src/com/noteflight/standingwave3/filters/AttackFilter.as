
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
     * AttackFilter passes the signal unchanged after fading it in.
     * Many times a fade can be used in place of an Envelope + AmpFilter
     * and will be much more efficient, since it only calculates during the fading part.
     */
    public class AttackFilter extends AbstractFilter
    {
    
        public static const MIN_SIGNAL:Number = -50; //db
        
        /** Fade time in frames */
        private var _fadeFrames:Number;
        
        /**
         * Create a new AttackFilter. 
         * @param source the underlying audio source
         * @param fadeDuration the time in seconds for the attack fade to last
         */
        public function AttackFilter(source:IAudioSource, fadeDuration:Number = .01)
        {
            super(source);
            this.fadeDuration = fadeDuration;
        }
  
        /**
        * Set fade time in seconds
        */
        public function set fadeDuration(t:Number):void 
        {
            _fadeFrames = Math.floor(t * _source.descriptor.rate);
        }     
        
        /**
        * Get Fade time in seconds
        */
        public function get fadeDuration():Number
        {
            return _fadeFrames / _source.descriptor.rate;
        }
             
        override public function get frameCount():Number
        {
            return _source.frameCount;
        } 
        
        /**
         * Returns the decibel gain amount at any position
         */
        private function fadeGainAtPosition(p:Number):Number {
            if (p > _fadeFrames) {
                return 0;
            }
            return MIN_SIGNAL * (1 - (p/_fadeFrames));
        }
        
        override public function getSample(numFrames:Number):Sample
        {
            var startPosition:Number = _source.position;
            var framesToFade:Number = 0;
            var sample:Sample = _source.getSample(numFrames);
            var endPosition:Number = _source.position;
            var mp:Mod = new Mod(); // our decay envelope segment
            
            if (startPosition < _fadeFrames) 
            {
                // we need to fade some of this sample
                mp.y0 = mp.y1 = fadeGainAtPosition(startPosition);
                if (endPosition > _fadeFrames) 
                {
                    // Partial fade. 
                    framesToFade = _fadeFrames - startPosition;
                } else {
                    // Fade entire buffer    
                    framesToFade = numFrames;
                }
                mp.y2 = mp.y3 = fadeGainAtPosition(endPosition);
                // Run the fade
                sample.envelope(mp, framesToFade, 0);
            }
            
            return sample;
            
        }

        override public function clone():IAudioSource
        {
            return new AttackFilter(_source.clone(), fadeDuration);
        }
    }
}
