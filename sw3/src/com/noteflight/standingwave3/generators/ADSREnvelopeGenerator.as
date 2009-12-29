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

package com.noteflight.standingwave3.generators
{
	import __AS3__.vec.Vector;
	
	import com.noteflight.standingwave3.elements.*;
	import com.noteflight.standingwave3.utils.AudioUtils;
	
	public class ADSREnvelopeGenerator extends AbstractGenerator
	{
		
		private var _attack:Number; // attack time in seconds
		private var _decay:Number; // decay time in seconds
		private var _hold:Number; // hold time in seconds
		private var _sustain:Number; // sustain level as factor
		private var _release:Number; // release time in seconds
		
		private var _attackTable:Sample;
		private var _decayTable:Sample;
		private var _releaseTable:Sample;
		
		/**
		 * Envelope settings cannot be changed after creation.
		 * It's better to just destroy one and build a new one.
		 */
		public function get attack():Number { return _attack; }
		public function get decay():Number { return _decay; }
		public function get hold():Number { return _hold; }
		public function get sustain():Number { return _sustain; }
		public function get release():Number { return _release; }
		
		/**
		 * An EnvelopeGenerator generates a sample table that describes the
		 * envelope shape for a note. It can be passed to an AmpFilter to
		 * shape any other sound. Works faster than EnvelopeFilter().
		 * One EnvelopeGenerator can be reused across any voices that have
		 * the same envelope shape, and does not need to be cloned.
		 */
		public function ADSREnvelopeGenerator(descriptor:AudioDescriptor, a:Number=0.05, d:Number=0.05, h:Number=1.0, s:Number=1.0, r:Number=0.1 )
		{
			super(descriptor, a+d+h+r);
			this._attack = a * descriptor.rate;
			this._decay = d  * descriptor.rate;
			this._hold = h  * descriptor.rate;
			this._sustain = s;
			this._release = r * descriptor.rate;
		}
		
		/**
		 * This envelope works by generating three 1025 sample tables,
		 * each for one of the rising/falling segments of the envelope.
		 * These envelopes are normalized from 0 to 1;
		 * The fast wavetable functions in the awave sample lib are used
		 * to stretch the envelope to its full size.
		 * They are 1024 sample envelopes, with 1 guard sample for interpolation.
		 */
		
		protected function generateAttackTable():void 
		{
			// The attack table goes from 0 signal to 1
			_attackTable = new Sample(descriptor, 1025);
			generateExponentialTable(_attackTable, AudioUtils.MINIMUM_SIGNAL, 1.0);
		}
		
		protected function generateDecayTable():void 
		{
			// Decay table from 1 to sustain value
			_decayTable = new Sample(descriptor, 1025);
			generateExponentialTable(_decayTable, 1.0, _sustain);
		}
		
		protected function generateReleaseTable():void 
		{
			// Release table from sustain value to 0 signal
			_releaseTable = new Sample(descriptor, 1025);
			generateExponentialTable(_releaseTable, _sustain, AudioUtils.MINIMUM_SIGNAL);
		}
		
		public function generateEntireEnvelope():void 
		{
			// This is the simple form to make an entire envelope at once
			// Not usually used, but it's easier to read than the complex form below...
			
			generateAttackTable();
			generateDecayTable();
			generateReleaseTable();
			_sample.resampleInDirectAccessSource(_attackTable, 0, 1024/_attack, 0, _attack);
			_sample.resampleInDirectAccessSource(_decayTable, 0, 1024/_decay, _attack, _decay);
			_sample.setSamples(_sustain, _attack+_decay, _hold);
			_sample.resampleInDirectAccessSource(_releaseTable, 0, 1024/_release, _attack+_decay+_hold, _release);
			
		}
		
		protected function generateEnvelope(genPosition:Number, numFrames:Number):void 
		{
			// This is the complex form to make a little bit of an envelope at a time
			
			var lengthOfPhase:Number = 0.0;
			var framesLeftToMake:Number = numFrames;
			var phaseOffset:Number = 0.0; 
			
			if (genPosition < _attack) {
				if (!_attackTable) {
					generateAttackTable();
				}
				lengthOfPhase = _attack-genPosition;
				lengthOfPhase = Math.min(lengthOfPhase, framesLeftToMake);
				phaseOffset = Math.floor( (genPosition/_attack) * 1024);
				_sample.resampleInDirectAccessSource(_attackTable, phaseOffset, 1024/_attack, genPosition, lengthOfPhase);
				genPosition += lengthOfPhase;
				framesLeftToMake -= lengthOfPhase;
			}
			
			if (genPosition < _attack+_decay && framesLeftToMake > 0) {
				if (!_decayTable) {
					generateDecayTable();
				}
				lengthOfPhase = _attack + _decay - genPosition;
				lengthOfPhase = Math.min(lengthOfPhase, framesLeftToMake);
				phaseOffset = Math.floor( ((genPosition-_attack) / _decay)*1024 );
				_sample.resampleInDirectAccessSource(_decayTable, phaseOffset, 1024/_decay, genPosition, lengthOfPhase);
				genPosition += lengthOfPhase;
				framesLeftToMake -= lengthOfPhase;
			}
			
			if (genPosition < _attack+_decay+_hold && framesLeftToMake > 0) {
				lengthOfPhase = _attack + _decay + _hold - genPosition;
				lengthOfPhase = Math.min(lengthOfPhase, framesLeftToMake);
				_sample.setSamples(_sustain, genPosition, lengthOfPhase);
				genPosition += lengthOfPhase;
				framesLeftToMake -= lengthOfPhase;
			}
			
			if (genPosition < _attack+_decay+_hold+_release && framesLeftToMake > 0) {
			 	if (!_releaseTable) {
			 		generateReleaseTable();
			 	}
			 	lengthOfPhase = _attack + _decay + _hold + _release - genPosition;
				lengthOfPhase = Math.min(lengthOfPhase, framesLeftToMake);
				phaseOffset = Math.floor( ((genPosition-_attack-_decay-_hold) / _release)*1024 );
				_sample.resampleInDirectAccessSource(_releaseTable, phaseOffset, 1024/_release, genPosition, lengthOfPhase);
			}
			
		}
	
		override public function fill(toOffset:Number=-1):void 
		{
			if (toOffset < 0 || toOffset > frameCount) {
                toOffset = frameCount;
            }
            
            if (toOffset > _position) {
            	var numFrames:Number = toOffset - _position;
				// An uncached run of samples is needed
            	generateEnvelope(_position, numFrames);
            	_position = toOffset; // advance position
   			}
		}
		
		/**
		 * The EnvelopeGenerator should be destroyed when no longer needed,
		 * to free the sample memory.
		 */
		override public function destroy():void {
			_attackTable.destroy();
			_decayTable.destroy();
			_releaseTable.destroy();
			_sample.destroy();
			_sample = null;
		}
		
		
	}
}