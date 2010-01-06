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


package com.noteflight.standingwave3.performance
{
    import __AS3__.vec.Vector;
    
    import com.noteflight.standingwave3.elements.AudioDescriptor;
    
    /**
     * An IPerformance is a queryable set of PerformanceElements.  Only time-range queries may be performed.
     */
    public interface IPerformance
    {
        /**
         * Obtain a list of of PerformanceElements in this performance, ordered by starting frame index,
         * whose starting frame lies in a given range.
         * 
         * @param start frame count of range start (inclusive)
         * @param end frame count of the range end (exclusive)
         */
        function getElementsInRange(start:Number, end:Number):Vector.<PerformanceElement>;
        
        /**
         * The AudioDescriptor describing the audio characteristics of this performance.
         */
        function get descriptor():AudioDescriptor;

        /**
         * The number of sample frames in this performance. 
         */        
        function get frameCount():Number;
        
        /**
         * A boolean that determines whether audio performer creates a stereo mix from mono sources.
         */ 
        function get stereoize():Boolean
        
        /**
         * Obtain a clone of this performance, preserving all of its timing information but
         * cloning all contained audio sources. 
         */
        function clone():IPerformance;
    }
}