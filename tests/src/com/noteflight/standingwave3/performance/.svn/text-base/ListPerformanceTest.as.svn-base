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
    import __AS3__.vec.Vector;
    
    import com.noteflight.standingwave2.elements.AudioTestCase;
    
    public class ListPerformanceTest extends AudioTestCase
    {
        public function testListPerformance():void
        {
            var p:ListPerformance = new ListPerformance();
            p.addSourceAt(0, s1.clone());
            p.addSourceAt(2 / 22050.0, s1.clone());   // delayed by two samples
            p.addSourceAt(10 / 22050.0, s1.clone());  // delayed by 10 samples

            var result:Vector.<PerformanceElement>;
            
            result = p.getElementsInRange(0, 0);
            assertEquals(0, result.length);
            
            result = p.getElementsInRange(0, 1);
            assertEquals(1, result.length);
            assertEquals(p.elements[0], result[0]);

            // repeated query must work OK
            result = p.getElementsInRange(0, 1);
            assertEquals(1, result.length);
            assertEquals(p.elements[0], result[0]);

            result = p.getElementsInRange(1, 3);
            assertEquals(1, result.length);
            assertEquals(p.elements[1], result[0]);

            result = p.getElementsInRange(2, 3);
            assertEquals(1, result.length);
            assertEquals(p.elements[1], result[0]);

            result = p.getElementsInRange(3, 100);
            assertEquals(1, result.length);
            assertEquals(p.elements[2], result[0]);

            result = p.getElementsInRange(2, 100);
            assertEquals(2, result.length);
            assertEquals(p.elements[1], result[0]);
            assertEquals(p.elements[2], result[1]);
       }
    }
}