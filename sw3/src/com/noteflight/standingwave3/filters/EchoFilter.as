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
     * An EchoFilter implements a simple recirculating delay line in which the input is blended with
     * a time-delayed copy of itself.  
     */
    public class EchoFilter extends AbstractFilter
    {
        private var _bufferLength:Number;
        private var _wet:Number;
        private var _decay:Number;
        private var _period:Number;
        
        /** Our ring buffer to hold the echo */
        private var _ring:Sample;
        
        /**
         * Create a new EchoFilter.  Parameters may be changed while the filter is operating.
         *  
         * @param source the underlying IAudioSource
         * @param period the time period of the echo
         * @param wet the fraction of the output which is represented by the delayed signal
         * @param decay the fraction of the delayed signal which is fed back into the delay line
         * 
         */
        public function EchoFilter(source:IAudioSource = null, period:Number = 0, wet:Number = 0.5, decay:Number = 0.5)
        {
            super(source);
            this.period = period;
            this.wet = wet;
            this.decay = decay;
        }
        
        /**
         * @inheritDoc
         */
        override public function resetPosition():void
        {
            super.resetPosition();
            initializeState();
        }        
        
        /**
         * The fraction of the output which is represented by the delayed signal.
         */
        public function get wet():Number
        {
            return _wet;
        }
        
        public function set wet(value:Number):void
        {
            _wet = value;
        }
        
        /**
         * The fraction of the delayed signal which is fed back into the delay line.
         */
        public function get decay():Number
        {
            return _decay;
        }
        
        public function set decay(value:Number):void
        {
            _decay = value;
        }
        
        /**
         * The time period of the echo in seconds.
         */
        public function get period():Number
        {
            return _period;
        }
        
        public function set period(value:Number):void
        {
            _period = value;
            initializeState();
        }
        
        protected function initializeState():void
        {
        	if (_ring) {
        		_ring.destroy();
        	}
            _ring = null;
        }
        
        override public function getSample(numFrames:Number):Sample 
        {
        	// The delay line is just a Sample whose channels are used as a ring buffer.
            if (_ring == null)
            {
                _bufferLength = Math.floor(_period * _source.descriptor.rate );
                _ring = new Sample(descriptor, _bufferLength);
            }
            
            var sample:Sample = _source.getSample(numFrames); 
            sample.delay(_ring, 1.0, _wet, _decay);  
            
            return sample;   
        }
        
        override public function clone():IAudioSource
        {
            return new EchoFilter(source.clone(), period, wet, decay);
        }
        
        /**
        * Destroy EchoFilters to free the sample memory in the ring buffer
        */
        public function destroy():void 
        {
        	_ring.destroy();	
        }
    }
}
