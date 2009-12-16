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
	import com.noteflight.standingwave3.elements.*;
	import com.noteflight.standingwave3.filters.AbstractFilter;
	import com.noteflight.standingwave3.utils.*;

	/**
	 * ToneControlFilter provides relatively basic and gentle equalization
	 * for any input, and is useful in tonal shaping of the Rompler output.
	 */
	 
	public class ToneControlFilter extends AbstractFilter
	{
		/** Low shelving EQ shape */
		public static var LOW_SHELF:String = "lowShelf";
		
		/** High shelving EQ shape */
		public static var HIGH_SHELF:String = "highShelf";
		
		/** Peak EQ shape */
		public static var PEAK:String = "peak";
		
		public var treble:Number = 0; // dbGain
		public var bass:Number = 0; // dbGain
		public var trebleFrequency:Number = 8000;
		public var bassFrequency:Number = 120;
		public var trebleShape:String = HIGH_SHELF;
		public var bassShape:String = LOW_SHELF;
		
		private var _bassState:Sample;
		private var _trebleState:Sample;
		
		public function ToneControlFilter(source:IAudioSource=null)
		{
			super(source);
			_bassState = new Sample(descriptor, 4);
			_trebleState = new Sample(descriptor, 4);
		}
		
	 	override public function getSample(numFrames:Number):Sample
	 	{
	 		var bassCoeffs:Object; 
	 		var trebleCoeffs:Object; 
	 	
	 		if (bassShape == PEAK) {
	 			bassCoeffs = FilterCalculator.biquadPeakEQ(bassFrequency, 3, bass, _source.descriptor.rate);
	 		} else {
	 			bassCoeffs = FilterCalculator.biquadLowShelfEQ(bassFrequency, 3, bass, _source.descriptor.rate);
	 		}
	 		
	 		if (trebleShape == PEAK) {
	 			trebleCoeffs = FilterCalculator.biquadPeakEQ(trebleFrequency, 3, treble, _source.descriptor.rate);
	 		} else {
	 			trebleCoeffs = FilterCalculator.biquadHighShelfEQ(trebleFrequency, 3, treble, _source.descriptor.rate);
	 		}
	 	
	 		var sample:Sample = _source.getSample(numFrames);
	 		sample.biquad(_bassState, bassCoeffs);
	 		sample.biquad(_trebleState, trebleCoeffs);
	 		
	 		return sample;
	 	}
		
	}
}