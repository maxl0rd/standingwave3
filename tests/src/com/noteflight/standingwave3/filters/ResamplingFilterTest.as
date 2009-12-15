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


package com.noteflight.standingwave3.filters
{
    import com.noteflight.standingwave3.elements.AudioTestCase;
    import com.noteflight.standingwave3.elements.Sample;
    
    

    public class ResamplingFilterTest extends AudioTestCase
    {
        public function testFrequencyShiftUp():void
        {
            // Create the new destination sample
            var filter:ResamplingFilter = new ResamplingFilter(s1, 1.5);
            var sample:Sample = filter.getSampleRange(0, filter.frameCount);
            assertEquals("frames", 3, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(500, sample.channelData[0][1]);
            assertEquals(-250, sample.channelData[1][1]);
            assertEquals(800, sample.channelData[0][2]);
            assertEquals(-400, sample.channelData[1][2]);

            filter = new ResamplingFilter(s1, 1.49);
            sample = filter.getSampleRange(0, filter.frameCount);
            assertEquals("frames", 3, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(498, sample.channelData[0][1]);
            assertEquals(-249, sample.channelData[1][1]);
            assertEquals(796, sample.channelData[0][2]);
            assertEquals(-398, sample.channelData[1][2]);

            filter = new ResamplingFilter(s1, 1.51);
            sample = filter.getSampleRange(0, filter.frameCount);
            assertEquals("frames", 2, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(502, sample.channelData[0][1]);
            assertEquals(-251, sample.channelData[1][1]);
        }
        
        public function testFrequencyShiftContinuity():void
        {
            var f:ResamplingFilter = new ResamplingFilter(s1, 0.714);
            var sample1:Sample = f.getSampleRange(0, 3);
            var sample2:Sample = f.getSampleRange(1, 5);
            for (var c:uint = 0; c < s1.channels; c++)
            {
                for (var i:int = 1; i < 3; i++)
                {
                    assertEquals("sample " + i, sample1.channelData[c][i], sample2.channelData[c][i-1]);
                }
            }
            
        }
        public function testFrequencyShiftDown():void
        {
            // Create the new destination sample
            var filter:ResamplingFilter = new ResamplingFilter(s1, 0.5); 
            var sample:Sample = filter.getSampleRange(0, filter.frameCount);
            assertEquals("frames", 7, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(300, sample.channelData[0][1]);
            assertEquals(-150, sample.channelData[1][1]);
            assertEquals(800, sample.channelData[0][6]);
            assertEquals(-400, sample.channelData[1][6]);

            filter = new ResamplingFilter(s1, 0.49);
            sample = filter.getSampleRange(0, filter.frameCount);
            assertEquals("frames", 7, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(298, sample.channelData[0][1]);
            assertEquals(-149, sample.channelData[1][1]);
            assertEquals(788, sample.channelData[0][6]);
            assertEquals(-394, sample.channelData[1][6]);
            
            filter = new ResamplingFilter(s1, 0.51);
            sample = filter.getSampleRange(0, filter.frameCount);
            assertEquals("frames", 6, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(302, sample.channelData[0][1]);
            assertEquals(-151, sample.channelData[1][1]);
            assertEquals(710, sample.channelData[0][5]);
            assertEquals(-355, sample.channelData[1][5]);
        }
   }
}