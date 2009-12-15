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
     * An IRandomAccessSource is an interface implemented by IAudioSources that
     * expose the ability to extract any desired subrange at will, given its
     * starting and ending index.
     */
    public interface IRandomAccessSource
    {
        /**
         * Return a Sample representing a concrete subrange of this source.
         *  
         * @param fromOffset the starting point of the range (inclusive)
         * @param toOffset the endpoint of the range (exclusive)
         */
        function getSampleRange(fromOffset:Number, toOffset:Number):Sample;
        
    }
}