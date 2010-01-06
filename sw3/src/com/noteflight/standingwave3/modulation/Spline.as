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

package com.noteflight.standingwave3.modulation
{
	import __AS3__.vec.Vector;
	
	import com.noteflight.standingwave3.elements.IModulationSource;
	import com.noteflight.standingwave3.elements.Mod;

	public class Spline implements IModulationSource
	{
		public static const MOD_RATE:int = 1024;
		
		public var knots:Vector.<Number>;
		
		public function Spline()
		{
			knots = new Vector.<Number>(0, false);
		}

		/**
		 * Returns a Mod object with the spline segment for the given position.
		 * Returns sensible values for empty, or incomplete splines.
		 * Does not interpolate around the edges.
		 */
		public function getMod(position:Number):Mod
		{
			var m:Mod = new Mod();
			var intP:int = Math.floor(position / MOD_RATE);
			
			// This is complicated because we want to return sensible values
			// for all the corner conditions
			
			if (knots.length == 0) {
				// return 0 mod signal for empty vector
				return m; 
			} else if (intP > knots.length-1) {
				// position is after the last knot, so stay constant on the final value
				m.y0 = m.y1 = m.y2 = m.y3 = knots[knots.length-1];
				return m;
			} else if (knots.length == 1) {
				// 1 knot, constant signal...
				m.y0 = m.y1 = m.y2 = m.y3 = knots[0];
				return m;
			} else {
				m.y1 = knots[intP-1];
				if (knots[intP-2]) {
					m.y0 = knots[intP-2];
				} else {
					m.y0 = m.y1;
				}
				if (knots[intP]) {
					m.y2 = knots[intP];
				} else {
					m.y2 = m.y1;
				}
				if (knots[intP+1]) {
					m.y3 = knots[intP+1];
				} else {
					m.y3 = m.y1;
				}
			}
			return m;
		}
		
	}
}