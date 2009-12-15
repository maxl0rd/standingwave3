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
    import __AS3__.vec.Vector;
    import com.noteflight.standingwave3.utils.AudioUtils;
    import com.noteflight.standingwave3.elements.*
    
    /**
     * EnvelopeFilter applies a so-called ADSR (attack/decay/sustain/release) amplitude envelope to its
     * underlying source, to provide a shape to a sound source that typically has no amplitude envelope. 
     * 
     * NOTE this is the original StandingWave 2 ADSR implementation which is retained
     * mainly for its educational value. You can make much faster ADSRs in SW3 by using the
     * EnvelopeGenerator and AmpFilter pattern.
     */
    public class EnvelopeFilter extends AbstractFilter
    {
        /** The duration of the attack envelope in frames. */
        public var attack:Number;
        
        /** The duration of the decay envelope in frames. */
        public var decay:Number;
        
        /** The sustain level of the envelope, expressed as a multiplying factor. */
        public var sustain:Number;
        
        /** The duration of the hold phase of the element in frames. */
        public var hold:Number;
        
        /** The release duration for the envelope, in frames. */
        public var release:Number;
        
        /** current gain */
        private var _currentGain:Number = 0;
        
        /**
         * Create a new EnvelopeFilter. 
         * @param source the underlying audio source
         * @param attackTime the time of the attack phase of the envelope, during which it rises linearly from zero
         * to unity (if decayTime is nonzero) or to the sustain level (if decayTime is zero).
         * @param decayTime the time of the decay phase of the envelope, during which it decays exponentially from
         * unity to the sustain level.
         * @param sustain the gain factor for the sustain level.
         * @param holdTime the time for which the sustain level is maintained
         * @param releaseTime the time of the release phase, during which the envelope decays exponentially from
         * the sustain level to a near-zero factor.
         */
        public function EnvelopeFilter(source:IAudioSource, attackTime:Number, decayTime:Number, sustain:Number, holdTime:Number, releaseTime:Number)
        {
            super(source);
            this.attack = Math.floor(attackTime * source.descriptor.rate);
            this.decay = Math.floor(decayTime * source.descriptor.rate);
            this.sustain = sustain;
            this.hold = Math.floor(holdTime * source.descriptor.rate);
            this.release = Math.floor(releaseTime * source.descriptor.rate);
        }
                
        /**
         * Return the length of this source, which is in effect gated by the overall
         * length of the envelope.
         */
        override public function get frameCount():Number
        {
            return Math.min(super.frameCount, attack + decay + hold + release);
        }

        override public function resetPosition():void
        {
            super.resetPosition();
            if (attack == 0)
            {
                if (decay == 0)
                {
                    _currentGain = sustain;
                }
                else
                {
                    _currentGain = 1;
                }
            }
            else
            {
                _currentGain = 0;
            }
        }
        
        override public function getSample(numFrames:Number):Sample
        {
            var startPos:Number = position;
            var sample:Sample = _source.getSample(numFrames);
            var startGain:Number = _currentGain;
            
            for (var c:Number = 0; c < sample.channels; c++)
            {
                _currentGain = startGain;
                var data:Vector.<Number> = sample.channelData[c];
                var index:Number = 0;
                var i:Number = startPos;
                var endOffset:Number = startPos + numFrames;
            
                var phaseEnd:Number = Math.min(endOffset, attack);
                var attackLevel:Number = (decay > 0) ? 1.0 : sustain;
                var attackIncrement:Number = attackLevel / attack;
                while (i < phaseEnd)
                {
                    data[index++] *= _currentGain;
                    i++;
                    _currentGain += attackIncrement;
                }
            
                phaseEnd = Math.min(endOffset, phaseEnd + decay);
                var decayFactor:Number = Math.exp(Math.log(sustain) / decay);
                while (i < phaseEnd)
                {
                    data[index++] *= _currentGain;
                    i++;
                    _currentGain *= decayFactor;
                }

                phaseEnd = Math.min(endOffset, phaseEnd + hold);
                if (sustain < 1.0)
                {
                    while (i < phaseEnd)
                    {
                        data[index++] *= _currentGain;
                        i++;
                    }
                }
                else if (i < phaseEnd)
                {
                    index += phaseEnd - i;
                    i = phaseEnd;
                }

                phaseEnd = Math.min(endOffset, phaseEnd + release);
                var releaseFactor:Number = Math.exp(Math.log(AudioUtils.MINIMUM_SIGNAL / sustain) / release);
                while (i < phaseEnd)
                {
                    data[index++] *= _currentGain;
                    i++;
                    _currentGain *= releaseFactor;
                }
            }
			sample.invalidateSampleMemory();
            return sample;
        }

        override public function clone():IAudioSource
        {
            return new EnvelopeFilter(source.clone(), attack / descriptor.rate, decay / descriptor.rate, sustain, hold / descriptor.rate, release / descriptor.rate);
        }
    }
}
