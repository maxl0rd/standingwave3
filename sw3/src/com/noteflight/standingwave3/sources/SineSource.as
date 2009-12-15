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


package com.noteflight.standingwave3.sources
{
    import __AS3__.vec.Vector;
    
    import com.noteflight.standingwave3.elements.*;
    
    /**
     * A SineSource provides a source whose signal in all channels is a pure sine wave of a given frequency. 
     */
    public class SineSource extends AbstractSource
    {
        protected var _frequency:Number = 0;
        protected var _phase:Number = 0;

		/** Lookup tables for faster sine generation. These are static so don't destroy them. :) */
		protected static var _sineTable1:Sample; // mono table
		protected static var _sineTable2:Sample; // stereo table

        public function SineSource(descriptor:AudioDescriptor, duration:Number, frequency:Number, amplitude:Number = 0.5)
        {
            super(descriptor, duration, amplitude);
            this.frequency = frequency;
        }

        /**
         * The frequency of this sine wave. 
         */
        public function get frequency():Number
        {
            return _frequency;
        }
        
        public function set frequency(value:Number):void
        {
            _frequency = value;
        }
        
        override public function resetPosition():void
        {
            super.resetPosition();
            _phase = 0;
        }
        
        /**
        * Create a lookup table of 1 cycle of a sine.
        * This is scanned by a phasor going from 0-1 over one period.
        * Table is 0-1023 plus 1 extra sample to avoid interplolation overrun.
        * Using the awave wavetable methods is about an order of magnitude faster
        * than calling Math.sin() for every sample.
        */
        protected static function createSineTables():void 
        {
			var data:Vector.<Number> = new Vector.<Number>(1025, true);
			data[0] = 0.0;
			var rads:Number;
			var pi2:Number = 2 * Math.PI;
			for (var x:int=1; x<1024; x++) {
				rads = (x/1023) * pi2;
				data[x] = Math.sin(rads);
			}
			data[1024] = 0.0;
			_sineTable1 = new Sample(new AudioDescriptor(44100, 1), 1025);
			_sineTable2 = new Sample(new AudioDescriptor(44100, 2), 1025);
			_sineTable1.commitSlice(data, 0, 0);
			_sineTable2.commitSlice(data, 0, 0); 
			_sineTable2.commitSlice(data, 1, 0); 
		}
        
        override public function getSample(numFrames:Number):Sample
        {
        	if (!_sineTable1 || !_sineTable2) {
            	createSineTables();
            }
            var table:Sample;
            // Use the mono or stereo table, depending on num of channels.
            if (descriptor.channels == 1) { 
            	table = _sineTable1;
            } else { 
            	table = _sineTable2;
            }
            var sample:Sample = new Sample(descriptor, numFrames);
            var phaseAddPerFrame:Number = _frequency / _descriptor.rate;
            // create a sine from _position for numFrames
            sample.wavetableInDirectAccessSource(table, 1024, _phase, phaseAddPerFrame, 0, 0, numFrames);
             // we have to track the change in phase angle over this sample chunk
            // to avoid discontinuities between getSample() calls...
            _phase += phaseAddPerFrame * numFrames;
            _phase = _phase - Math.floor(_phase); // normalize to 0-1
            _position += numFrames; // advance position
            return sample; 
        }
        
        override public function clone():IAudioSource
        {
            return new SineSource(descriptor, duration, frequency, amplitude);
        }
        
    }
}
