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


package com.noteflight.standingwave2.filters
{
    import __AS3__.vec.Vector;
    
    import com.noteflight.standingwave2.elements.AudioDescriptor;
    import com.noteflight.standingwave2.elements.Sample;
    import com.noteflight.standingwave2.utils.AudioUtils;
    
    import flexunit.framework.TestCase;

    public class EnvelopeFilterTest extends TestCase
    {
        public function testEnvelope():void
        {
            // Create the new destination sample
            var s1:Sample = new Sample(new AudioDescriptor(44010, 1), 100);
            for (var i:Number = 0; i < 100; i++)
            {
                s1.channelData[0][i] = 1;
            }
            
            var envelope:EnvelopeFilter = new EnvelopeFilter(s1, 10/44010, 10/44010, 0.5, 10/44010, 10/44010);
            assertEquals("frames", 40, envelope.frameCount);
            assertStrictlyEquals("descriptor", s1.descriptor, envelope.descriptor);
            
            var data:Vector.<Number> = envelope.getSample(40).channelData[0];
            
            assertEquals("attack midpoint", 0.5, data[5]);
            assertEquals("end of attack", 1000, Math.round(data[10] * 1000));
            assertEquals("decay midpoint", Math.round(1000 * Math.exp(Math.log(0.5) / 2)), Math.round(1000*data[15]));
            assertEquals("start of decay", 0.5, data[20]);
            assertEquals("hold midpoint", 0.5, data[25]);
            assertEquals("start of release", 0.5, data[30]);
            var rm:Number = Math.exp(Math.log(AudioUtils.MINIMUM_SIGNAL / 0.5) / 2.0);
            rm *= 0.5;
            assertEquals("release midpoint", rm, data[35]);

            envelope.resetPosition();
            envelope.getSample(30);
            data = envelope.getSample(10).channelData[0];
            assertEquals("start of release", 0.5, data[0]);
            assertEquals("release midpoint", rm, data[5]);
        }
    }
}