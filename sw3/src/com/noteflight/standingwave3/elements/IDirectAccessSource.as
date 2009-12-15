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
	public interface IDirectAccessSource
	{
		/**
         * Return the pointer to the sample memory so that other sample functions
         * can read directly from sample memory.
         * May return null if asked for a pointer to invalid memory.
         *  
         * @param frames the starting offset point of the range (inclusive)
         */
         function getSamplePointer(frames:Number = 0):uint;
	
		/**
         * useSample is like getSample(), except it does not return a Sample.
         * It just guarantees that the next frames are available in memory.
         * If the source is also an IAudioSource, it will also advance the position.
         *  
         * @param fromOffset the starting point of the range (inclusive)
         */
		 function useSample(frames:Number):void;
		 
		/**
		 * Fill is called to guarantee that the sample memory is valid
		 * up until the offset specified. Used extensively by CacheFilter
		 * and any other unit generators that are direct access. 
		 * If called without a param, it will attempt to fill the entire buffer. 
		 */
		 function fill(offset:Number = -1):void
		 
		/**
		 * Tell us the size of this source.
		 */
		 function get frameCount():Number  
		 
		 /**
		 * Retrieve audio descriptor
		 */
		 function get descriptor():AudioDescriptor
	}
}