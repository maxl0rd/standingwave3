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


package com.noteflight.standingwave2.elements
{
    import flexunit.framework.TestCase;

    public class SampleTest extends AudioTestCase
    {
        public function testSampleBasics():void
        {
            assertEquals("length", 4, s1.channelData[0].length);
            assertEquals("length", 4, s1.channelData[1].length);
            assertEquals("frame count", 4, s1.frameCount);
            assertEquals("stereo duration", 4.0/22050, s1.duration);
        }
        
        public function testGetChannelSample():void
        {
            assertEquals(200, s1.getChannelSample(0,0));
            assertEquals(-100, s1.getChannelSample(1,0));
            assertEquals(800, s1.getChannelSample(0,3));
            assertEquals(-400, s1.getChannelSample(1,3));
        }
        
        public function testGetInterpolatedSample():void
        {
            assertEquals(200, s1.getInterpolatedSample(0,0));
            assertEquals(-100, s1.getInterpolatedSample(1,0));
            assertEquals(220, s1.getInterpolatedSample(0,0.1));
            assertEquals(-190, s1.getInterpolatedSample(1,0.9));
        }
         
        public function testClear():void
        {
            s1.clear();

            assertEquals(0, s1.getChannelSample(0,0));
            assertEquals(0, s1.getChannelSample(1,0));
            assertEquals(0, s1.getChannelSample(0,3));
            assertEquals(0, s1.getChannelSample(1,3));
        }
         
        /**
         * Return a sample that is a slice of this sample, from frame startOffset(inclusive)
         * to endOffset(exclusive).
         */
        public function testGetSample():void
        { 
            s1.resetPosition();
            s1.getSample(1);  // advance one frame
            
            var sample:Sample = s1.getSample(2);            
            assertEquals("frames", 2, sample.frameCount);
            for (var c:Number = 0; c < sample.channels; c++)
            {
                for (var i:Number = 0; i < 2; i++)
                {
                    assertEquals("sample " + i, s1.channelData[c][i+1], sample.channelData[c][i]);
                }
            }
            s1.resetPosition();
            sample = s1.getSample(s1.frameCount);
            for (c = 0; c < sample.channels; c++)
            {
                for (i = 0; i < 4; i++)
                {
                    assertEquals("sample " + i, s1.channelData[c][i], sample.channelData[c][i]);
                }
            }
        }
    }
}