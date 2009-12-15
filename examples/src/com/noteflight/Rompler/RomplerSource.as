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


package com.noteflight.Rompler
{
	import com.noteflight.standingwave3.elements.AudioDescriptor;
	import com.noteflight.standingwave3.elements.IAudioSource;
	import com.noteflight.standingwave3.elements.Sample;
	import com.noteflight.standingwave3.filters.AmpFilter;
	import com.noteflight.standingwave3.filters.PanFilter;
	import com.noteflight.standingwave3.generators.ADSREnvelopeGenerator;
	import com.noteflight.standingwave3.generators.SoundGenerator;
	import com.noteflight.standingwave3.sources.AbstractSource;

	/** Combines all of the functionality of sampling, looping, and enveloping
	 * to create a note from a sample source.
	 * 
	 */
	public class RomplerSource extends AbstractSource
	{
		public var soundGenerator:SoundGenerator; // the original sample, usually a SoundGenerator
		public var envelopeGenerator:ADSREnvelopeGenerator; // the amplitude shape, usually an EnvelopeGenerator
		public var frequencyShift:Number = 1.0; // a factor
		public var loopStartFrame:Number;
		public var loopEndFrame:Number;
		public var pan:Number = 0;
		
		private var _loopSource:LoopSource;
		private var _ampFilter:AmpFilter;
		private var _panFilter:PanFilter;
		
		public function RomplerSource(sg:SoundGenerator, eg:ADSREnvelopeGenerator)
		{
			super(new AudioDescriptor(sg.descriptor.rate, 2), eg.frameCount/eg.descriptor.rate, 1.0);
			soundGenerator = sg;
			envelopeGenerator = eg;
			loopStartFrame = 0;
			loopEndFrame = sg.frameCount;
		}
		
		override public function get frameCount():Number
		{
			// Return the lesser of the loop length or the envelope length
			// Usually they'll be the same, unless you're messing with it.
			return Math.min(duration * descriptor.rate, envelopeGenerator.frameCount);
		} 
		
		private function setUpChain():void 
		{
			_loopSource = new LoopSource(soundGenerator, duration);
			_loopSource.startFrame = loopStartFrame;
			_loopSource.endFrame = loopEndFrame;
			_loopSource.frequencyShift = frequencyShift;
			_ampFilter = new AmpFilter(_loopSource, envelopeGenerator);
			_ampFilter.gain = amplitude;
			_panFilter = new PanFilter(_ampFilter, 0, 0);
			_panFilter.pan = pan;
		}
		
		override public function getSample(numFrames:Number):Sample
		{
			if (!_loopSource) {
				setUpChain();
			}
			
			return _panFilter.getSample(numFrames);
		}
		
		override public function clone():IAudioSource 
		{
			var rslt:RomplerSource = new RomplerSource(soundGenerator, envelopeGenerator);
			rslt.loopEndFrame = loopEndFrame;
			rslt.loopStartFrame = loopStartFrame;
			rslt.frequencyShift = frequencyShift;
			rslt.amplitude = amplitude;
			rslt.pan = pan;
			return rslt; 
		}
		
	}
}