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
    * 
    * TODO! FIXME! ONE POLE DOESN'T WORK YET!
    * 
    * 
    * 
     * Infinite Impulse Response (IIR) linear filter implementation of a 1 pole filter.
     *  
     * This filter can be used in two ways: as a low-pass filter that attenuates frequencies
     * higher than the <code>frequency</code> property, as a high-pass filter that attenuates frequencies lower
     * than the center. The <code>type</code> property determines which filter behavior is used.  
     */
    public class OnePoleFilter extends AbstractFilter
    {
        private var _frequency:Number;
        private var _type:int;
        
        private var _state:Object = null;  // A tiny object to hold our delay line filter state
        private var _coeffs:Object = null; // an object of filter coefficients from FilterCalculator
        
        private var _calculated:Boolean = false; // true when coefficients have been calculated
        
        /** Low-pass filter type */
        public static const LOW_PASS_TYPE:int = 0;

        /** High-pass filter type */
        public static const HIGH_PASS_TYPE:int = 1;
        
        /**
         * Construct an instance of a OnePoleFilter.  Parameters may be left as defaulted and/or changed
         * later while the filter is in operation.
         * 
         * @param source the underlying audio source
         * @param type the type of filter desired
         * @param frequency the center frequency of the filter
         */
        public function OnePoleFilter(source:IAudioSource = null, type:int = LOW_PASS_TYPE, frequency:Number = 1000)
        {
            super(source);
            this.type = type;
            this.frequency = frequency;
            this._state = { lx:0, ly:0, rx:0, ry:0 };
            this._coeffs = {};
        }

        override public function resetPosition():void
        {
            super.resetPosition();

            // Initialize delay line state when the cursor is reset
            if (_state) {
            	_state = { lx:0, ly:0, rx:0, ry:0 };
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
                    _coeffs = FilterCalculator.onePoleLowPass(frequency, descriptor.rate);
                    break;
                case HIGH_PASS_TYPE:
                    _coeffs = FilterCalculator.onePoleHighPass(frequency, descriptor.rate);
                    break;
            }
            _calculated = true;
        }
        
        override public function getSample(numFrames:Number):Sample 
        {
        	var sample:Sample = _source.getSample(numFrames);
        	
        	// Make sure our filter coefficients are up to date
        	computeCoefficients();
        	
        	// Run the filter function on the sample, passing the state and our calculated filter coefficients
        	sample.onePole(_state, _coeffs);
        	
        	return sample;
        	
        }

        override public function clone():IAudioSource
        {
            return new OnePoleFilter(source.clone(), type, frequency);
        }
    }
}
