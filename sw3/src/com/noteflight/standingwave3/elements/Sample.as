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
	import __AS3__.vec.Vector;
	
	import cmodule.awave.CLibInit;
	
	import flash.media.Sound;
	import flash.utils.ByteArray;
    
    /**
     * Sample is the fundamental audio source in StandingWave, and is the primary
     * way audio data is passed through the application. Sample also provides access to
     * a library of basic operations through its "Alchemical Wave" C Libraries.
     * Every sample has a fixed-size internal sample memory allocated for it, and its
     * data may be manipulated easily through the built in functions.
     * Alternatively, the sample data can be requested as a Vector of Numbers, manipulated,
     * and then committed back to the sample memory.
     */
    public final class Sample implements IAudioSource, IRandomAccessSource, IDirectAccessSource
    {
    	/** Uint "pointer" to the sample memory in the awave. */
    	protected var _samplePointer:uint;
    	
        /** Array of Vectors of data samples as Numbers, one Vector per channel. */
        protected var _channelData:Array;
        
        /** The number of 44.1k frames in the sample. */
        protected var _frames:Number;    
        
        /** To keep the sample memory and channelData Vectors in sync */
        protected var _channelDataDirty:Boolean = true;
        protected var _awaveMemoryDirty:Boolean = false;
        
        /** Audio descriptor for this sample. */
        protected var _descriptor:AudioDescriptor;
        
        /** Audio cursor position, expressed as a sample frame index. For use as an IAudioSource.  */
        protected var _position:Number;

		

		/** Statics for the singleton Alchemy Lib */
		private static var _awave:Object;
		private static var _awaveMemory:ByteArray; 
		private static var ns:Namespace = new Namespace("cmodule.awave");
		private static var _pool:MemoryPool;
		
		
        /**
         * Construct a new, empty Sample with some specified audio format. 
         * @param descriptor an AudioDescriptor specifying the audio format of this sample.
         * @param frames the number of frames in this Sample. required.
         */
        public function Sample(descriptor:AudioDescriptor, numFrames:Number = -1)
        {
        	if (!_awave) {
        		// Creates the Alchemy C Lib when you first need a Sample
        		Sample.initAlchemicalWaveSingleton();
        	}
            this._descriptor = descriptor;
            this._channelData = new Array();  
            this._frames = numFrames;
            if (_frames < 0) {
            	// Leaving this in for non-backwards compatibile situations
            	throw new Error("Zero length and variable size Samples are no longer supported in Standing Wave.");
            }
            var len:Number = numFrames * descriptor.channels;
            // First try to get sample memory from the pool
            this._samplePointer = _pool.fetch(len);
            // If a pool-sourced buffer was not available, then allocate new memory
            if (this._samplePointer == 0) {
            	this._samplePointer = Sample._awave.allocateSampleMemory(numFrames, descriptor.channels);
            }
            _position = 0; 
        }
         
        /**
         * Returns the total sample memory size in bytes
         */ 
        public static function getAwaveMemoryUsage():Number {
        	// Keep tabs on memory usage
			// var size:Number = Math.floor(_awaveMemory.bytesAvailable / (1024*1024) );
			// trace("Using " + size + " mb total sample memory");
			return _awaveMemory.bytesAvailable;
        }
        
        private static function initAlchemicalWaveSingleton():void {
        	var loader:CLibInit = new CLibInit();   
			Sample._awave = loader.init();
			Sample._awaveMemory = (ns::gstate).ds; //point to memory
			Sample._pool = new MemoryPool(Sample._awave);
        }
        
        /**
         * Adds frames to the sample memory.
         * The new sample will start with the existing sample data and be extended with zero samples.
         * Reallocating samples larger than 10-20 seconds can be quite slow.
         * @param numFrames the new total frameCount for this Sample    
         */
        public function realloc(numFrames:Number):void {
        	if (numFrames < frameCount) {
        		return;
        	} else {
        		_samplePointer = Sample._awave.reallocateSampleMemory(frameCount, numFrames, descriptor.channels);
        		_frames = numFrames;
        		invalidateChannelData();
        	}
        }
        
        /* Basic accessors and IAudioSource stuff */
        
        /**
         * The number of channels in this sample
         */
        public function get channels():Number
        {
            return _descriptor.channels;
        }
        
        /**
         * Return duration in seconds
         */
        public function get duration():Number
        {
            return frameCount / _descriptor.rate;
        }
        
        /**
         * Zero out this sample. 
         */
        public function clear():void
        {
            Sample._awave.setSamples(getSamplePointer(), _descriptor.channels, _frames, 0.0);
            invalidateChannelData();
        }    
        
        /**
         * @inheritDoc  
         */
        public function get descriptor():AudioDescriptor
        {
            return _descriptor;
        }
        
        /**
         * @inheritDoc
         */
        public function get frameCount():Number
        {
        	return _frames;	
        }

        /**
         * @inheritDoc
         */
        public function get position():Number
        {
            return _position;
        }
        
        public function set position(p:Number):void
        {
            _position = p;
        }
        
        /**
         * @inheritDoc
         */
        public function resetPosition():void
        {
            _position = 0;
        }
        
        /**
         * @inheritDoc
         */
        public function getSampleRange(fromOffset:Number, toOffset:Number):Sample
        {
        	if (_awaveMemoryDirty) {
        		commitChannelData();
        	}
        	var numFrames:int = toOffset - fromOffset;
            var returnSample:Sample = new Sample(descriptor, numFrames);
            var returnSamplePointer:uint = returnSample.getSamplePointer(0);
            var thisSamplePointer:uint = getSamplePointer(fromOffset);
            Sample._awave.mixIn(returnSamplePointer, thisSamplePointer, _descriptor.channels, numFrames, 1.0, 1.0);
            return returnSample;
        }

        /**
         * @inheritDoc
         */
        public function getSample(numFrames:Number):Sample
        {
            var sample:Sample = getSampleRange(_position, _position + numFrames);
            _position += numFrames;
            return sample;
        }
        
        /* IDirectAccessSource Implementation.
           The IDirectAccessSource works much like an IAudioSource, 
           except that another object can act directly on its sample memory. */
        
        /**
         * Returns a pointer to the sample memory, adjusted to the offset provided.
         * The user should be extremely careful accessing the memory returned.
         * Generally, this is READ-ONLY and used exclusively by other methods of Sample.
         * @param offset the number of frames into the sample. Defaults to 0, the sample start. 
         */ 
        public function getSamplePointer(offset:Number = 0):uint {
        	if (offset < 0 || offset > _frames) {
        		// Out of range, return a null pointer
        		throw new Error("Sample pointer out of range.");
        		return null; 
        	}
        	if (_descriptor.channels == AudioDescriptor.CHANNELS_STEREO) {
        		// Round to an even frame (a left channel sample), and double
        		offset = Math.floor(offset/2) * 4;
        	}
        	return _samplePointer + (4 * offset);  // 4 bytes per float * offset in frames
        }
          
        /**
         * IDirectAccessSources can be used similarly to IAudioSource.
         * Call useSample() instead of getSample(). This instructs the source to "fill" 
         * the next n frames, so that they will have valid data.
         * That data is then safe to access through its sample pointer.
         * Note that the Sample implementation is trivial/unnecessary,
         * and this is primarily used with CacheFilter.
         * @param numFrames the number of additional frames to use from this sample.
         */   
        public function useSample(numFrames:Number):void {
        	_position += numFrames; // just advance pointer
        }  
        
        public function fill(offset:Number=-1):void {
        	// does nothing
        }
          
        /* Memory management functions */    
          
        /**
         * Returns an array of channelData Vectors containing the entire contents of the sample memory. 
         * Note that this can take a few ms if a lot of data needs to be read. 
         * If only acting on a subset of the sample, it is better to use getChannelSlice(). 
         * Note that the Vector will have half as many samples when running at 22050 Hz. 
         */ 
        public function get channelData():Array 
        {
        	if (_channelDataDirty) {
        		var fcount:int = _frames;
        		_channelData = [];
        		for (var c:int=0; c<channels; c++) {
        			_channelData[c] = getChannelVector(c, 0, _frames);
        		}
        		_channelDataDirty = false;
        	}
        	return _channelData;
        }
        
        // Primarily used for sw2-era unit tests. Not for general use any longer... 
         
        /**
         * Return a sample for the given channel and frame index
         * @param channel the channel index of the sample
         * @param index the frame index of the sample within that channel
         */
        public function getChannelSample(channel:Number, index:Number):Number
        {
        	if (_awaveMemoryDirty) {
        		commitChannelData();
        	}
        	var rslt:Number;
        	rslt = Vector.<Number>(channelData)[channel][index];
            return rslt;
        }
        
        // Definitely only for tests! Don't use in Sample loops!!!! SLOW!!
        
        /**
         * Return an interpolated sample for a non-integral sample position.
         * Interpolation is always done within the same channel.
         */
        public function getInterpolatedSample(channel:Number, pos:Number):Number
        {
            var intPos:Number = int(pos);
            var fracPos:Number = pos - intPos;
            var s1:Number = getChannelSample(channel, pos);
            var s2:Number = getChannelSample(channel, pos+1);
            return s1 + (fracPos * (s2 - s1));
        }
        
        /** 
         * If you intend to modify the sample memory through the channelData 
         * then call invalidateSampleMemory() to notify the Sample to get the channelData
         * before performing any operations that use sample memory directly.
         * Or call commitChannelData() to write it back by hand.
         */
        public function invalidateSampleMemory():void {
        	_awaveMemoryDirty = true;
        }
        
        /**
        * Operations directly on sample memory invalidate our channel data.
        * This is only called internally.
        */
        protected function invalidateChannelData():void { 
        	_channelDataDirty = true;
        }
        
        /** 
        * If channelData is modified, use commitChannelData to write it back to memory. 
        */
        public function commitChannelData():void {
        	if (_awaveMemoryDirty) {
        		for (var c:int=0; c<_descriptor.channels; c++) {
        			vectorToSampleMemory(_channelData[c], c, 0, _frames);
        		}
        	_channelDataDirty = false;
        	_awaveMemoryDirty = false;
        	}
        }
           
        /** 
         * Get a fractional slice of the sample memory out as a vector.
         * Note that the Vector will have half as many samples when running at 22050 Hz.
       	 * @param channel channel index to retrieve, 0 for left, 1 for right
       	 * @param offset the start frame number for the slice
       	 * @param numFrames the number of frames to slice 
       	 * @returns a vector of Numbers corresponding to the sample memory.
       	 */
        public function getChannelSlice(channel:int, offset:Number, numFrames:Number):Vector.<Number> 
        {
        	return getChannelVector(channel, offset, numFrames);
        }
        
        /**
         * Commit a fractional slice of channeld data back to memory.
         * @param slice a Vector if channel data
         * @param channel the channel index to write to, 0 for left, 1 for right
         * @param offset the number of frames into the sample at which to start writing
         */
        public function commitSlice(slice:Vector.<Number>, channel:int, offset:Number):void 
        {
        	vectorToSampleMemory(slice, channel, offset, slice.length);
        	invalidateChannelData();
        }   
                      
        /** 
        * Creates a new channel Vector from the contents of sample memory 
        */ 
        protected function getChannelVector(channel:int=0, offset:Number=0, numFrames:Number=-1):Vector.<Number> 
        {	
        	var positionAddPerLoop:int = 0; 
        	if (_descriptor.channels == 2) {
        		positionAddPerLoop = 4; // 4 bytes per float, to skip alt channels
        	}
        	if (numFrames == -1) { numFrames = _frames; }
        	var fcount:int = numFrames; 
        	var slice:Vector.<Number> = new Vector.<Number>(fcount, true); // create if missing
        	// Now populate it from memory
        	_awaveMemory.position = getSamplePointer(offset) + (channel*4); // +4 bytes for right channel
        	for (var s:int=0; s<fcount; s++) {
        		slice[s] = _awaveMemory.readFloat(); // read the current position and advance 4 bytes
        		_awaveMemory.position += positionAddPerLoop; // jump ahead to the next frame
        	}
        	return slice;
        }
        
        /**
         * Writes a vector of channel data back to sample memory
         */
        protected function vectorToSampleMemory(data:Vector.<Number>, channel:int=0, offset:Number=0, numFrames:Number=-1):void 
        {
        	if (numFrames == -1) { numFrames = _frames; }
        	var positionAddPerLoop:int = 0;
        	if (_descriptor.channels == 2) {
        		positionAddPerLoop = 4; // 4 bytes per float, to skip alt channels
        	}
        	var fcount:int = Math.floor(numFrames);
        	_awaveMemory.position = getSamplePointer(offset) + (channel*4); // 4 byte offset for right channel
        	for (var s:int=0; s<fcount; s++) {
        		_awaveMemory.writeFloat( data[s] );
        		_awaveMemory.position += positionAddPerLoop;
        	}
        }
        
        /* Sample manipulations that use the new fast AlchemicalWave libs */       
          
        
        /**
         * Set a range of frames to a fixed sample value 
         * @param value the numerical value to set all samples to
         * @param targetOffset the offset into the sample to start modifying       
         * @param numFrames the number of continuous frames to set  
         */
        public function setSamples(value:Number, targetOffset:Number, numFrames:Number):void 
        {
            Sample._awave.setSamples(getSamplePointer(targetOffset), _descriptor.channels, numFrames, value);   
            invalidateChannelData();
        }   
        
        /**
         * Mix another whole Sample into this sample. They should have the same descriptor.
         * @param sourceSample the sample to mix in
         * @param gain the gain or attenuation of the source signal
         * @param offset the number of frames into this target sample at which to begin mixing  
         */ 
        public function mixIn(sourceSample:Sample, gain:Number=0.0, offset:Number=0):void 
        {
			mixInDirectAccessSource(IDirectAccessSource(sourceSample), 0, gain, offset, _frames);  
        }
        
       	/**
       	 * Mix part or all of another IDirectAccessSource into this Sample.
       	 * This can be another Sample, A CacheFilter, or any other unit generator. 
       	 * This is one of our core-functions, as memory to memory adds are *extremely* fast.
       	 * @param source the IDirectAccessSource, with valid data at the sourceOffset
       	 * @param sourceOffset the number of frames into our source to begin mixing from, defaults to 0
       	 * @param gain gain or attenuation of the source signal
       	 * @param targetOffset the number of frames into this target sample at which to begin mixing, defaults to 0
       	 */
        public function mixInDirectAccessSource(source:IDirectAccessSource, sourceOffset:Number=0, gain:Number=0.0, targetOffset:Number=0, numFrames:Number=-1):void {
       		var thisSamplePointer:uint;
        	var mixSamplePointer:uint;
 
        	if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	}
			thisSamplePointer = getSamplePointer(targetOffset); // mix in at this position
			mixSamplePointer = source.getSamplePointer(sourceOffset); // mix from this position
			numFrames = Math.min(numFrames, _frames - targetOffset); // don't mix more frames than are left in our target 
			numFrames = Math.min(numFrames, source.frameCount - sourceOffset); // and don't mix more than are left in our source
			Sample._awave.mixIn(thisSamplePointer, mixSamplePointer, _descriptor.channels, Math.floor(numFrames), gain, gain);  
			invalidateChannelData();
       } 
       
       /**
         * Mix a mono Sample into this stereo sample, with variable left and right gain.
         * @param sourceSample the sample to mix in
         * @param leftGain the left mix gain factor
         * @param rightGain the right mix gain factor
         * @param offset the number of frames into this target sample at which to begin mixing
         */ 
        public function mixInPan(sourceSample:Sample, leftGain:Number=1.0, rightGain:Number=1.0, offset:Number=0):void 
        {
        	if (_descriptor.channels != AudioDescriptor.CHANNELS_STEREO) {
        		throw new Error("mixInPan() only works with stereo samples.");
        	}
			mixInPanDirectAccessSource(IDirectAccessSource(sourceSample), 0, leftGain, rightGain, offset, _frames);  
        }
       
       	/**
       	 * Mix part or all of another IDirectAccessSource into this Sample.
       	 * This can be another Sample, A CacheFilter, or any other unit generator. 
       	 * This is one of our core-functions, as memory to memory adds are *extremely* fast.
       	 * @param source the IDirectAccessSource, with valid data at the sourceOffset
       	 * @param sourceOffset the number of frames into our source to begin mixing from, defaults to 0
       	 * @param leftGain gain or attenuation of the source signal, mixed into the left
       	 * @param rightGain gain or atten of source, mixed into the right
       	 * @param targetOffset the number of frames into this target sample at which to begin mixing, defaults to 0
       	 */
        public function mixInPanDirectAccessSource(source:IDirectAccessSource, sourceOffset:Number=0, leftGain:Number=1.0, rightGain:Number=1.0, targetOffset:Number=0, numFrames:Number=-1):void {
       		var thisSamplePointer:uint;
        	var mixSamplePointer:uint;
        	
        	if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}  
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	}  
			thisSamplePointer = getSamplePointer(targetOffset); // mix in at this position
			mixSamplePointer = source.getSamplePointer(sourceOffset); // mix from this position
			numFrames = Math.min(numFrames, _frames - targetOffset); // don't mix more frames than are left in our target 
			numFrames = Math.min(numFrames, source.frameCount - sourceOffset); // and don't mix more than are left in our source
			Sample._awave.mixInPan(thisSamplePointer, mixSamplePointer, Math.floor(numFrames), leftGain, rightGain);  
			invalidateChannelData();
       } 
       
       public function envelope(mp:Mod, numFrames:Number=-1):void 
       {
       		if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}  
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	} 
       		Sample._awave.envelope(getSamplePointer(), _descriptor.channels, numFrames, mp); 
       		invalidateChannelData();
       } 
        
       /**
        * The multiply functions are very similar to the mix functions.
        * They apply the amplitude envelope of the source on to the target.
        * At high rates, amplitude or ring modulation occurs.
        * If the sources do not have the same descriptor, superfluous data in the source is ignored.
        * @param sourceSample the source sample to multiply in
        * @param gain an extra multiplication factor to apply to the source
        * @param offset the number of frames into this target sample to begin multiplying at
        */  
        public function multiplyIn(sourceSample:Sample, gain:Number=1.0, offset:Number=0):void 
        {
			multiplyInDirectAccessSource(IDirectAccessSource(sourceSample), 0, gain, offset, _frames);  
        }
       
       	/**
       	 * Multiply in a slice of an IDirectAccessSource
       	 * This is our core "enveloping" function, as memory to memory multiplies are *fast*
       	 * @param source the IDrectAccessSource to multiply in
       	 * @param sourceOffset number of frames into the source to begin from
       	 * @param gain extra multiplication factor
       	 * @param targetOffset the number of frames into this target source at which to begin multiplying
       	 */
        public function multiplyInDirectAccessSource(source:IDirectAccessSource, sourceOffset:Number=0, gain:Number=1.0, targetOffset:Number=0, numFrames:Number=-1):void {
       		var thisSamplePointer:uint;
        	var mixSamplePointer:uint;
        	if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	}
			thisSamplePointer = getSamplePointer(targetOffset); // mix in at this position
			mixSamplePointer = source.getSamplePointer(sourceOffset); // mix from this position
			numFrames = Math.min(numFrames, _frames - targetOffset); // don't mix more frames than are left in our target 
			numFrames = Math.min(numFrames, source.frameCount - sourceOffset); // and don't mix more than are left in our source
			Sample._awave.multiplyIn(thisSamplePointer, mixSamplePointer, _descriptor.channels, Math.floor(numFrames), gain, gain );  
			invalidateChannelData();
       }
       
       
        
       	/**
       	 * Use a IDirectAccessSource as a wavetable, scanning it at a specified frequency
       	 * and generating a new continuous waveform into this sample.
       	 * This is a traditional technique for creating single cycle waveforms quickly.
       	 * @param table the IDirectAccessSource to use as a wavetable
       	 * @param tableSize the integer length in samples of the table (note the table should *actually* be tableSize+1 long, to allow for interpolation)
       	 * @param initalPhase a phasor normalized from 0-1
       	 * @param phaseAddPerFrame amount to add to this phasor per frame. typically frequency/samplerate
       	 * @param phaseReset the phase to reset to when it runs off the end 
       	 * @param targetOffset offset into this sample to begin writing the resultant waveform
       	 * @param numFrames the number of frames to generate
       	 * @returns The return value is the new phase angle after wave scanning. Reuse this phase in the next chunk to maintain constant scanning
       	 */    
       	public function wavetableInDirectAccessSource(table:IDirectAccessSource, tableSize:int, initialPhase:Number, phaseAdd:Number, phaseReset:Number, targetOffset:Number, numFrames:Number):Number {
       		var thisSamplePointer:uint; 
        	var tableSamplePointer:uint;
        	if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	}
			thisSamplePointer = getSamplePointer(targetOffset); // gen to this position
			tableSamplePointer = table.getSamplePointer(); // gen from this position
			numFrames = Math.min(numFrames, _frames - targetOffset); // don't mix more frames than are left in our target 
			var settings:Object = {tableSize:tableSize, phase:initialPhase, phaseAdd:phaseAdd, phaseReset:phaseReset };
        	Sample._awave.wavetableIn(thisSamplePointer, tableSamplePointer, _descriptor.channels, Math.floor(numFrames), settings );
        	// trace("New phase = " + settings.phase); 
        	invalidateChannelData();  
        	return settings.phase;  
       	} 
       	
       	/**
       	 * Use a IDirectAccessSource as a wavetable, scanning it at a specified frequency
       	 * and generating a new continuous waveform into this sample.
       	 * The phase does not "reset" as wavetable does. Instead it can be passed a table for
       	 * continuous pitch change.
       	 * @param table the IDirectAccessSource to use as a wavetable
       	 * @param tableSize the integer length in samples of the table (note the table should *actually* be tableSize+1 long, to allow for interpolation)
       	 * @param initalPhase a phasor normalized from 0-1
       	 * @param phaseAddPerFrame amount to add to this phasor per frame. typically frequency/samplerate
       	 * @param targetOffset offset into this sample to begin writing the resultant waveform
       	 * @param numFrames the number of frames to generate
       	 * @returns The return value is the new phase angle after wave scanning. Reuse this phase in the next chunk to maintain constant scanning
       	 */  
       	public function waveModInDirectAccessSource(table:IDirectAccessSource, tableSize:int, initialPhase:Number, phaseAdd:Number, pitchTablePointer:uint, targetOffset:Number, numFrames:Number):Number {
       		var thisSamplePointer:uint; 
        	var tableSamplePointer:uint;
        	if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	}
			thisSamplePointer = getSamplePointer(targetOffset); // gen to this position
			tableSamplePointer = table.getSamplePointer(); // gen from this position
			numFrames = Math.min(numFrames, _frames - targetOffset); // don't mix more frames than are left in our target 
			var settings:Object = {tableSize:tableSize, phase:initialPhase, phaseAdd:phaseAdd, pitchTable:pitchTablePointer };
        	Sample._awave.waveModIn(thisSamplePointer, tableSamplePointer, _descriptor.channels, Math.floor(numFrames), settings );
        	trace("Wave Mod. New phase = " + settings.phase); 
        	invalidateChannelData();  
        	return settings.phase;
       	} 
       
       	/** 
        * Resample writes one sample into another at a new speed. This is used for shifting
        * samples in pitch. The source sample must contain enough samples to fill the buffer, ie frames/factor.
        * @param sourceSample the source to resample in
        * @param factor the speed change expressed as a factor, ie 0.5 (half speed) or 2 (double speed) 
        */
        public function resampleIn(sourceSample:Sample, factor:Number):void
        {
        	resampleInDirectAccessSource(IDirectAccessSource(sourceSample), 0, factor, 0, _frames);
        }
        
        
        /**
         * Resample in any arbitrary slice from an IDirectAccessSource.
         * Resampling is a subset of wavetable scanning. We calculate the args to scan it exactly once at the right speed.
         * @source the IDirectAccessSource to resample in
         * @factor the speed change factor
         * @startFrame the first frame
         */
        public function resampleInDirectAccessSource(source:IDirectAccessSource, sourceOffset:Number=0, factor:Number=1, targetOffset:Number=0, numFrames:Number=-1):void
        { 
        	var thisSamplePointer:uint;
        	var tableSamplePointer:uint;
        	if (_awaveMemoryDirty) {
        		commitChannelData(); // make sure we're in sync
        	}
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, mix into the entire sample
        	}
			thisSamplePointer = getSamplePointer(targetOffset); // mix in at this position
			tableSamplePointer = source.getSamplePointer(0); // use the whole wavetable
			numFrames = Math.min(numFrames, _frames - targetOffset); // don't mix more frames than are left in our target 
        	var tableSize:Number = source.frameCount - 1; // minus a guard sample for interpolation
        	var phase:Number = sourceOffset / source.frameCount; // phase = fractional progress through the source
        	var phaseAdd:Number = factor / source.frameCount;
        	var settings:Object = {tableSize:tableSize, phase:phase, phaseAdd:phaseAdd, phaseReset:0};
        	Sample._awave.wavetableIn(thisSamplePointer, tableSamplePointer, _descriptor.channels, Math.floor(numFrames), settings );        	
        	invalidateChannelData();
        }
        
       
       	/**
       	 * A simple delay line that delays a sample by the size of the ringBuffer provided.
       	 * Wet and dry mix, and feedback controls can be used to create a range of echo effects.
       	 * @param ringBuffer another Sample to use as a delay line. The delay time will be equal to the length of this sample.
       	 * @param startOffset the number of frames into the sample to begin writing. Needed for continuous delay through many samples. typically position % delay frames.
       	 * @param dryMix the amount of original signal mixed into the output, as a factor, defaults to 0
       	 * @param wetMix the amount of delayed signal mixed into the output, defaults to 1
       	 * @param feedback the amount of delayed signal to "regenerate" to the input, creating echos, defaults to 0  
       	 */ 
        public function delay(ringBuffer:Sample, dryMix:Number=0, wetMix:Number=1, feedback:Number=0):void
        {
        	if (_awaveMemoryDirty) { 
        		commitChannelData(); // make sure we're in sync
        	}
        	// Create the object of delay settings to send in
        	var settings:Object = { 
        		length: int(ringBuffer.frameCount), 
        		dryMix: dryMix,     
        		wetMix: wetMix, 
        		feedback: feedback};        	 
       		Sample._awave.delay(getSamplePointer(), ringBuffer.getSamplePointer(), _descriptor.channels, int(_frames), settings); 
       		
       		// Note that the delay() method has also now shifted the data in the ring buffer, if you're looking...
       		
       		invalidateChannelData();	 		
        }   
            
        
        /** 
        * Change this sample's gain by a fixed factor.
        * @param leftGain the gain or attenuation expressed as a factor
        * @raram rightGain the gain for the right channel, defaults to the left channel gain
        */
        public function changeGain(leftGain:Number=1.0, rightGain:Number=-1):void 
        {
        	if (_awaveMemoryDirty) {
        		commitChannelData();
        	}
        	if (rightGain < 0) {
        		rightGain = leftGain;
        	}
        	Sample._awave.changeGain(getSamplePointer(0), _descriptor.channels, _frames, leftGain, rightGain);
        	invalidateChannelData();
        }
        
        /**
         * Biquad function runs a biquad filter function on the sample.
         * This function cannot be used for filters with continuously changing parameters.
         * @params state a 4 frame state sample that is needed to hold the filter delay line state
         * @params coeffs an object containing the filter coefficients, with values for a0,a1,a2,b0,b1,b2
         * Use the FilterCalculator class to obtain these.
         */
        public function biquad(state:Sample, coeffs:Object):void 
        {
        	if (_awaveMemoryDirty) {
        		commitChannelData();
        	}
        	Sample._awave.biquad(getSamplePointer(), state.getSamplePointer(), _descriptor.channels, _frames, coeffs);
        	invalidateChannelData(); 	
        }  
          
        /**
         * Standardize migrates a sample with any descriptor format to 44.1k stereo.
         * Mono signals are steroized, and 22050 Hz data is upsampled to 44100 Hz.
         * There is no change to samples in the correct format.
         * This is called by the AudioSampleHandler before passing anything to Sound output,
         * but may also be used any time in the processing chain that it is needed.
         */  
        public function standardize():void 
        {
        	if (_awaveMemoryDirty) {
        		commitChannelData();
        	}
        	if (_descriptor.rate != AudioDescriptor.RATE_44100 || 
        		_descriptor.channels != AudioDescriptor.CHANNELS_STEREO ) 
        	{
        		// Create a new sample, and write a 44.1k stereo version of this sample in.
        		// Switch this sample to point at the new memory
        		if (_descriptor.rate == AudioDescriptor.RATE_22050) {
        			_frames *= 2;
        		}  
        		var newSample:uint = Sample._awave.allocateSampleMemory(_frames, 2);
        		Sample._awave.standardize(newSample, _samplePointer,  _descriptor.channels, _frames, _descriptor.rate);	
        		Sample._awave.deallocateSampleMemory(_samplePointer);
        		_samplePointer = newSample;
        		_descriptor = new AudioDescriptor(AudioDescriptor.RATE_44100, AudioDescriptor.CHANNELS_STEREO);
        		_channelData = [];  // and a descriptor change has invalidated our channelData entirely
        		invalidateChannelData();  
        	}
        }
        
        /**
         * Extracts a native Flash Sound object into the sample memory.
         * Flash sounds are 44.1k stereo, but when extracted into a sample with a lower
         * descriptor, the superfluous data is simply discarded.
         * The position param refers to the position of both the sound and the memory
         * so a Sample derived from a Sound matches the length and size of the original.
         * @param soundObject any embedded or dynamically loaded Sound object 
         * @param position the frame offset into the Sound to begin extracting (in 44.1k frames)
         * @numFrames the number of frames to extract
         */
        public function extractSound(soundObject:Sound, position:Number, numFrames:Number):void 
        {
        	_awaveMemory.position = getSamplePointer();	
        	if (_descriptor.channels == 2 && _descriptor.rate == 44100) {	
        		//  Yay! We can extract the sound straight into the memory we allocated for this sample
            	var numSamples:Number = soundObject.extract(_awaveMemory, numFrames, position);  
         	 } else {
          		// We have to discard some of the data to fit into our smaller sample
          		var tempBytes:ByteArray = new ByteArray();
          		var s:int;
          		if (_descriptor.channels == 1 && _descriptor.rate == 22050) {	
          			soundObject.extract(tempBytes, numFrames*2, position*2); // extract to a temporary bytearray, then downsample
          			tempBytes.position = 0; 
          			while(tempBytes.bytesAvailable > 0) {
          				_awaveMemory.writeFloat( tempBytes.readFloat() );
          				tempBytes.position += 12; // skip 3 samples
          			}
          		} else if (_descriptor.channels == 2 && _descriptor.rate == 22050) {	
          			soundObject.extract(tempBytes, numFrames*2, position*2);           		
          			tempBytes.position = 0;
          			while(tempBytes.bytesAvailable > 0)  {
          				_awaveMemory.writeFloat( tempBytes.readFloat() );
          				_awaveMemory.writeFloat( tempBytes.readFloat() ); 
          				tempBytes.position += 8; // skip 2;
          			}
          		} else if (_descriptor.channels == 1 && _descriptor.rate == 44100) {
          			soundObject.extract(tempBytes, numFrames, position);
          			tempBytes.position = 0;
          			while(tempBytes.bytesAvailable > 0)  {
          				_awaveMemory.writeFloat( tempBytes.readFloat() );
          				tempBytes.position += 4; //skip 1 
          			}
          		}
          	}
            invalidateChannelData();
        }
        
        /** 
         * Read the sample data out to another ByteArray.
         * The AudioSampleHandler calls this to read a sample out to the final output ByteArray.
         * @param outputBytes the output ByteArray
         * @param offset the 
         */ 
        public function writeBytes(destBytes:ByteArray, offset:Number=0, numFrames:Number=-1):void 
        {
        	if (numFrames < 0) {
        		numFrames = _frames; // if unspecified, write the whole sample
        	}
        	// Awave memory is littleEndian, and the sampleEvent handler is bigEndian
        	// If we just adjust its littleEndianess, then we can use the Clib func to bang all the bytes in fast
        	destBytes.endian = "littleEndian";
        	Sample._awave.writeBytes(getSamplePointer(offset), destBytes, _descriptor.channels, _frames);
        } 
        
        public function copy(source:Sample, type:int):void
        {
        	if (_awaveMemoryDirty) {
        		commitChannelData();
        	}
        	Sample._awave.copy(getSamplePointer(), source.getSamplePointer(),
        		 _descriptor.channels, _frames, type);
        	invalidateChannelData();
        }  
          
       
        /**
         * Clone this Sample.  Note that the sample memory is shared between the
         * original and the clone. Channel Vectors are regenerated when needed.
         * Note that cloning Samples is almost always unnecessary, unless they are
         * being used themselves as audio sources, but that's weird behavior.
         */
        public function clone():IAudioSource
        {
            var sample:Sample = new Sample(_descriptor);
            sample._samplePointer = _samplePointer;
            return sample;
        }
        
        /**
         * Destroy the Sample and free the memory associated with it.
         */
        public function destroy():void 
        {
        	// Offer the sample memory to the memory pool
        	// If the pool doesn't want it, it'll be free'd
        	_pool.release(_samplePointer, _frames * _descriptor.channels);
        	_samplePointer = 0; // null pointer
        	for (var c:Number = 0; c < channels; c++) {
        		_channelData[c] = null;
        	}
        }
        
    }
    
}
	
	internal class MemoryPool
	{
		public var sizes:Array = [512, 1024, 2048, 4096, 8192];
		public var pool:Object;
		public var awave:Object;
		
		/**
		 * This class manages a pool of small sample buffers for the Sample class.
		 * Since the Alchemy lib's memory management can be kind of inefficient,
		 * we gain a lot of speed by reusing a pool of small buffers.  
		 */
		public function MemoryPool(aw:Object)
		{
			awave = aw;	
			pool = new Object();
			for (var s:int; s < sizes.length; s++) {
				pool[ sizes[s] ] = new Array();
				fillPool( sizes[s] );
			}
		}
	
		private function fillPool(len:int):void
		{
			// add 64 empty sample buffers of this length to the pool
			// store the pointers in the pool array
			var sp:uint;
			for (var b:int; b < 64; b++) {
				sp = awave.allocateSampleMemory(len, 1);
				pool[len].push(sp);
			}
		}
	
		/**
		 * Pull a buffer of this size from the pool.
		 * Returns 0 if there isn't one available.
		 */
		public function fetch(len:Number):uint
		{
			for (var s:int; s<sizes.length; s++) {
				if (len == sizes[s] && pool[len].length > 0) {
					// Here's one we can use
					return pool[len].pop();
				}
			}
			// Either it's larger than a size we're pooling, or we ran out
			return 0;
		}
		
		/**
		 * Release a buffer of this size to the pool
		 */
		public function release(pointer:uint, len:Number):void
		{
			for (var s:int; s<sizes.length; s++) {
				if (len == sizes[s] && pool[len].length < 64) {
					// We'll add this buffer to the pool
					pool[len].push(pointer);
					// And zero it out
					awave.setSamples(pointer, 1, len, 0.0);
					return;
				}
			}
			// Either it's not a size we're pooling, or we have enough of those.
			// So we'll just free the memory
			awave.deallocateSampleMemory(pointer);
		}
	}