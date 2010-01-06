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
    /**
     * An object that provides continuously variable, real-time, 
     * or slowly moving signals to another implements IModulationSource.
     * The object serves up its signal in tiny spline segments of 1024 samples each.
     * The lower-level operators use a cubic spline interpolation algorithm
     * to create a continuous signal that is applied to the modulation target.
     */
    public interface IModulationSource
    {
        /**
         * Return a Mod object representing a spline segment of the
         * modulation signal beginning at this point in time.
         *  
         * @param position the starting point of the range (inclusive)
         * @returns a mod object describing the modulation segment
         */
        function getMod(position:Number):Mod;
        
    }
}