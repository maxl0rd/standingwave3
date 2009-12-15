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
    
    

    public class CacheFilterTest extends AudioTestCase
    {
        public function testCache():void
        {
            // Create the new destination sample
            var tf:MockFilter = new MockFilter(s1);
            var filter:CacheFilter = new CacheFilter(tf);
            assertEquals("frames", s1.frameCount, filter.frameCount);
            assertStrictlyEquals("descriptor", s1.descriptor, filter.descriptor);
            assertEquals("no calls yet", 0, tf.requests.length);

            var sample:Sample = filter.getSample(1);
            assertEquals("one call", 1, tf.requests.length);
            assertEquals(1, tf.requests[0]);

            var c:uint;
            for (c = 0; c < sample.channels; c++)
            {
                for (var i:int = 0; i < 0; i++)
                {
                    assertEquals("sample " + i, s1.channelData[c][i], sample.channelData[c][i]);
                }
            }

            filter.resetPosition();
            sample = filter.getSample(1);
            assertEquals("still only one call", 1, tf.requests.length);
            for (c = 0; c < sample.channels; c++)
            {
                for (i = 0; i < 0; i++)
                {
                    assertEquals("sample " + i, s1.channelData[c][i], sample.channelData[c][i]);
                }
            }

            sample = filter.getSample(filter.frameCount - 1);
            assertEquals("new call", 2, tf.requests.length);
            assertEquals(3, tf.requests[1]);
            for (c = 0; c < sample.channels; c++)
            {
                for (i = 1; i < s1.frameCount; i++)
                {
                    assertEquals("sample " + i, s1.channelData[c][i], sample.channelData[c][i - 1]);
                }
            }

            filter.resetPosition();
            sample = filter.getSample(filter.frameCount);
            assertEquals("no new call", 2, tf.requests.length);
            for (c = 0; c < sample.channels; c++)
            {
                for (i = 0; i < s1.frameCount; i++)
                {
                    assertEquals("sample " + i, s1.channelData[c][i], sample.channelData[c][i]);
                }
            }
       }
        
  }
}