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


package
{    
    import com.noteflight.standingwave3.elements.SampleTest;
    import com.noteflight.standingwave3.filters.CacheFilterTest;
    import com.noteflight.standingwave3.filters.EnvelopeFilterTest;
    import com.noteflight.standingwave3.filters.ResamplingFilterTest;
    import com.noteflight.standingwave3.performance.AudioPerformerTest;
    import com.noteflight.standingwave3.performance.ListPerformanceTest;
    import com.noteflight.standingwave3.performance.PerformanceElementTest;
    
    import flexunit.framework.TestSuite;
    
    public class StandingwaveTestSuite
    {
        public static function suite() : TestSuite
        {
            var testSuite:TestSuite = new TestSuite();

            testSuite.addTestSuite( SampleTest );
            testSuite.addTestSuite( PerformanceElementTest );
            testSuite.addTestSuite( ListPerformanceTest );
            testSuite.addTestSuite( AudioPerformerTest );
            testSuite.addTestSuite( EnvelopeFilterTest );
            testSuite.addTestSuite( CacheFilterTest );
            testSuite.addTestSuite( ResamplingFilterTest );

            return testSuite;
        }
    }
}
