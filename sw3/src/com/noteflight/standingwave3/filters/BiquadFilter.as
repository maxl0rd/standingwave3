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
    import com.noteflight.standingwave3.utils.FilterCalculator;
    
    /**
     * Infinite Impulse Response (IIR) linear filter based on the "Direct Form 1"
     * filter structure, incorporating four delay lines from the two previous input and
     * output values.
     *  
     * This filter can be used in three ways: as a low-pass filter that attenuates frequencies
     * higher than the <code>frequency</code> property, as a high-pass filter that attenuates frequencies lower
     * than the center, or as a band-pass filter that attenuates frequencies that lie
     * further from the center.  In all three cases the <code>resonance</code> property controls
     * the abruptness of the rolloff as a function of frequency.  The <code>type</code> property
     * determines which filter behavior is used.  
     */
    public class BiquadFilter extends AbstractFilter
    {
        private var _frequency:Number;
        private var _resonance:Number;
        private var _type:int;
        
        private var _state:Sample = null;  // A tiny 4 frame sample to hold our delay line (x1,x2,y1,y2)
        private var _coeffs:Object = null; // an object of filter coefficients for the biquad
        
        private var _calculated:Boolean = false; // true when coefficients have been calculated
        
        /** Low-pass filter type */
        public static const LOW_PASS_TYPE:int = 0;

        /** High-pass filter type */
        public static const HIGH_PASS_TYPE:int = 1;

        /** Band-pass filter type (constant peak, attenuated skirt) */
        public static const BAND_PASS_TYPE:int = 2;
        
        /**
         * Construct an instance of a BiquadFilter.  Parameters may be left as defaulted and/or changed
         * later while the filter is in operation.
         * 
         * @param source the underlying audio source
         * @param type the type of filter desired
         * @param frequency the center frequency of the filter
         * @param resonance the resonance characteristic of the filter, also known as "Q"
         */
        public function BiquadFilter(source:IAudioSource = null, type:int = LOW_PASS_TYPE, frequency:Number = 1000, resonance:Number = 1)
        {
            super(source);
            this.type = type;
            this.frequency = frequency;
            this.resonance = resonance;
            this._state = new Sample(source.descriptor, 4); 
            this._coeffs = new Object();
        }

        override public function resetPosition():void
        {
            super.resetPosition();

            // Initialize delay line state when the cursor is reset
            if (_state) {
            	_state.setSamples(0.0, 0, 4);
            }
           	
        }        
        
        /**
         * The type of the filter, which controls the shape of its frequency response.
         */
        public function get type():int
        {
            return _type;
        }
        
        public function set type(value:int):void
        {
            _type = value;
            invalidateCoefficients();
        }
        
        /**
         * The center frequency of the filter in Hz. 
         */
        public function get frequency():Number
        {
            return _frequency;
        }
        
        public function set frequency(value:Number):void
        {
            _frequency = value;
            invalidateCoefficients();
        }
        
        /**
         * The resonance of the filter, which controls the degree of attenuation in its frequency response. 
         */
        public function get resonance():Number
        {
            return _resonance;
        }
        
        public function set resonance(value:Number):void
        {
            _resonance = value;
            invalidateCoefficients();
        }
        
        /**
         * Called when a property change invalidates the derived coefficients for the filter. 
         */
        protected function invalidateCoefficients():void
        {
            _calculated = false;
        }
        
        /**
         * Called to force calculation of the derived coefficients.
         */
        protected function computeCoefficients():void
        {
            if (_calculated) {
                return;
            }
            switch (_type) {
                case LOW_PASS_TYPE:
                    _coeffs = FilterCalculator.biquadLowPass(frequency, resonance, descriptor.rate);
                    break;
                case HIGH_PASS_TYPE:
                    _coeffs = FilterCalculator.biquadHighPass(frequency, resonance, descriptor.rate);
                    break;
                case BAND_PASS_TYPE:
                    _coeffs = FilterCalculator.biquadBandPass(frequency, resonance, descriptor.rate);
                    break;
            }
            _calculated = true;
        }
        
        override public function getSample(numFrames:Number):Sample 
        {
        	var sample:Sample = _source.getSample(numFrames);
        	
        	// Make sure our filter coefficients are up to date
        	computeCoefficients();
        	
        	// Run the biquad function on the sample, passing the state buffer and our calculated filter coefficients
        	sample.biquad(_state, _coeffs);
        	
        	return sample;
        	
        }

        override public function clone():IAudioSource
        {
            return new BiquadFilter(source.clone(), type, frequency, resonance);
        }
    }
}
