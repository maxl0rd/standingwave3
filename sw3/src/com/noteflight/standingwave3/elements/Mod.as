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

package com.noteflight.standingwave3.elements
{
	/**
	 * A ModPoint represents a spline segment that is used as a control
	 * value for some synthesis function. It contains four points so that
	 * operators can create a continuously smooth spline function through
	 * any time period. Modulations can be created at any rate, but the
	 * convention is 1024 frames per point.
	 */
	public class Mod
	{
		/** The previous modulation value before this segment.
		 * Can be the same as y1 if unknown, or if y1 is the first point. */
		public var y0:Number;
		
		/** The modulation value at the beginning of the segment. */
		public var y1:Number;
		
		/** The modulation value at the end of the segment */
		public var y2:Number;
		
		/** The next modulation value after the segment.
		 * Can be the same as y2 if unknown. */
		public var y3:Number;
	
		public function Mod(y0:Number=0, y1:Number=0, y2:Number=0, y3:Number=0) 
		{ 
			this.y0 = y0;
			this.y1 = y1;
			this.y2 = y2;
			this.y3 = y3;
		}
		
	}
}