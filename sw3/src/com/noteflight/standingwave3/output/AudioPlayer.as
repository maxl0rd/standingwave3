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
    import com.noteflight.standingwave3.elements.IAudioSource;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.ProgressEvent;
    import flash.events.SampleDataEvent;
    import flash.events.TimerEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.utils.Timer;
    
    /** Dispatched when the currently playing sound has completed. */
    [Event(type="flash.events.Event",name="complete")]
    
    /**
     * An AudioPlayer streams samples from an IAudioSource to a Sound object using a
     * SampleDataEvent listener.  It does so using a preset number of frames per callback,
     * and continues streaming the output until it is stopped, or until there is no more
     * audio output obtainable from the IAudioSource.
     */
    public class AudioPlayer extends EventDispatcher
    {

        // The sound being output
        private var _sound:Sound;
        
        // The SoundChannel that the output is playing through
        private var _channel:SoundChannel;
 
        // The delegate that handles the actual provision of the samples
        private var _sampleHandler:AudioSampleHandler;
        
        private static const PROGRESS_INTERVAL:Number = 1000 / 15;
        private var _progressTimer:Timer = new Timer(PROGRESS_INTERVAL);
 
        /**
         * Construct a new AudioPlayer instance. 
         * @param framesPerCallback the number of frames that this AudioPlayer will
         * obtain for playback on each SampleDataEvent emitted by the playback Sound object.
         */
        public function AudioPlayer(framesPerCallback:Number = 4096)
        {
            _sampleHandler = new AudioSampleHandler(framesPerCallback); 
            _sampleHandler.addEventListener(Event.SOUND_COMPLETE, handleComplete);
            _progressTimer.addEventListener(TimerEvent.TIMER, handleProgressTimer);
        }
        
        /**
         * Play an audio source through this output.  Only one source may be played at a time.
         * @param source an IAudioSource instance
         */
        public function play(source:IAudioSource):void
        {
            stop();
            if (source.descriptor.channels == 2 && source.descriptor.rate == 44100) {
            	_sampleHandler.source = source;
            	_sampleHandler.sourceStarted = false;
            	startSound();
            } else {
            	throw new Error("AudioPlayer no longer supports lower audio descriptors. Please pass the source through the StandardizeFilter() before output.");
            }
        }
        
        /**
         * Stop a given source (if supplied), or stop any source that is playing (if no source
         * parameter is supplied). 
         * 
         * @param source an optional IAudioSource instance
         */
        public function stop(source:IAudioSource = null):void
        {
            if (source == null || source == _sampleHandler.source)
            {
                _sampleHandler.source = null;
                _sampleHandler.channel = null;
                if (_channel)
                {
                    // We don't need to tell the channel to stop: the next
                    // SampleDataEvent callback will cause the sample handler
                    // to return no frames, which immediately halts playback.
                    // Stopping the channel here causes a crash, possibly due to
                    // unexpected re-entrancy somewhere in the player FSM.
                    // 
                    // _channel.stop();
                    
   					// A more elegant solution is to mute the channel immediately,
   					//  and then null the channel so that it returns nothing next event
                    _channel.soundTransform = new SoundTransform(0);
                    _channel = null;
                }

                if(_sound){
                  /*This fixes an annoying bug. If you start and start the sample source again
                  you will notice that the sound plays in multiple speed dependet on how often you started the same source again.
                  It`s a bug! You have to remove the handler for sample data when erasing the _sound object. In general this also prevents memory leaking. */
                  _sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, handleSampleData);
                }
                _sound = null;
            }
        }
        
        /**
         * The source currently being played by this object, or null if there is none.
         */
        public function get source():IAudioSource
        {
            return _sampleHandler.source;
        }
        
        /**
         * The SoundChannel currently employed for playback, or null if there is none.
         */
        public function get channel():SoundChannel
        {
            return _channel;
        }

        /**
         * Begin continuous sample block generation. 
         */
        private function startSound():void
        {
            if (_sound != null)
            {
                return;
            }
            _sound = new Sound();
            _sound.addEventListener(SampleDataEvent.SAMPLE_DATA, handleSampleData);
            _channel = _sound.play();
            _sampleHandler.channel = _channel;
            _progressTimer.start();
        }
        
		public function pause():void 
		{
			if (_sampleHandler)
			{
				_sampleHandler.paused = true;
			}
		}
		
		public function resume():void 
		{
			if (_sampleHandler)
			{
				_sampleHandler.paused = false;
			}
		}
		
        /**
         * Handle a SampleDataEvent by passing it to the AudioSampleHandler delegate.
         */
        private function handleSampleData(e:SampleDataEvent):void
        {
        	// Occassionally useful to turn this trace on...
        	// trace("start handle");
        	
            _sampleHandler.handleSampleData(e);
            
            // trace("end handle");
            
        }
        
        private function handleProgressTimer(e:TimerEvent):void
        {
            dispatchEvent(new ProgressEvent("progress"));
        }
        
        /**
         * Handle completion of our sample handler by forwarding the event to anyone listening to us.
         */
        private function handleComplete(e:Event):void
        {
            dispatchEvent(e);
            _progressTimer.stop();
        }
 
        /**
         * The actual playback position in seconds, relative to the start of the current source. 
         */
        [Bindable("positionChange")]
        public function get position():Number
        {
            return _sampleHandler.position;
        }

        /**
         * The estimated percentage of CPU resources being consumed by sound synthesis. 
         */
        [Bindable("positionChange")]
        public function get cpuPercentage():Number
        {
            return _sampleHandler.cpuPercentage;
        }

        /**
         * The estimated time between a SampleDataEvent and the actual production of the
         * sound provided to that event, if known.  The time is expressed in seconds.
         */
        [Bindable("positionChange")]
        public function get latency():Number
        {
            return _sampleHandler.latency;
        }
    }
}