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


package com.noteflight.standingwave3.formats
{
    import com.noteflight.standingwave3.elements.*;
    
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import flash.utils.getTimer;
    
    /**
     * The WaveFile class translates between audio files in the WAV format and
     * Samples.  
     */    
    public class WaveFile
    {
        // File format constants
        private static const RIFF_GROUP_ID:String = "RIFF";
        private static const WAVE_TYPE:String = "WAVE";
        private static const FORMAT_CHUNK:String = "fmt ";
        private static const DATA_CHUNK:String = "data";
        private static const SAMPLE_CHUNK:String = "smpl";      
        private static const INSTRUMENT_CHUNK:String = "inst";  
        private static const UNCOMPRESSED_FORMAT:uint = 1;
        private static const HEADER_OFFSET:uint = 36;
        private static const SUBCHUNK_SIZE_PCM:uint = 16;
        private static const BYTE_LENGTH:uint = 8;
        
        /**
         * Given a WAV file in the form of a ByteArray, return a Sample
         * that includes its data.
         */
        public static function createSample(wav:ByteArray):Sample
        {
            wav.endian = Endian.LITTLE_ENDIAN;
            var groupId:String = wav.readUTFBytes(4);
            if (groupId != RIFF_GROUP_ID)
            {
                throw new Error("Invalid WAV group id: " + groupId);
            }

            var fileLen:uint = wav.readUnsignedInt();
            fileLen += wav.position;
            
            var riffType:String = wav.readUTFBytes(4);
            if (riffType != WAVE_TYPE)
            {
                throw new Error("Invalid RIFF type; expected WAVE but found: " + riffType);
            }
            
            var sample:Sample;
            
            while (wav.position < fileLen)
            {
                var chunkType:String = wav.readUTFBytes(4);
                var chunkSize:uint = wav.readUnsignedInt();
                if ((chunkSize % 2) == 1)
                {
                   // wav spec says: round chunks to even bytes, so force to word boundary
                   chunkSize += 1;
                }
                var chunkStart:uint = wav.position;
                var blockAlign:uint = 0;
                var bitsPerSample:uint;
                var channels:uint;
                var rate:uint;
                        
                switch(chunkType)
                {
                    case FORMAT_CHUNK:
                        var wFormatTag:uint = wav.readUnsignedShort();
                        if (wFormatTag != UNCOMPRESSED_FORMAT)
                        {
                            throw new Error("Cannot handle compressed WAV data");
                        }
                        channels = wav.readUnsignedShort();
                        rate = wav.readUnsignedInt();
                        var dwAvgBytesPerSec:uint = wav.readUnsignedInt();
                        blockAlign = wav.readUnsignedShort();
                        bitsPerSample = wav.readUnsignedShort();
                        break;
                    
                    case SAMPLE_CHUNK:
                    	// Read in loop data, and put it where ... ?!
                    	break;
                    	
                    case INSTRUMENT_CHUNK:
                    	// Read in instrument data, and put it where ... ?!
                    	break;
                        
                    case DATA_CHUNK:
                    
                    	// Read the descriptor
                        var numSamples:uint = chunkSize / (bitsPerSample >> 3);
                        var numFrames:uint = numSamples / channels;
                        
                        // Allocate sample memory
                        sample = new Sample(new AudioDescriptor(rate, channels), numFrames);
                       
                       	// Convert the wav data byte array into native floating point sample format
                        sample.readWavBytes(wav, bitsPerSample, sample.channels, numFrames);
                        
                        break;
                }
                wav.position = chunkStart + chunkSize;
            }
            return sample;
        }
        
        /**
         * Convert a StandingWave Sample to a 16bit Wave file
         * 
         * @param sample the sample to convert
         * @returns a ByteArray containing the complete wave file data, including header
         */  
        public static function writeSampleToWavFile(sample:Sample):ByteArray
        {
        	var wavData:ByteArray = new ByteArray(); // final file
       		wavData.endian = Endian.BIG_ENDIAN;
       		
       		// Size in bytes = number of frames * channels * 2 bytes per 16 bit word
       		// Don't worry about rounding to word, since we're on 16 bit
       		var dataSize:uint = sample.frameCount * sample.descriptor.channels * 2;
       		
       		// Write header
            WaveFile.writeHeader(wavData, dataSize, sample.descriptor.rate, sample.descriptor.channels, 16);
       		
       		// Write data
       		sample.writeWavBytes(wavData);
       		
       		return wavData;
        }
        
        /**
         * Converts a ByteArray containing raw fixed point audio data into a Wave file.
         * Works by generating a WAV header, and then copying the raw data after.
         * 
         * @param wavData the destination ByteArray in which to create the Wave file.
         * @param rawDataBytes the source ByteArray containing raw fixed point audio data
         * @param sampleRate the sampling rate of the raw audio data
         * @param numChannels the number of interleaved channels of audio data
         * @param bitDepth the bit depth of the audio data
         */
        public static function writeBytesToWavFile(wavData:ByteArray, rawDataBytes:ByteArray, sampleRate:uint, numChannels:uint, bitDepth:uint):void
        {
        	// Round data size to word if needed
        	var dataSize:uint = rawDataBytes.length;
        	if ((dataSize % 2) == 1) {
            	dataSize += 1; 
            	rawDataBytes.position = rawDataBytes.length;
            	rawDataBytes.writeByte(0);
            }
            
            // Write header
            WaveFile.writeHeader(wavData, dataSize, sampleRate, numChannels, bitDepth);
            
            // Write data
            wavData.writeBytes(rawDataBytes);
            
        }
        
        /**
         * Writes just a WAV header to a destination ByteArray
         * 
         * @param wavData the destination ByteArray in which to write the wav file header
         * @param dataSize the number of bytes of audio data (must be an even number of bytes, per WAV spec)
         * @param sampleRate the sampling rate of the raw audio data
         * @param numChannels the number of interleaved channels of audio data
         * @param bitDepth the bit depth of the audio data
         */  
        public static function writeHeader(wavData:ByteArray, dataSize:uint, sampleRate:uint, numChannels:uint, bitDepth:uint):void
        {
             
            wavData.endian = Endian.BIG_ENDIAN;
            //big endian                       
            wavData.writeUTFBytes(RIFF_GROUP_ID);

            //little endian
            var size:ByteArray = new ByteArray();  
            size.endian = Endian.LITTLE_ENDIAN;
            
            size.writeUnsignedInt(dataSize + HEADER_OFFSET);
            wavData.writeBytes(size);
            
            //big endian
            wavData.writeUTFBytes(WAVE_TYPE);
            wavData.writeUTFBytes(FORMAT_CHUNK);

            //little endian
            var metaData:ByteArray = new ByteArray();  
            metaData.endian = Endian.LITTLE_ENDIAN;
            
            //sub chunk size (of PCM)
            metaData.writeUnsignedInt(SUBCHUNK_SIZE_PCM);

            //format (1 for PCM)
            metaData.writeShort(UNCOMPRESSED_FORMAT);
            
            //number of channels (mono)
            metaData.writeShort(numChannels);

            //sample rate
            metaData.writeUnsignedInt(sampleRate);

            // Byte Rate
            metaData.writeUnsignedInt(sampleRate * numChannels * bitDepth / BYTE_LENGTH);

            metaData.writeShort(numChannels * bitDepth / BYTE_LENGTH);

            // bits per sample
            metaData.writeShort(bitDepth);
      
            wavData.writeBytes(metaData);
                        
            wavData.writeUTFBytes(DATA_CHUNK);
            
            //sub chunk size
            //little endian
            var subChunkSize:ByteArray = new ByteArray();  
            subChunkSize.endian = Endian.LITTLE_ENDIAN;

            subChunkSize.writeUnsignedInt(dataSize);
            
            wavData.writeBytes(subChunkSize);
            
        }
    }
}
