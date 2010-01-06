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
    
    import com.noteflight.standingwave3.elements.*;
    
    /**
     * A QueuePerformance works forward through a queue of audio sources.  The final element
     * of the queue is repeated indefinitely.  When more elements are added to a QueuePerformance,
     * the new elements are played immediately following the last complete repeat of any currently
     * playing element.
     */
    public class QueuePerformance implements IPerformance
    {
        private var _sources:Array = [];
        private var _nextStart:Number;
        private var _started:Boolean;
        
        public function QueuePerformance()
        {
            _nextStart = 0;
            _started = false;
        }

        /**
         * Add a new audio source to the queue of sources rendered by this queue.
         */
        public function addSource(source:IAudioSource):void
        {
            _sources.push(source);
        }
        
        /**
         * The frame count of the entire Performance. 
         */
        public function get frameCount():Number
        {
            return int.MAX_VALUE;  // it never ends
        }
        
        //
        // IPerformance interface implementation
        //
        
        /**
         * @inheritDoc 
         */        
        public function getElementsInRange(start:Number, end:Number):Vector.<PerformanceElement>
        {
            var result:Vector.<PerformanceElement> = new Vector.<PerformanceElement>();             
            if (_nextStart >= start && _nextStart < end)
            {
                if (_started && _sources.length > 1)
                {
                    _sources.shift();
                }
                var source:IAudioSource = _sources[0];
                result.push(new PerformanceElement(_nextStart / descriptor.rate, source.clone()));
                _nextStart += source.frameCount;
                _started = true;
            }
            return result;
        }
        
        public function get descriptor():AudioDescriptor
        {
            return _sources[0].descriptor;
        }

		public function get stereoize():Boolean 
		{
			return false;
		}

        public function clone():IPerformance
        {
            var qp:QueuePerformance = new QueuePerformance();
            for (var i:int = 0; i < _sources.length; i++)
            {
                qp.addSource(_sources[i].clone());
            }
            return qp;
        }
    }
}