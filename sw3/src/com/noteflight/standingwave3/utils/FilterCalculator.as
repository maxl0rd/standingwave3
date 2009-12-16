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

/* 
 * Thanks to Robert Bristow-Johnson  <rbj@audioimagination.com>
 *   For the classic Audio Filter Cookbook that this class is based on.
 */

package com.noteflight.standingwave3.utils
{
	import com.noteflight.standingwave3.elements.AudioDescriptor;
	
	public class FilterCalculator
	{
		/**
		 * This class provides static functions to aid in creating filter coefficients
		 * to be passed to the sample's filter methods.
		 */
		public function FilterCalculator() { }
		
		/**
		 * Low Pass Biquad
		 */
		public static function biquadLowPass(freq:Number, resonance:Number, rate:int):Object
		{
			var coeffs:Object = {};
            var w0:Number = 2 * Math.PI * freq / rate;
            var cosw0:Number = Math.cos(w0);
            var sinw0:Number = Math.sin(w0);
            var alpha:Number = sinw0 / (2 * resonance);
            
            coeffs.b0 = (1 - cosw0) / 2;
            coeffs.b1 = 1 - cosw0;
            coeffs.b2 = (1 - cosw0) / 2
            coeffs.a0 = 1 + alpha;
            coeffs.a1 = -2 * cosw0;
            coeffs.a2 = 1 - alpha;
            normalizeBiquadCoeffs(coeffs);
            
			return coeffs;
		}
		
		/**
		 * High Pass Biquad
		 */
		public static function biquadHighPass(freq:Number, resonance:Number, rate:int):Object
		{
			var coeffs:Object = {};
            var w0:Number = 2 * Math.PI * freq / rate;
            var cosw0:Number = Math.cos(w0);
            var sinw0:Number = Math.sin(w0);
            var alpha:Number = sinw0 / (2 * resonance);
            
            coeffs.b0 = (1 + cosw0) / 2;
            coeffs.b1 = -(1 + cosw0);
            coeffs.b2 = (1 + cosw0) / 2;
            coeffs.a0 = 1 + alpha;
            coeffs.a1 = -2 * cosw0;
            coeffs.a2 = 1 - alpha;
            normalizeBiquadCoeffs(coeffs);
            
			return coeffs;
		}
		
		/**
		 * Band Pass Biquad
		 */
		public static function biquadBandPass(freq:Number, resonance:Number, rate:int):Object
		{
			var coeffs:Object = {};
            var w0:Number = 2 * Math.PI * freq / rate;
            var cosw0:Number = Math.cos(w0);
            var sinw0:Number = Math.sin(w0);
            var alpha:Number = sinw0 / (2 * resonance);
            
            coeffs.b0 = alpha;
            coeffs.b1 = 0;
            coeffs.b2 = -alpha;
            coeffs.a0 = 1 + alpha;
            coeffs.a1 = -2 * cosw0;
            coeffs.a2 = 1 - alpha;
            normalizeBiquadCoeffs(coeffs);
            
			return coeffs;
		}
		
		/**
		 * Peak EQ Biquad.
		 * dbGain is boost or cut in db, ie. +6, +12, -6, etc...
		 */
		public static function biquadPeakEQ(freq:Number, resonance:Number, dbGain:Number, rate:int):Object
		{
			var coeffs:Object = {};
			var A:Number = Math.sqrt( Math.pow(10, dbGain/20) );
            var w0:Number = 2 * Math.PI * freq / rate;
            var cosw0:Number = Math.cos(w0);
            var sinw0:Number = Math.sin(w0);
            var alpha:Number = sinw0 / (2 * resonance);
            
            coeffs.b0 =   1 + alpha*A
            coeffs.b1 =  -2 * cosw0;
            coeffs.b2 =   1 - alpha*A
            coeffs.a0 =   1 + alpha/A
            coeffs.a1 =  -2 * cosw0;
            coeffs.a2 =   1 - alpha/A
            
            normalizeBiquadCoeffs(coeffs);
            
			return coeffs;
		}
		
		public static function biquadLowShelfEQ(freq:Number, resonance:Number, dbGain:Number, rate:int):Object
		{
			var coeffs:Object = {};
			var A:Number = Math.sqrt( Math.pow(10, dbGain/20) );
			var sqrtA:Number = Math.sqrt(A);
            var w0:Number = 2 * Math.PI * freq / rate;
            var cosw0:Number = Math.cos(w0);
            var sinw0:Number = Math.sin(w0);
            var alpha:Number = sinw0 / (2 * resonance);
            
            coeffs.b0 = A*( (A+1) - (A-1)*cosw0 + 2*sqrtA*alpha );
            coeffs.b1 = 2*A*( (A-1) - (A+1)*cosw0 );
            coeffs.b2 = A*( (A+1) - (A-1)*cosw0 - 2*sqrtA*alpha );
            coeffs.a0 = (A+1) + (A-1)*cosw0 + 2*sqrtA*alpha;
            coeffs.a1 = -2*( (A-1) + (A+1)*cosw0 );
            coeffs.a2 = (A+1) + (A-1)*cosw0 - 2*sqrtA*alpha;
            
            normalizeBiquadCoeffs(coeffs);
            
			return coeffs;
		}
		
		public static function biquadHighShelfEQ(freq:Number, resonance:Number, dbGain:Number, rate:int):Object
		{
			var coeffs:Object = {};
			var A:Number = Math.sqrt( Math.pow(10, dbGain/20) );
			var sqrtA:Number = Math.sqrt(A);
            var w0:Number = 2 * Math.PI * freq / rate;
            var cosw0:Number = Math.cos(w0);
            var sinw0:Number = Math.sin(w0);
            var alpha:Number = sinw0 / (2 * resonance);
            
            coeffs.b0 = A*( (A+1) + (A-1)*cosw0 + 2*sqrtA*alpha );
            coeffs.b1 = -2*A*( (A-1) + (A+1)*cosw0);
            coeffs.b2 = A*( (A+1) + (A-1)*cosw0 - 2*sqrtA*alpha );
            coeffs.a0 = (A+1) - (A-1)*cosw0 + 2*sqrtA*alpha;
            coeffs.a1 = 2*( (A-1) - (A+1)*cosw0 );
            coeffs.a2 = (A+1) - (A-1)*cosw0 - 2*sqrtA*alpha;
            
            normalizeBiquadCoeffs(coeffs);
            
			return coeffs;
		}
		
		
		/* Normalizes a set of coeffs to a0 */
		
		protected static function normalizeBiquadCoeffs(coeffs:Object):void 
		{
			coeffs.b0 /= coeffs.a0;	
			coeffs.b1 /= coeffs.a0;	
			coeffs.b2 /= coeffs.a0;	
			coeffs.a1 /= coeffs.a0;	
			coeffs.a2 /= coeffs.a0;	
		}

		

	}
}