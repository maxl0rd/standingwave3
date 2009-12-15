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
    import com.noteflight.standingwave3.elements.IAudioSource;
    
    /**
     * A PerformanceElement is an IAudioSource with a specific start index in sample frames.
     */
    public class PerformanceElement
    {
        private var _source:IAudioSource;
        private var _start:Number;
        
        /**
         * Create a PerformanceElement that renders the given source at a particular time onset. 
         * @param start a time onset within the performance in seconds from the time origin
         * @param source an instance of IAudioSource
         * 
         */
        public function PerformanceElement(startTime:Number, source:IAudioSource)
        {
            _start = Math.floor(startTime * source.descriptor.rate);
            _source = source;
        }
               
        /**
         * The underlying audio source. 
         */
        public function get source():IAudioSource
        {
            return _source;
        }
        
        /**
         * The starting time frame offset for the audio in this source 
         */
        public function get start():Number
        {
            return _start;
        }
        
        /**
         * The ending time frame offset for the audio in this source 
         */
        public function get end():Number
        {
            return _start + _source.frameCount;
        }

        /**
         * The starting time offset in seconds
         */
        public function get startTime():Number
        {
            return _start / source.descriptor.rate;
        }
        
        /**
         * The ending time offset in seconds
         */
        public function get endTime():Number
        {
            return end / source.descriptor.rate;
        }
    }
}