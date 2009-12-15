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
    import flexunit.framework.TestCase;

    public class AudioTestCase extends TestCase
    {
        protected var s1:Sample;
        
        override public function setUp():void
        {
            s1 = new Sample(new AudioDescriptor(AudioDescriptor.RATE_22050, AudioDescriptor.CHANNELS_STEREO), 4);
            var i:Number = 0;
            s1.channelData[0][i++] = 200;
            s1.channelData[0][i++] = 400;
            s1.channelData[0][i++] = 600;
            s1.channelData[0][i++] = 800;
            i = 0;
            s1.channelData[1][i++] = -100;
            s1.channelData[1][i++] = -200;
            s1.channelData[1][i++] = -300;
            s1.channelData[1][i++] = -400;

			// ADDED FOR SW3 to write to mem
			s1.invalidateSampleMemory();
			s1.commitChannelData(); 
       }
    }
}