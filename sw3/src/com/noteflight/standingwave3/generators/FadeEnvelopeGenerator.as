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
	import com.noteflight.standingwave3.elements.*;
	import com.noteflight.standingwave3.utils.AudioUtils;
	
	public class FadeEnvelopeGenerator extends AbstractGenerator
	{
		
		public static var FADE_IN:String = "fadeIn";
		public static var FADE_OUT:String = "fadeOut";
				
		private var _envTable:Sample;
		
		private var _type:String;
		
		/**
		 * A FadeInEnvelopeGenerator generates a sample table that describes the
		 * envelope shape for a fade in, and can be passed to a FadeInFilter.
		 * One generator can be reused across any voices that have
		 * the same envelope shape, and does not need to be cloned.
		 */
		public function FadeEnvelopeGenerator(descriptor:AudioDescriptor, t:Number, type:String)
		{
			super(descriptor, t);
			this._type = type;
		}
		
		protected function generateTable():void 
		{
			// The attack table goes from 0 signal to 1
			_envTable = new Sample(descriptor, 1025);
			if (_type == FADE_IN) {
				generateExponentialTable(_envTable, AudioUtils.MINIMUM_SIGNAL, 1);
			} else if (_type == FADE_OUT) {
				generateExponentialTable(_envTable, 1, AudioUtils.MINIMUM_SIGNAL);
			}
		}
		
		protected function generateEnvelope(genPosition:Number, numFrames:Number):void 
		{
			
			if (!_envTable) {
				generateTable();
			}
			var factor:Number = 1024/frameCount; // the scaling factor while resampling the envelope
			var envPosition:Number = (genPosition/frameCount) * 1024;
			
			// Scale the attack envelope out to this slice
			
			_sample.resampleInDirectAccessSource(_envTable, envPosition, factor, genPosition, numFrames);
			
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
		 * The generator should be destroyed when no longer needed,
		 * to free the sample memory.
		 */
		public function destroy():void {
			_envTable.destroy();
			_sample.destroy();
			_sample = null;
		}
		
		
	}
}