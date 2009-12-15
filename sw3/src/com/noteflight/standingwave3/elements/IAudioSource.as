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
     * An IAudioSource is the fundamental unit of construction for
     * StandingWave audio machines.  It represents a source of audio
     * data with characteristics described by an AudioDescriptor, a and
     * a definite number of sample frames.  The <code>position</code> property is a
     * cursor that indicates the frame index of the next portion of
     * data that will be retrieved by calling <code>getSample()</code>.
     * The ability to extract slices of data allows audio processing to take
     * place in small enough chunks that CPU intensive operations do not tie up
     * the Flash Player's event processing.
     */
    public interface IAudioSource
    {
        /**
         * The AudioDescriptor describing the audio characteristics of this source.
         */
        function get descriptor():AudioDescriptor;

        /**
         * The number of sample frames in this source.  An unbounded source
         * may return Number.MAX_VALUE.
         */
        function get frameCount():Number;

        /**
         * The position of the audio cursor in this source, as a frame index. 
         */
        function get position():Number;

        /**
         * Resets the audio cursor to the beginning of the source, and causes any
         * cursor-dependent state in the source to be initialized.
         */
        function resetPosition():void;
        
        /**
         * Retrieve a number of sample frames from this source as a Sample object,
         * starting from the audio cursor position.  It is not legal to request frames
         * beyond the maximum index indicated by the <code>frameCount</code> property.
         *  
         * @param numFrames an integral number of frames.
         * @return a Sample object containing the requested sample frames.
         */
        function getSample(numFrames:Number):Sample;
        
        /**
         * Return a copy of this source which is functionally identical to it, but which
         * is not required to preserve the audio cursor position or any other internal
         * state.  This function is useful for constructing source/filter graphs that can be
         * used as "prototypes", to be duplicated at will.
         */
        function clone():IAudioSource;
    }
}