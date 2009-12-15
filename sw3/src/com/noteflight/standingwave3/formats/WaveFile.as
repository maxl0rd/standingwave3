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
    import com.noteflight.standingwave3.elements.*
    
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
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
                var chunkStart:uint = wav.position;
                var blockAlign:uint = 0;
                var bitsPerSample:uint;
                
                switch(chunkType)
                {
                    case FORMAT_CHUNK:
                        var wFormatTag:uint = wav.readUnsignedShort();
                        if (wFormatTag != UNCOMPRESSED_FORMAT)
                        {
                            throw new Error("Cannot handle compressed WAV data");
                        }
                        var channels:uint = wav.readUnsignedShort();
                        var rate:uint = wav.readUnsignedInt();
                        var dwAvgBytesPerSec:uint = wav.readUnsignedInt();
                        blockAlign = wav.readUnsignedShort();
                        bitsPerSample = wav.readUnsignedShort();
                        sample = new Sample(new AudioDescriptor(rate, channels), 0);
                        break;
                        
                    case DATA_CHUNK:
                        var numSamples:uint = chunkSize / (bitsPerSample >> 3);
                        var numFrames:uint = numSamples / sample.channels;
                        var i:uint;
                        var c:uint = 0;
                        var j:uint = 0;
                        switch (bitsPerSample)
                        {
                            case 8:
                                for (i = 0; i < numSamples; i++)
                                {
                                    sample.channelData[c++][j] = wav.readByte() / 128.0;
                                    if (c == sample.channels)
                                    {
                                        c = 0;
                                        j++;
                                    }
                                }
                                break;
                                
                            case 16:
                                switch (sample.channels)
                                {
                                    case AudioDescriptor.CHANNELS_MONO:
                                        var data1:Vector.<Number> = sample.channelData[0];
                                        for (i = 0; i < numFrames; i++)
                                        {
                                            data1[j++] = wav.readShort() / 32768.0;
                                        }
                                        break;

                                    case AudioDescriptor.CHANNELS_STEREO:
                                        data1 = sample.channelData[0];
                                        var data2:Vector.<Number> = sample.channelData[1];
                                        for (i = 0; i < numFrames; i++)
                                        {
                                            data1[j] = wav.readShort() / 32768.0;
                                            data2[j++] = wav.readShort() / 32768.0;
                                        }
                                        break;

                                    default:
                                        for (i = 0; i < numSamples; i++)
                                        {
                                            sample.channelData[c++][j] = wav.readShort() / 32768.0;
                                            if (c == sample.channels)
                                            {
                                                c = 0;
                                                j++;
                                            }
                                        }
                                        break;
                                }
                                break;
                            
                            default:
                                throw new Error("Unsupported bits per sample: " + bitsPerSample);
                        }
                        break;
                }
                wav.position = chunkStart + chunkSize;
            }
            return sample;
        }
        
        public static function writeHeader(dataSize:uint, sampleRate:uint, numChannels:uint, bitDepth:uint):ByteArray
        {
            var wavData:ByteArray = new ByteArray();  
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

            subChunkSize.writeUnsignedInt(dataSize * numChannels * bitDepth / BYTE_LENGTH);
            
            wavData.writeBytes(subChunkSize);
            return wavData;
        }
    }
}
