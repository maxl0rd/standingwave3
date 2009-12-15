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


package com.noteflight.standingwave2.performance
{
    import com.noteflight.standingwave2.elements.AudioTestCase;
        
    public class PerformanceElementTest extends AudioTestCase
    {
        public function testSource():void
        {
            var p:PerformanceElement = new PerformanceElement(10 / 22050.0, s1);
            assertEquals("source", s1, p.source);
            assertEquals("start", 10, p.start);
            assertEquals("end", 10 + s1.frameCount, p.end);
            assertEquals("startTime", 10 / 22050, p.startTime);
            assertEquals("endTime", (10 + s1.frameCount) / 22050, p.endTime);
        }
    }
}