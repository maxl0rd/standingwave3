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


package com.noteflight.standingwave3.performance
{
    import com.noteflight.standingwave3.elements.AudioTestCase;
    import com.noteflight.standingwave3.elements.Sample;
    
    public class AudioPerformerTest extends AudioTestCase
    {
        public function testAudioPerformer():void
        {
            var p:ListPerformance = new ListPerformance();
            p.addElement(new PerformanceElement(0, s1.clone()));
            p.addElement(new PerformanceElement(2 / 22050.0, s1.clone()));   // delayed by two samples
            p.addElement(new PerformanceElement(10 / 22050.0, s1.clone()));  // delayed by 10 samples

            var ap:AudioPerformer = new AudioPerformer(p);
            assertEquals("rate", 22050, ap.descriptor.rate);
            assertEquals("frameCount", 14, ap.frameCount);
            
            // get full sample
            var sample:Sample = ap.getSample(ap.frameCount);
            assertEquals(14, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(800, sample.channelData[0][2]);
            assertEquals(-400, sample.channelData[1][2]);
            assertEquals(1200, sample.channelData[0][3]);
            assertEquals(-600, sample.channelData[1][3]);

            assertEquals(200, sample.channelData[0][10]);
            assertEquals(-100, sample.channelData[1][10]);
            assertEquals(800, sample.channelData[0][13]);
            assertEquals(-400, sample.channelData[1][13]);

            // get partial sample
            ap.resetPosition();
            sample = ap.getSample(2);
            assertEquals(2, sample.frameCount);
            assertEquals(200, sample.channelData[0][0]);
            assertEquals(-100, sample.channelData[1][0]);
            assertEquals(400, sample.channelData[0][1]);
            assertEquals(-200, sample.channelData[1][1]);

            sample = ap.getSample(2);
            assertEquals(2, sample.frameCount);
            assertEquals(800, sample.channelData[0][0]);
            assertEquals(-400, sample.channelData[1][0]);
            assertEquals(1200, sample.channelData[0][1]);
            assertEquals(-600, sample.channelData[1][1]);

            sample = ap.getSample(2);
            assertEquals(2, sample.frameCount);
            assertEquals(600, sample.channelData[0][0]);
            assertEquals(-300, sample.channelData[1][0]);
            assertEquals(800, sample.channelData[0][1]);
            assertEquals(-400, sample.channelData[1][1]);

            sample = ap.getSample(ap.frameCount - ap.position);
            assertEquals(8, sample.frameCount);
            assertEquals(0, sample.channelData[0][0]);
            assertEquals(0, sample.channelData[1][0]);
            assertEquals(0, sample.channelData[0][1]);
            assertEquals(0, sample.channelData[1][1]);
            assertEquals(200, sample.channelData[0][4]);
            assertEquals(-100, sample.channelData[1][4]);
            assertEquals(400, sample.channelData[0][5]);
            assertEquals(-200, sample.channelData[1][5]);
        }
    }
}