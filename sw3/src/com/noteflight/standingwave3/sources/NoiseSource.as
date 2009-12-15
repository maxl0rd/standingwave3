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

package com.noteflight.standingwave3.sources
{
	import com.noteflight.standingwave3.elements.AudioDescriptor;
	import __AS3__.vec.Vector;
	
	public class NoiseSource extends AbstractSource
	{
		public function NoiseSource(descriptor:AudioDescriptor, duration:Number=MAX_DURATION, amplitude:Number=1.0)
		{
			super(descriptor, duration, amplitude);
		}
		
		override protected function generateChannel(data:Vector.<Number>, channel:Number, numFrames:Number):void
        {
        	// Naive noise source. Neither band-limited nor spectrum-shaped.
        	// TODO: Provide band-limited white, pink, brown, gaussian, etc noise sources
        	
        	var twiceA:Number = amplitude * 2;
            for (var i:int=0; i<numFrames; i++) {
            	data[i] = (Math.random()-0.5) * twiceA;
            }
            
        }
		
	}
}