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
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
 
    /** Dispatched when the currently playing sound has completed. */
    [Event(type="flash.events.Event",name="soundComplete")]
    
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
        
        /** A suck factor to keep track of how far off we are. */
        private var _deadFrames:Number = 0;

		/** Pause audio output */
		public var paused:Boolean = false;

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
                var rslt:Number = (_channel.position / 1000.0); // start with where the channel event is
                rslt -= _startFrame / 44100; // go back, if we started late for some reason
                rslt -= _deadFrames / 44100; // subtract all the dead frames that we didn't deliver
                return rslt;
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
                cpuPercentage = 0;
            }
            
            // Determine the frame at which we should start getting samples from the source.
            var frame:Number;
            frame = e.position - _startFrame;
            
            if (_source != null)
            { 
                // We have a live source to work with.
                if (frame > _source.position) {
                	// We've been dropping frames. Keep track of how far off we are.
                	_deadFrames = e.position - _source.position;
                	// trace("Dead frames at " + frame + " = " + _deadFrames);
                } else {
                	// trace("Healthy handler at " + frame);
                }

                // Determine amount left that we could conceivably deliver, pinned back
                // to the max that we can return.
                //
    			length = _source.frameCount - frame;
                
    			if (length > framesPerCallback) {
    				length = framesPerCallback;
    			}
            }
            else
            {
                // The source can be set to null by AudioPlayer.stop()
                // as a clean way of stopping the handler on the next callback.
                // This works better than stopping the channel forcibly.
                //
                length = 0;
            }
           
			if (length > 0)
			{	
				if (paused) 
				{
					// Push an empty sample through, if it is paused. This will accrue "dead frames"
					sample = new Sample(_source.descriptor, length, true);
				} else {
					// Get our output Sample.
					sample = _source.getSample(length);  
				}
				
				// Read the sample data to the ByteArray provided by the handler, and then clean up
				sample.writeBytes(e.data, 0, length);    
				sample.destroy();
   			} 
             
            if (length <= 0) 
            {
                _source = null;
                _sourceStarted = false;
                dispatchEvent(new Event(Event.SOUND_COMPLETE)); // Event.SOUND_COMPLETE
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
                dispatchEvent(new Event(Event.SOUND_COMPLETE)); // Event.SOUND_COMPLETE
            }

            // Calculate CPU utilization
            calculateCpu(now);
            
        }

        private function calculateCpu(now:Number):void
        {
            if (_lastSampleTime > 0)
            {
            	// The CPU measure can be erratic beyond useful,
            	//   so we'll publish a moving average of the last 5 cpu calculations
            	// var instantaneousCpu:Number = 100 * (getTimer() - now) / (now - _lastSampleTime);
                // cpuPercentage = Math.floor(cpuPercentage*0.8 + instantaneousCpu*0.2);
                // trace("cpu: ", cpuPercentage + "%");
                cpuPercentage = Math.floor(100 * (getTimer() - now) / (now - _lastSampleTime));
                // trace("cpu: " + cpuPercentage + "%");
				if (_channel) {
					// trace("peak: " + _channel.leftPeak + " / " + _channel.rightPeak);
					if (_channel.leftPeak > 0.98 || _channel.rightPeak > 0.98) {
						trace("AUDIO CLIPPING");
					}
				}
            }
            _lastSampleTime = now;
        }
    }
}
