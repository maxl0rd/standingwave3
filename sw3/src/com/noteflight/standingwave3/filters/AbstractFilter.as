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
    import com.noteflight.standingwave3.elements.*
 	import __AS3__.vec.Vector;
 	   
    /**
     * An abstract implementation of the IAudioFilter interface that can be
     * overridden to supply the specific transformation for a specific filter subclass. 
     */
    public class AbstractFilter implements IAudioFilter
    {
        /** The underlying source that acts as input to this filter. */        
        protected var _source:IAudioSource;
        
        /**
         * Create a new filter based on some underlying source. 
         * @param source the source that this filter transforms to produce its output.
         */
        public function AbstractFilter(source:IAudioSource = null)
        {
            this.source = source;
        }
        
        ////////////////////////////////////////////        
        // overrideable abstract methods
        ////////////////////////////////////////////

        /**
         * Transform the data for a channel by modifying it in place; called by the default implementation
         * of <code>getSample()</code>.  Overridden by subclasses.
         *  
         * @param data a Vector of channel data
         * @param channel the index of the channel being transformed
         * @param start the starting sample index of the transformation
         * @param numFrames the number of samples to be transformed
         */
        protected function transformChannel(data:Vector.<Number>, channel:Number, start:Number, numFrames:Number):void
        {
            throw new Error("generateChannel() not overridden");
        }

        ////////////////////////////////////////////        
        // IAudioFilter interface implementation
        ////////////////////////////////////////////        
        
        /**
         * The underlying audio source for this filter. 
         */
        public function get source():IAudioSource
        {
            return _source;
        }
        
        public function set source(s:IAudioSource):void
        {
            _source = s;
            if (_source != null)
            {
                resetPosition();
            }            
        }

        /**
         * @inheritDoc
         */
        public function get descriptor():AudioDescriptor
        {
            return source.descriptor;
        }
        
        /**
         * @inheritDoc
         */
        public function get frameCount():Number
        {
            return source.frameCount;
        }
        
        /**
         * @inheritDoc
         */
        public function get position():Number
        {
            return _source.position;
        }
        
        /**
         * @inheritDoc
         */
        public function resetPosition():void
        {
            _source.resetPosition();
        }
        
        /**
         * @inheritDoc
         */
        public function getSample(numFrames:Number):Sample
        {
            // This implementation of getSample delegates its work to transformChannel().
            // Note that the position is advanced implicitly by the call to _source.getSample()
            // since this advances the position of the "upstream" source, from which the filter's
            // position is derived.
            //
            var startPos:Number = position;
            var sample:Sample = _source.getSample(numFrames);
            for (var c:Number = 0; c < sample.channels; c++)
            {
                transformChannel(sample.channelData[c], c, startPos, numFrames);
            }
            return sample;
        }

        /**
         * @inheritDoc
         */
        public function clone():IAudioSource
        {
            throw new Error("clone() not overridden");
        }
    }
}
