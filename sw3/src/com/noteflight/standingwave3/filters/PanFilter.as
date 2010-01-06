//////////////////////////////////////////////////////////////////////////////
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
	import com.noteflight.standingwave3.utils.AudioUtils;

	public class PanFilter extends AbstractFilter
	{
		public static const PAN_LAW_NONE:Number = 0.0; // signals panned center will be 2x as loud
		public static const PAN_LAW_NORMAL:Number = -3.0; // -3db down in center is normal
		public static const PAN_LAW_MID:Number = -4.5; // the "SSL" pan law
		public static const PAN_LAW_STEEP:Number = -6.0; // -6db down is ideal for constant power
		
		private var _panLaw:Number = -3.0; // gain reduction at center, in db
		private var _gain:Number = 0.0; // additional gain factor, in db. 0 = unity gain
		private var _pan:Number = 0.0; // pan position, -1 (left) to 1 (right)
		
		protected var _leftGain:Number;
		protected var _rightGain:Number;
		protected var _descriptor:AudioDescriptor;
		
		public function PanFilter(source:IAudioSource=null, p:Number=0, g:Number=0)
		{
			super(source);
			if (source.descriptor.channels > 1) {
				throw new Error ("Use PanFilter with mono sources only.");
			}
			this._descriptor = new AudioDescriptor(source.descriptor.rate, AudioDescriptor.CHANNELS_STEREO);
			_pan = p;
			_gain = g;
			calculateGains();
		}
		
		override public function get descriptor():AudioDescriptor 
		{
			return _descriptor;
		}
		
		public function set panLaw(pl:Number):void {
			_panLaw = pl;
			calculateGains();
		}
		
		public function set pan(p:Number):void {
			_pan = p;
			calculateGains();
		}
		
		public function set gain(g:Number):void {
			_gain = g;
			calculateGains();
		}
		
		public function get panLaw():Number { return _panLaw; }
		public function get gain():Number { return _gain; }
		public function get pan():Number { return _pan; }
		
		private function calculateGains():void 
		{	
			// Change pan position -1 to 1 into left and right amplitude factors
			var gains:Object = AudioUtils.panToFactors(_pan, _panLaw);
			_leftGain = gains.left;
			_rightGain = gains.right;
			
			// Static gain adjustment
			_leftGain *= AudioUtils.decibelsToFactor(_gain);
			_rightGain *= AudioUtils.decibelsToFactor(_gain);
		}
		 
		override public function getSample(numFrames:Number):Sample 
		{
			var sample:Sample = _source.getSample(numFrames);
			var returnSample:Sample = new Sample(_descriptor, numFrames); 
			returnSample.mixInPan(sample, _leftGain, _rightGain); 
			sample.destroy(); // discard our mono sample after mixing it in
			return returnSample; 
		}
		
	}
}