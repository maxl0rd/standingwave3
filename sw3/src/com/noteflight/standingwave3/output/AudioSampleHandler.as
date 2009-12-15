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

package com.noteflight.standingwave3.output
{
    import com.noteflight.standingwave3.elements.*;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.SampleDataEvent;
    import flash.media.SoundChannel;
    import flash.utils.getTimer;
 
    /** Dispatched when the currently playing sound has completed. */
    [Event(type="flash.events.Event",name="complete")]
    
    /**
     * A delegate object that takes care of the work for audio playback by moving data
     * from an IAudioSource into a SampleDataEvent's ByteArray.
     */
    public class AudioSampleHandler extends EventDispatcher
    {
        /** Reports % of CPU used after each SampleDataEvent based on last event interval */
        public var cpuPercentage:Number = 0;

        /** frames supplied for each SampleDataEvent */
        public var framesPerCallback:Number;
        
        /** Overall gain factor for output. Deprecated. */
        public var gainFactor:Number = 1.0;
        
        /** The absolute frame number of the sample block at which the current source began playing */
        private var _startFrame:Number = 0;

        /** Timer value at conclusion of last sample block calculation, for CPU percentage determination */
        private var _lastSampleTime:Number = 0;
        
        /** Flag indicating that the current source has been examined during a sample data event. */
        private var _sourceStarted:Boolean;
        
        private var _totalLatency:Number = 0;
        private var _latencyCount:Number = 0;
        private var LATENCY_MAX_COUNT:Number = 10;

        // The SoundChannel that the output is playing through, really only needed for calculating latency
        private var _channel:SoundChannel;

        // If non-null, the audio source being currently rendered        
        private var _source:IAudioSource;
        
 
        public function AudioSampleHandler(framesPerCallback:Number = 4096)
        {
            this.framesPerCallback = framesPerCallback;
        }

        public function get source():IAudioSource
        {
            return _source;
        }

        public function set source(source:IAudioSource):void
        {
            _source = source;
        }

        public function set sourceStarted(sourceStarted:Boolean):void
        {
            _sourceStarted = sourceStarted;
        }
        
        public function set channel(channel:SoundChannel):void
        {
            _channel = channel;
        }


        /**
         * The latency in seconds.
         */
        public function get latency():Number
        {
            if (_latencyCount < LATENCY_MAX_COUNT)
            {
                return 0;
            }
            return _totalLatency / _latencyCount;
        }

        /**
         * The position in seconds relative to the start of the current source, else zero 
         */
        public function get position():Number
        {
            if (_channel != null && _source != null && _sourceStarted)
            {
                return (_channel.position / 1000.0) - (_startFrame / 44100);
            }
            return 0;
        }
        
        /**
         * Handle a request by the player for a block of samples. 
         */
        public function handleSampleData(e:SampleDataEvent):void
        {
            var now:Number = getTimer();
            
            // Determine latency based on skew between channel position and sample request position.
            if (_channel && position > 0 && _latencyCount < LATENCY_MAX_COUNT)
            {
                _totalLatency += (e.position / AudioDescriptor.RATE_44100) - (_channel.position / 1000.0);
                _latencyCount++; 
            }
            
            var endFrame:Number;
            var sample:Sample;
            var length:Number;
            
            // If the current source has never been seen here before, capture the starting
            // frame number at which its rendering is beginning.
            if (!_sourceStarted)
            {
                _startFrame = e.position;
                _sourceStarted = true;
            }
            
            // Determine the frame at which we should start getting samples from the source.
            var frame:Number;
            frame = e.position - _startFrame;
			length = source.frameCount - frame;
			if (length > framesPerCallback) {
				length = framesPerCallback;
			}
           
			if (length > 0)
			{	
				// Get our output Sample.
				sample = source.getSample(length);  
				
				// Read the sample data to the ByteArray provided by the handler, and then clean up
				sample.readBytes(e.data, 0, length);
				sample.destroy();
   			} 
             
            if (length <= 0) 
            {
                _source = null;
                _sourceStarted = false;
                dispatchEvent(new Event(Event.COMPLETE));
            }
            else if (length > 0 && length < framesPerCallback)
            {
                // Fill out remainder of sample block if the source could not supply all frames.  
                // Avoid Flash buffer underrun anger 
                for (var i:int = length; i < framesPerCallback; i++)
                {
                    e.data.writeFloat(0);
                    e.data.writeFloat(0);
                }
            }

            // Calculate CPU utilization
            calculateCpu(now);
            
        }

        private function calculateCpu(now:Number):void
        {
            if (_lastSampleTime > 0)
            {
            	// I find the CPU measure to be erratic beyond useful,
            	//   so we'll publish a moving average of the last 5 cpu calculations
            	var instantaneousCpu:Number = 100 * (getTimer() - now) / (now - _lastSampleTime);
                cpuPercentage = Math.floor(cpuPercentage*0.8 + instantaneousCpu*0.2);
                // trace("cpu:", cpuPercentage, "latency:", latency, "interval:", now - _lastSampleTime);
            }
            _lastSampleTime = now;
        }
    }
}
