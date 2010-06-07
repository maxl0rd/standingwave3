////////////////////////////////////////////////////////////////////////////////
//
//  NOTEFLIGHT LLC
//  Copyright 2010 Noteflight LLC
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

package com.noteflight.standingwave3.modulation
{
    
    /**
    * An IModulationData represents a source of continuously changing control data.
    * It is represented by any number of keyframes that can be added to the data at any point
    *  typically by an IPerformableModulation.
    */
    public interface IModulationData
    {
        
        /** The sample rate for the concrete modulation data */
        function get rate():uint; 
        
        /** Add a point to the modulation data  */
        function addKeyframe(kf:ModulationKeyframe):void;
        
        /** Return the value of the modulation data at the specififed position */
        function getValueAtPosition(position:Number):Number;
        
        /** Return an array of keyframes for the specified range.
        * Keyframes represent discontinuous points in the modulation that require a new Mod. */
        function getKeyframes(fromOffset:Number=0, toOffset:Number=-1):Array;
        
        /** Return a Mod for the specified range */
        function getModForRange(fromOffset:Number, toOffset:Number):Mod; 
        
    }

}