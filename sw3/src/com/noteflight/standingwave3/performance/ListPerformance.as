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
     * A ListPerformance is an ordered list of PerformanceElements, each of which possesses an onset relative to the
     * start of the performance.  The list is optimized for the case where elements are appended in order of start time.
     */
    public class ListPerformance implements IPerformance
    {
        private var _defaultDescriptor:AudioDescriptor = new AudioDescriptor();
        private var _stereoDescriptor:AudioDescriptor;
        
        public var _stereoize:Boolean;
        
        private var _elements:Vector.<PerformanceElement> = new Vector.<PerformanceElement>;
        
        private var _dirty:Boolean = false;
        
        private var _frameCount:Number = 0;  
        
        private var _lastIndex:Number = 0;
        
        public function ListPerformance(stereoize:Boolean=false) {
        	this.stereoize = false;
        }
        
        /**
         * Add a Performance Element to this Performance. 
         */
        public function addElement(element:PerformanceElement):void
        {
            if ((! _dirty)
                && _elements.length > 0
                && element.start < _elements[_elements.length - 1].start)
            {
                // If we add an element which is out of order, note that we will have
                // to re-sort the performance later.
                //
                _dirty = true;
            }
            _elements.push(element);
            
            // Maintain a cached duration for the overall performance.  Note that
            // the "long straw" element whose end determines the performance end may
            // not be the last element.
            //
            _frameCount = Math.max(_frameCount, element.end);
        }
        
        /**
         * Add an IAudioSource to this performance, to start at a particular start time.
         */
        public function addSourceAt(startTime:Number, source:IAudioSource, gain:Number=0, pan:Number=0):void
        {
            addElement(new PerformanceElement(startTime, source, gain, pan));
        }
        
        /**
         * The list of PerformanceElements within this Performance, sorted by onset. 
         */        
        public function get elements():Vector.<PerformanceElement>
        {
            ensureSorted();
            return _elements;
        }
        
        /**
         * The start of the last performance element in the Performance. 
         */
        public function get lastStart():Number
        {
            var el:Vector.<PerformanceElement> = elements;
            return (el.length == 0) ? 0 : el[el.length-1].start;
        }
        
        /**
         * The frame count of the entire Performance. 
         */
        public function get frameCount():Number
        {
            return _frameCount;
        }
        
        //
        // IPerformance interface implementation
        //
        
        /**
         * @inheritDoc 
         */        
        public function getElementsInRange(start:Number, end:Number):Vector.<PerformanceElement>
        {
            // This makes use of _lastIndex as a memory of what was last queried to optimize
            // the search for the first matching element, since queries will in general run
            // in forward order.
            //
            var el:Vector.<PerformanceElement> = elements;
            var result:Vector.<PerformanceElement> = new Vector.<PerformanceElement>();             
            _lastIndex = Math.max(0, Math.min(_lastIndex, el.length - 1));

            // back up if prior element is ahead of starting frame
            while (_lastIndex > 0 && el[_lastIndex - 1].start >= start)
            {
                _lastIndex--;
            }

            // advance if our current element is prior to starting frame
            while (_lastIndex < el.length && el[_lastIndex].start < start)
            {
                _lastIndex++;
            } 
            
            // Return elements that start in this time window (and may also end in it)
            while (_lastIndex < el.length && el[_lastIndex].start < end)
            {
                result.push(el[_lastIndex++]);
            }

            return result;
        }
        
        public function set stereoize(s:Boolean):void
        {
        	_stereoize = s;
        }
        
        public function get stereoize():Boolean {
        	return _stereoize;
        }
        
        public function get descriptor():AudioDescriptor
        {
        	var rslt:AudioDescriptor;
        	if (elements.length > 0) {
                rslt =  elements[0].source.descriptor;
         	} else {
                rslt = _defaultDescriptor;
            }
            if (_stereoize) {
            	_stereoDescriptor = new AudioDescriptor(rslt.rate, 2);
        		rslt = _stereoDescriptor;
        	}
        	return rslt; 
        }

        public function clone():IPerformance
        {
            var p:ListPerformance = new ListPerformance();
            for each (var element:PerformanceElement in elements)
            {
                p.addElement(new PerformanceElement(element.startTime, element.source.clone()));
            }
            return p;
        }

        private function ensureSorted():void
        {
            if (_dirty)
            {
                _elements.sort(sortByStart);
                _dirty = false;
            }
        }

        private static function sortByStart(a:PerformanceElement, b:PerformanceElement):Number
        {
            var aStart:Number = a.start;
            var bStart:Number = b.start;
            if(aStart > bStart)
            {
                return 1;
            }
            else if(aStart < bStart)
            {
                return -1;
            }
            else
            {
                return 0;
            }
        }
    }
}