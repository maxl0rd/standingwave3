///////////////////////////////////////////////////////////////////////////////
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
	import com.noteflight.standingwave3.elements.*;

	/** 
	 * Creates an audio source of indefinite duration by looping another IDirectAccessSource.
 	 */
	public class LoopSource extends AbstractSource 
	{
		/** The frame to begin and end looping on.
		 * Standing Wave can *not* read loop points from samples. You must provide them.
		 * Of course, loop points should almost ALWAYS be at zero-crossings! 
		 */
		public var startFrame:Number = 0;
		public var endFrame:Number = 0;
		
		/**  Initial start point for when the source first starts */
		public var firstFrame:Number = 0; 
		
		/** Factor by which to shift the playback frequency up or down */
		public var frequencyShift:Number;
		
		/** A direct access source to serve as the source of raw sample data */
		private var _generator:IDirectAccessSource;
		
		private var _phase:Number;
		
		private static const LOOP_MAX:Number = 30;
		
		
		/** 
		 * LoopSource extends a sample indefinitely by looping a section.
		 * The source of a loop is always a SoundGenerator.
		 */
		public function LoopSource(ad:AudioDescriptor, soundGenerator:IDirectAccessSource)
		{
			super(ad, 0, 1.0);
			this._generator = soundGenerator;
			this._position = 0;
			this.frequencyShift = 1;
			this._phase = 0;
		}
		
		override public function resetPosition():void 
		{
		    _phase = 0;
			_position = 0;
		}
		
        /**
         * In a LoopSource, the frame count needs to be tweaked appropriately
         * to reflect the frequency shift.
         */
        override public function get frameCount():Number
        {
            if (endFrame)
            {
                return LOOP_MAX * descriptor.rate;
            }
            else
            {
            	var actualShift:Number = frequencyShift * ( _generator.descriptor.rate / _descriptor.rate );
                return Math.floor((_generator.frameCount - firstFrame) / actualShift);
            }
        }
        
        override public function get duration():Number
        {
            return frameCount / descriptor.rate;
        }

		override public function getSample(numFrames:Number):Sample 
		{
			var sample:Sample = new Sample(descriptor, numFrames, false);
			var tableSize:Number;
			
			if (endFrame) {
				// The wavetable size is from frame zero to loop end
				tableSize = Math.floor(endFrame);
			} else {
				// The wavetable size is the full sample
				tableSize = _generator.frameCount;
			}
			
			// The actual shift factor depends on the difference between the generator and output descriptors
			// multiplied by the requested shift. 
			var actualShift:Number = frequencyShift * ( _generator.descriptor.rate / _descriptor.rate );
			
			// The wavetable function works with a phase angle that goes from 0-1
			//  from the start to end of the table. The phaseAdd is added every frame.
			//  The phaseReset is where it loops back to if overrunns. 
			
			var phaseAdd:Number = actualShift / tableSize; 
			var phaseReset:Number;
			
			if (startFrame && endFrame) {
			 	phaseReset = startFrame / tableSize;
			} else {
				phaseReset = -1; // no loop
			} 
	           
	        if (_phase == 0 && firstFrame) {
                // a manual start point adjustment
                _phase = firstFrame / tableSize;
            }
            
			// Make sure the sound generator is filled to the max time we will need, plus a guard sample for interpolation
			_generator.fill( Math.ceil(_position / actualShift) + 1 );
			
			// Scan the wavetable forward, looping appropriately
			// The wavetable function returns the new phase (ie position in the generator)
			_phase = sample.wavetableInDirectAccessSource(_generator, tableSize, _phase, phaseAdd, phaseReset, 0, numFrames);
			_position += numFrames;  
			
			return sample;
			
		}
		
		override public function clone():IAudioSource
		{
			var rslt:LoopSource = new LoopSource(_descriptor, _generator);
			rslt.startFrame = startFrame;
			rslt.endFrame = endFrame;
			rslt.frequencyShift = frequencyShift;
			rslt.resetPosition();
			return rslt;
		}
		
	}
}