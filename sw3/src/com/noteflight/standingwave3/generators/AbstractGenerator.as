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


package com.noteflight.standingwave3.generators
{
	import com.noteflight.standingwave3.elements.*;
	import __AS3__.vec.Vector;
	

	/**
     * AbstractGenerator is an implementation superclass for generator implementations.
     * A Generator implements both IRandomAccessSource and IDirectAccessSource.
     * It is intended to create functions that are "generated" once, and reused
     * many times across different sources and filters. They can be generated bit by
     * bit as needed, or all in one go.
     */
	
	public class AbstractGenerator implements IDirectAccessSource, IRandomAccessSource
	{
		/** The sample data to which we generate a function */
		protected var _sample:Sample;
		
		/** The next position to keep generating at */
		protected var _position:Number;
		
		
		public function AbstractGenerator(descriptor:AudioDescriptor, duration:Number)
		{
			_sample = new Sample(descriptor, Math.floor(duration * descriptor.rate) );
			this._position = 0;
		}

		public function get duration():Number { 
			return _sample.frameCount / _sample.descriptor.rate; 
		}
			
		public function get descriptor():AudioDescriptor { 
			return _sample.descriptor; 
		}
		
		/** Position indicates the position that it's been generated to. */
		public function get position():Number { 
			return _position; 
		}

		public function get frameCount():Number 
		{
			return _sample.frameCount;
		}

		public function getSamplePointer(offset:Number=0):uint
		{
			return _sample.getSamplePointer(offset);
		}
		
		public function useSample(frames:Number):void
		{
			fill(_position + frames);
		}
		
		public function getSampleRange(fromOffset:Number, toOffset:Number):Sample
		{
			// Constrain to the sample duration
			if (toOffset > frameCount) {
				toOffset = frameCount;
			}
			var numFrames:Number = toOffset - fromOffset;
			fill(toOffset);
			var result:Sample = new Sample(descriptor, numFrames);
			result.mixInDirectAccessSource(_sample, fromOffset, 1.0, 0, numFrames);
			return result;
		}
		
		/**
		 * This abstract class assumes you will override generateChannel() and write
		 * the sample through a channelData Vector. If you would prefer to generate
		 * directly into sample data in your own potentially faster way,
		 * override fill() instead.
		 */
		public function fill(toOffset:Number=-1):void 
		{
			if (toOffset < 0) {
                toOffset = frameCount;
            }
            
            if (toOffset > _position) {
            	var numFrames:Number = toOffset - _position;
				// An uncached run of samples is needed
            	for (var c:int = 0; c < descriptor.channels; c++) {
                	var data:Vector.<Number> = new Vector.<Number>(numFrames, true); 
                	generateChannel(data, c, numFrames);
                	_sample.commitSlice(data, c, _position); // commit the new data to the sample memory
            	}
            	_position = toOffset + 1; // advance position
   			}
		}
		
		protected function generateChannel(data:Vector.<Number>, channel:int, numFrames:Number):void
        {
            throw new Error("generateChannel() not overridden");
        }
		
		// Utility functions for making lookup tables for envelopes
		
		/**
		 * Generates an exponential curve from minimum to maximum into the Sample provided 
		 */
		protected static function generateExponentialTable(table:Sample, minimum:Number, maximum:Number):void
		{
			// Create a vector for the table
			var tableSize:int = table.frameCount;
			var maxDivMin:Number = maximum / minimum;
			var data:Vector.<Number> = new Vector.<Number>(tableSize, true);
			data[0] = minimum;
			for (var i:int=1; i<tableSize-1; i++) {
				// create an exponential curve from the minimum to maximum
				data[i] = minimum * Math.pow(maxDivMin, i/(tableSize-2));
			}
			data[tableSize-1] = maximum;
			// Write it to our sample data
			for (var c:int=0; c<table.descriptor.channels; c++) {
				table.commitSlice(data, c, 0);
			}
		}
		
		/**
		 * Generates a linear function from minimum to maximum into the Sample provided 
		 */
		protected static function generateLinearTable(table:Sample, minimum:Number, maximum:Number):void
		{
			// Create a vector for the table
			var tableSize:int = table.frameCount;
			var data:Vector.<Number> = new Vector.<Number>(tableSize, true);
			data[0] = minimum;
			for (var i:int=1; i<tableSize-1; i++) {
				// create a curve from the minimum to maximum
				data[i] = minimum + maximum * ( i/(tableSize-2) );
			}
			data[tableSize-1] = maximum;
			// Write it to our sample data
			for (var c:int=0; c<table.descriptor.channels; c++) {
				table.commitSlice(data, c, 0);
			}
		}
	}
}