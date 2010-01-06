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


package com.noteflight.standingwave3.utils
{
    import com.noteflight.standingwave3.elements.*;
    import com.noteflight.standingwave3.filters.CacheFilter;
    
    public class AudioUtils
    {
        /** The base 10 exponent multiplier for decibels. */
        public static const DECIBELS_PER_DECADE:Number = 20.0;
        
        /** The smallest audible signal strength. */
        public static const MINIMUM_SIGNAL:Number = 1.0 / 65536.0;
        
        /** The smallest parametric control signal. */
        public static const MINIMUM_CONTROL:Number = 1.0 / 128.0;
        
        /** The decibel gain at which a sound becomes inaudible at 16 bit sample size. */
        public static const ZERO_GAIN_DECIBELS:Number = factorToDecibels(MINIMUM_SIGNAL);
        
        /** The natural log of the gain of an inaudible sound. */
        public static const MINIMUM_CONTROL_LN:Number = Math.log(MINIMUM_CONTROL);
        
        /**
         * Convert a gain in decibels to a pure proportional factor. 
         */
        public static function decibelsToFactor(dB:Number):Number
        {
            return Math.exp(dB * Math.LN10 / DECIBELS_PER_DECADE);
        }
        
        /**
         * Convert a pure proportional factor to a gain in decibels. 
         */
        public static function factorToDecibels(gain:Number):Number
        {
            return Math.log(gain) * Math.LOG10E * DECIBELS_PER_DECADE;
        }
        
        /**
        * Convert a pan position into left and right amplitude factors.
        * @param pan the pan position from left -1 to center 0 to right -1
        * @param panLaw the db down at center, defaults to -3db
        * @returns an object with left and right values set to amp factors
        */
        public static function panToFactors(pan:Number, panLaw:Number=-3):Object 
        {
        	var rslt:Object = new Object();
        	var plf:Number = AudioUtils.decibelsToFactor(panLaw);
			if (pan < -1) { pan = -1; }
			if (pan > 1) { pan = 1; }
			if (pan > 0) {
				rslt.left = plf * (1 - pan);
				rslt.right = plf * (1-pan) + pan;
			} else {
				rslt.left = plf * (1 + pan) - pan;
				rslt.right = plf * (1+pan);
			}
			return rslt;
        }
        
        /**
         * Compute a normalized concave unipolar control signal going from +1 to 0
         * as the input goes from 0 to +1; 
         */
        public static function concaveUnipolar(parameter:Number):Number
        {
            return Math.log(Math.max(MINIMUM_CONTROL, parameter)) / MINIMUM_CONTROL_LN;
        }
        
        /**
         * Convert a "midi note number" to a frequency.
         * By convention A4 = 69 = 440 Hz
         * but you can provide a reference to override the tuning reference.
         */ 
        public static function noteNumberToFrequency(noteNum:Number, refFreq:Number = 440):Number 
        {
        	return refFreq * Math.pow(2, (noteNum-69)/12 );
        }
        
        /** 
         * Convert a frequency to midi note number
         */
        public static function frequencyToNoteNumber(frequency:Number, refFreq:Number = 440):Number 
        {
        	return 69 + 12 * Math.log(frequency / refFreq);
        }
        
        /**
         * Obtain an IRandomAccessSource for a given audio source by caching it if necessary. 
         */
        public static function toRandomAccessSource(source:IAudioSource):IRandomAccessSource
        {
            return (source is IRandomAccessSource) ? IRandomAccessSource(source) : new CacheFilter(source);
        }
    }
}