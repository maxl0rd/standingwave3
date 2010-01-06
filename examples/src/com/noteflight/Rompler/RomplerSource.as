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
	import com.noteflight.standingwave3.utils.AudioUtils;

	/** The Rompler combines all of the functionality of sampling, looping, and enveloping
	 * to create a musical note from a sample source.
	 * Rompler feeds a SoundGenerator into a LoopSource, into an ADSR envelope,
	 * and into a final output pan filter. It's suitable for sending into a
	 * stereo AudioPerformer to create a stereo mix of any sample playback system.
	 * Unfortunately, you must provive loop points for all samples and manage your
	 * own voice allocation, and/or sample switching logic. 
	 * If you are playing complex sequences, consider sending each "note" into a
	 * CacheFilter, and reusing it in your Performance, instead of recalculating it.
	 */
	public class RomplerSource extends AbstractSource
	{
		public var soundGenerator:SoundGenerator; // the original sample, usually a SoundGenerator
		public var envelopeGenerator:ADSREnvelopeGenerator; // the amplitude shape, usually an EnvelopeGenerator
		
		public var loopStartFrame:Number;
		public var loopEndFrame:Number;
		public var basePitch:Number;
		public var pan:Number = 0;		
		public var pitch:Number;

		private var _loopSource:LoopSource;
		private var _ampFilter:AmpFilter;
		private var _panFilter:PanFilter;
		
		public function RomplerSource(ad:AudioDescriptor, sg:SoundGenerator, eg:ADSREnvelopeGenerator)
		{
			super(ad, eg.frameCount/eg.descriptor.rate, 1.0);
			soundGenerator = sg;
			envelopeGenerator = eg;
			loopStartFrame = 0;
			loopEndFrame = sg.frameCount;
			basePitch = 69;
			pitch = 69;
			setUpChain();  
		}
		
		public function get frequencyShift():Number
		{
			var baseFreq:Number = AudioUtils.noteNumberToFrequency(basePitch);
			var finalFreq:Number = AudioUtils.noteNumberToFrequency(pitch);
			return finalFreq/baseFreq;
		}
		
		override public function get frameCount():Number
		{
			// Return the lesser of the loop length or the envelope length
			// Usually they'll be the same, unless you're messing with it.
			return Math.min(duration * descriptor.rate, envelopeGenerator.frameCount);
		} 
		
		private function setUpChain():void 
		{
			_loopSource = new LoopSource(descriptor, soundGenerator, duration);
			_ampFilter = new AmpFilter(_loopSource, envelopeGenerator);
		}
		
		override public function getSample(numFrames:Number):Sample
		{
			_loopSource.frequencyShift = frequencyShift;
			_loopSource.startFrame = loopStartFrame;
			_loopSource.endFrame = loopEndFrame;
			_ampFilter.gain = amplitude;
			
			return _ampFilter.getSample(numFrames);
		}
		
		override public function clone():IAudioSource 
		{
			var rslt:RomplerSource = new RomplerSource(_descriptor, soundGenerator, envelopeGenerator);
			rslt.loopEndFrame = loopEndFrame;
			rslt.loopStartFrame = loopStartFrame;
			rslt.amplitude = amplitude;
			rslt.pan = pan;
			rslt.basePitch = basePitch;
			rslt.pitch = pitch;
			return rslt; 
		}
		
	}
}