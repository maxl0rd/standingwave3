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


package com.noteflight.standingwave3.filters
{
    import com.noteflight.standingwave3.elements.*;
    import com.noteflight.standingwave3.utils.AudioUtils;
    
    /**
     * GainFilter applies a fixed gain factor to the underlying source.
     * This is about as simple a filter as it is possible to make, and runs fast.
     * In practice, it's not common to use this filter, as gain changes can
     * be snuck into many other filters as well.
     */
    public class GainFilter extends AbstractFilter
    {
        /** The gain factor applied, in decibels */
        public var gain:Number;
        
        /**
         * Create a new GainFilter. 
         * @param source the underlying audio source
         * @param gain the gain change in decibels. ie 0 = unity gain, +6 is twice as loud, -6 is half as loud
         */
        public function GainFilter(source:IAudioSource, gain:Number)
        {
            super(source);
            this.gain = gain;
        }
                
        override public function getSample(numFrames:Number):Sample
        {
            var sample:Sample = _source.getSample(numFrames);
            var fgain:Number = AudioUtils.decibelsToFactor(gain);
           	sample.changeGain(fgain);
            return sample;
        }

        override public function clone():IAudioSource
        {
            return new GainFilter(source.clone(), gain);
        }
    }
}
