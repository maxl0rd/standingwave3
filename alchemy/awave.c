/*
 *  awave.c
 *  Part of Standing Wave 3
 *  Alchemy <-> AS3 Bridge for audio synthesis 
 *
 *  maxlord@gmail.com
 *
 */

/**
 * AlchemicalWave is the Alchemy CLib of StandingWave. It is accessed through the Sample element.
 * Every Sample in Standing Wave has corresponding sample memory allocated by this lib.
 * 
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "AS3.h"
 
float pi    = 3.1415926535897932384626433832795029;
float twopi = 6.2831853071795864769252867665590058;
char trace[100];

// A *large* lookup table for midi note number to frequency conversion
// 64 steps for each of the 128 midi note numbers, large enough to not interpolate
float noteToFreqLookup[8192]; 

// Another *large* lookup table for db to amplitude factor conversion
// Goes from -128 to +128 db, which is kind of ridiculous, but
//  provides 32 steps per db which probably enables us to do without interpolation
float dbToPowerLookup[8192];

// Scratch buffers for random stuff
float scratch1[16384];
float scratch2[16384];
float scratch3[16384];
float scratch4[16384];

static inline float interpolate(float sample1, float sample2, float fraction) {
	return sample1 + fraction * (sample2-sample1);
}

// We use splines for modulation shapes, typically ~ 1 point per 1024k buffer
// These are temporarily expanded into scratch memory and run continuous modulations

/* Cubic spline interpolation */
static inline float cubicInterpolate( float y0, float y1, float y2, float y3, float mu) {
   float a0,a1,a2,a3,mu2;
   mu2 = mu*mu;
   a0 = y3 - y2 - y0 + y1;
   a1 = y0 - y1 - a0;
   a2 = y2 - y0;
   a3 = y1;
   return(a0*mu*mu2+a1*mu2+a2*mu+a3);
}
 
/* Expand a spline segment into a buffer */
static int expandSpline(AS3_Val *modPoint, float *buffer, int frames) 
{
	double y0Arg, y1Arg, y2Arg, y3Arg;
	float y0, y1, y2, y3;
	float p, incr;
	int count;
	AS3_ObjectValue(*modPoint, "y0:DoubleType, y1:DoubleType, y2:DoubleType, y3:DoubleType", &y0Arg, &y1Arg, &y2Arg, &y3Arg);
	y0 = (float) y0Arg;
	y1 = (float) y1Arg;
	y2 = (float) y2Arg;
	y3 = (float) y3Arg;
	incr = 1 / (float) frames;
	count = frames;
	p = 0;
	// Optimize continuous, linear, and cubic modes
	if (y0 == y1 && y1 == y2 && y2 == y3) {
		// All values are the same
		while (count--) {
			*buffer++ = y1;
		}
	} else if (y0 == y1 && y2 == y3) {
		// Linear interpolation
		while (count--) {
			*buffer++ = interpolate(y1, y2, p);
			p += incr;
		}
	} else {
		// This is a full spline segment
		// Loop over the whole segment and calc instantaneous spline values with cubic interpolation
		while (count--) {
			*buffer++ = cubicInterpolate(y0, y1, y2, y3, p);
			p += incr;
		}
	}
	return 0;
} 

/* Returns a frequency in Hz for a midi note number */
static inline float noteToFreq(float note) {
	return noteToFreqLookup[ (int)(note*64) ];
}

/* Returns an amplitude factor for a decibel gain number (from -128db to +128 db) */
static inline float dbToPower(float dbGain) {
	return dbToPowerLookup[ (int)(dbGain*32) + 4096 ];
}

/* Returns a frequency shift factor from a semitone shift number -- ie. +12 semitones = 2x frequency */
static inline float shiftToFreq(float shift) {
	// Yea, obscurity zone
	return noteToFreqLookup[ (int)((69+shift)*64) ] * .00227273;
}
 
 
/**
 * Returns a pointer to the memory allocated for this sample.
 * Every frame value is a float, as Flash's native sound format is a 32bit float
 *  and we don't want to waste time converting back and forth to doubles.
 * The sample is zeroed.
 * Stereo samples are interleaved.
 */ 
static AS3_Val allocateSampleMemory(void* self, AS3_Val args)
{
	int frames;
	int channels;
	int size;
	float *buffer;
	
	AS3_ArrayValue(args, "IntType, IntType", &frames, &channels);
 
	size = frames * channels * sizeof(float);
	buffer = (float *) malloc(size); 
	memset(buffer, 0, size);
	
	// Return the sample pointer
	return AS3_Int((int)buffer);  
}

/**
 * Increases the memory allocation for this sample pointer
 */
static AS3_Val reallocateSampleMemory(void* self, AS3_Val args)
{
	int newframes;
	int oldframes;
	int channels;
	int newsize;
	int oldsize;
	float *buffer;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType", &oldframes, &newframes, &channels);
 
	oldsize = oldframes * channels * sizeof(float);
	newsize = newframes * channels * sizeof(float);
	
	// realloc is slow :(
	buffer = (float *) realloc(buffer, newsize); 
	
	// zero out the new memory 
	memset( buffer + oldframes*channels, 0, newsize - oldsize);
	
	// Return the new sample pointer
	return AS3_Int((int)buffer);  
}
 
/**
 * Frees the memory associated with this sample pointer
 */ 
static AS3_Val deallocateSampleMemory(void *self, AS3_Val args)
{
	float *buffer;
	int bufferPosition;
	AS3_ArrayValue(args, "IntType", &bufferPosition);
	buffer = (float *) bufferPosition;
	free(buffer);
	buffer = 0;
	return 0;
} 
 
/**
 * Fast sample memory copy between sample pointers
 */
 static AS3_Val copy(void *self, AS3_Val args) 
{
	int bufferPosition; int channels; int frames;
	float *buffer;
	int sourceBufferPosition;
	float *sourceBuffer;
	int type;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &bufferPosition, &sourceBufferPosition, &channels, &frames, &type);
	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition;
	
	memcpy(buffer, sourceBuffer, frames * channels * sizeof(float));
	return 0;
} 
 
/**
 * Converts a Sample at a lower rate (22050 Hz) or lower number of channels (mono)
 *  to the standard Flash sound format (44.1k stereo interleaved).
 * The descriptor in this case represents the sourceBuffer, not the targetBuffer, which is stereo/44.1
 */
static AS3_Val standardize(void *self, AS3_Val args) 
{
	int bufferPosition; int rate; int channels; int frames;
	float *buffer;
	int sourceBufferPosition;
	float *sourceBuffer;
	int count;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &bufferPosition, &sourceBufferPosition, &channels, &frames, &rate);
	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition;

	if (rate == 44100 && channels == 2) {
		// We're already standardized. Just copy the memory
		memcpy(buffer, sourceBuffer, frames * channels * sizeof(float));
	} else if (rate == 22050 && channels == 1) {
		// Upsample and stereoize with cubic interpolation
		// First set hold first sample
		*buffer++ = *sourceBuffer;
		*buffer++ = *sourceBuffer;
		*buffer++ = cubicInterpolate(*(sourceBuffer), *(sourceBuffer), *(sourceBuffer+1), *(sourceBuffer+2), 0.5); 
		*buffer = *(buffer-1);
		buffer++; sourceBuffer++;
		// Loop
		count = (frames/2) - 2;
		while (--count) {
			*buffer++ = *sourceBuffer;
			*buffer++ = *sourceBuffer;
			*buffer++ = cubicInterpolate(*(sourceBuffer-1), *sourceBuffer, *(sourceBuffer+1), *(sourceBuffer+2), 0.5); 
			*buffer = *(buffer-1);
			buffer++; sourceBuffer++;
		}		
		// Last set hold 2 samples
		*buffer++ = *sourceBuffer;
		*buffer++ = *sourceBuffer;
		*buffer++ = cubicInterpolate(*(sourceBuffer-1), *sourceBuffer, *(sourceBuffer+1), *(sourceBuffer+1), 0.5); 
		*buffer = *(buffer-1);
		buffer++; sourceBuffer++;
		*buffer++ = *sourceBuffer;
		*buffer++ = *sourceBuffer;
		*buffer++ = cubicInterpolate(*(sourceBuffer-1), *sourceBuffer, *sourceBuffer, *sourceBuffer, 0.5); 
		*buffer = *(buffer-1);
		// Done
	} else if (rate == 22050 && channels == 2) {
		// Upsample with cubic interpolation 
		// First set hold sample
		*buffer++ = *sourceBuffer;
		*buffer++ = *(sourceBuffer+1);
		*buffer++ = cubicInterpolate(*sourceBuffer, *sourceBuffer, *(sourceBuffer+2), *(sourceBuffer+4), 0.5); 
		*buffer = cubicInterpolate(*(sourceBuffer+1), *(sourceBuffer+1), *(sourceBuffer+3), *(sourceBuffer+5), 0.5); 
		buffer++;
		sourceBuffer += 2;
		count = frames/2 - 2;
		while (--count) {
			*buffer++ = *sourceBuffer; // left
			*buffer++ = *(sourceBuffer+1); // right
			*buffer++ = cubicInterpolate(*(sourceBuffer-2), *sourceBuffer, *(sourceBuffer+2), *(sourceBuffer+4), 0.5); 
			*buffer++ = cubicInterpolate(*(sourceBuffer-1), *(sourceBuffer+1), *(sourceBuffer+3), *(sourceBuffer+5), 0.5);
			sourceBuffer += 2;
		}
		// second to last set		
		*buffer++ = *sourceBuffer; // left
		*buffer++ = *(sourceBuffer+1); // right
		*buffer++ = cubicInterpolate(*(sourceBuffer-2), *sourceBuffer, *(sourceBuffer+2), *(sourceBuffer+2), 0.5); 
		*buffer++ = cubicInterpolate(*(sourceBuffer-1), *(sourceBuffer+1), *(sourceBuffer+3), *(sourceBuffer+3), 0.5);
		sourceBuffer += 2;
		// last set
		*buffer++ = *sourceBuffer; // left
		*buffer++ = *(sourceBuffer+1); // right
		*buffer++ = cubicInterpolate(*(sourceBuffer-2), *sourceBuffer, *sourceBuffer, *sourceBuffer, 0.5); 
		*buffer= cubicInterpolate(*(sourceBuffer-1), *(sourceBuffer+1), *(sourceBuffer+1), *(sourceBuffer+1), 0.5);
		// Done
	} else if (rate == 44100 && channels == 1) {
		// Stereoize
		count = frames;
		while (--count) {
			*buffer++ = *sourceBuffer;
			*buffer++ = *sourceBuffer++;
		}
	}
	return 0;
}
 
/**
 * Set every sample in the range to a fixed value.
 * Useful for function generators of different types, or erasing audio.
 */ 
static AS3_Val setSamples(void *self, AS3_Val args)
{
	float *buffer; int bufferPosition; int channels; int frames;
	double valueArg; float value;	
	int count;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, DoubleType", &bufferPosition, &channels, &frames, &valueArg);
	buffer = (float *) bufferPosition;
	value = (float) valueArg;
	
	count = frames * channels;
	if (count % 32 == 0) {
		// I love to unroll, love to unroll
		count /= 32;
		while (count--) {
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
			*buffer++ = value;
		}
	} else {
		while (count--) {
			*buffer++ = value;
		}
	}

	return 0;
} 

// Scale all samples
static AS3_Val changeGain(void* self, AS3_Val args)
{
	int bufferPosition; int channels; int frames;
	float *buffer;
	double leftGainArg; double rightGainArg;
	float leftGain; float rightGain;
	int count;
		
	AS3_ArrayValue(args, "IntType, IntType, IntType, DoubleType, DoubleType", &bufferPosition, &channels, &frames, &leftGainArg, &rightGainArg);
	buffer = (float *) bufferPosition;
	leftGain = (float) leftGainArg;
	rightGain = (float) rightGainArg;

	count = frames;
	if (channels == 1) {
		while (count--) {
			*buffer++ *= leftGain; 
		}
	} else if (channels == 2) {
		while (count--) {
			*buffer++ *= leftGain; 
			*buffer++ *= rightGain;
		}
	}
	return 0;
} 

// Mix one buffer into another
static AS3_Val mixIn(void *self, AS3_Val args)
{
	int bufferPosition; int channels; int frames;
	float *buffer;
	int sourceBufferPosition;
	float *sourceBuffer;
	double leftGainArg;
	double rightGainArg;
	float leftGain;
	float rightGain;
	int count;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, DoubleType, DoubleType", 
		&bufferPosition, &sourceBufferPosition, &channels, &frames, &leftGainArg, &rightGainArg);
	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition; // this can be passed with an offset to easily mix offset slices of samples
	leftGain = (float) leftGainArg;
	rightGain = (float) rightGainArg;	
	
	// sprintf(trace, "channels=%d, frames=%d, leftGain=%f, rightGain=%f", channels, frames, leftGain, rightGain);
	// sztrace(trace);
	
	count = frames;
	if (channels == 1) {
		if (count % 32 == 0) {
			// Massive unrolling optimization. Yes, this looks retarded, but it's 3x faster
			count /= 32;
			while (count--) {
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain; 
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain; 
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;
				*buffer++ += *sourceBuffer++ * leftGain;  
			}
		} else {
			while (count--) {
				*buffer++ += *sourceBuffer++ * leftGain; 
			}
		}
	} else if (channels == 2) {
		if (count % 32 == 0) {
			count /= 32;
			while (count--) {
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;

			}
		} else {
			while (count--) {
				*buffer++ += *sourceBuffer++ * leftGain; 		
				*buffer++ += *sourceBuffer++ * rightGain;
			}
		}
	}
	return 0;
}

/**
 * Mix a mono sample into a stereo sample.
 * Buffer is stereo, and source buffer is mono.
 */
static AS3_Val mixInPan(void *self, AS3_Val args)
{
	int bufferPosition;  int frames;
	float *buffer;
	int sourceBufferPosition;
	float *sourceBuffer;
	double leftGainArg;
	double rightGainArg;
	float leftGain;
	float rightGain;
	int count;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, DoubleType, DoubleType", 
		&bufferPosition, &sourceBufferPosition, &frames, &leftGainArg, &rightGainArg);
	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition; 
	leftGain = (float) leftGainArg;
	rightGain = (float) rightGainArg;	
	count = frames;
	
	if (count % 32 == 0) {
		// Again, unroll 32x
		count /= 32;
		while (count--) {
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
		}
	} else {
		while (count--) {
			*buffer++ += *sourceBuffer * leftGain; 		
			*buffer++ += *sourceBuffer++ * rightGain;
		}
	}

	return 0;
}


/**
 * Multiply (Amplitude modulate) one buffer against another
 */
static AS3_Val multiplyIn(void *self, AS3_Val args)
{
	int bufferPosition; int channels; int frames;
	float *buffer;
	int sourceBufferPosition;
	float *sourceBuffer;
	double gainArg;
	float gain;
	int count;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, DoubleType", &bufferPosition, &sourceBufferPosition, &channels, &frames, &gainArg);
	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition; 
	gain = (float) gainArg;
	
	count = frames * channels;
	
	if (count % 32 == 0) {
		// Unrolling this loop 32x dramatically increases performance.
		// This will work with almost all buffer sizes, which should be factors of 2
		count /= 32;
		while (count--) {
			*buffer++ *= *sourceBuffer++ * gain; 
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain; 
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain; 
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain; 
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
			*buffer++ *= *sourceBuffer++ * gain;
		}
	} else {
		while (count--) {
			*buffer++ *= *sourceBuffer++ * gain;
		}
	}
	return 0;
}

/**
 * Scan in a wavetable. Wavetable should be at least one longer than the table size.
 */
static AS3_Val wavetableIn(void *self, AS3_Val args)
{
	AS3_Val settings;
	int bufferPosition; int channels; int frames;
	float *buffer; 
	int sourceBufferPosition;
	float *sourceBuffer;
	double phaseArg; float phase;
	double phaseAddArg; float phaseAdd;
	double phaseResetArg; float phaseReset;
	int tableSize;
	int count; 
	int intPhase;
	float *wavetablePosition;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, AS3ValType", 
		&bufferPosition, &sourceBufferPosition, &channels, &frames, &settings);
	AS3_ObjectValue(settings, "tableSize:IntType, phase:DoubleType, phaseAdd:DoubleType, phaseReset:DoubleType",
		&tableSize, &phaseArg, &phaseAddArg, &phaseResetArg);

	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition; 
	phaseAdd = (float) phaseAddArg * tableSize; // num source frames to add per output frames
	phase = (float) phaseArg * tableSize; // translate into a frame count into the table
	phaseReset = (float) phaseResetArg * tableSize;
		
	// Make sure we got everything right
	// sprintf(trace, "Wavetable size=%d phase=%f phaseAdd=%f", tableSize, phase, phaseAdd);
	// sztrace(trace);	
				
	// phase goes from 0 to tableSize
	count=frames;
	if (channels == 1) {
		while (count--) {
			while (phase >= tableSize) {
				phase -= tableSize; // wrap phase to the loop point
				phase += phaseReset;
			}
			intPhase = (int) phase; // int phase
			wavetablePosition = sourceBuffer + intPhase;
			*buffer++ = interpolate(*wavetablePosition, *(wavetablePosition+1), phase - intPhase);
			phase += phaseAdd; 
		}
	} else if (channels == 2 ) {
		while (count--) {
			while (phase >= tableSize) {
				phase -= tableSize; // wrap phase to the loop point
				phase += phaseReset;
			}
			intPhase = ((int)(phase*0.5))*2; // int phase, round to even frames, for each stereo frame pair
			wavetablePosition = sourceBuffer + intPhase;
			*buffer++ = interpolate(*wavetablePosition, *(wavetablePosition+2), phase - intPhase);
			*buffer++ = interpolate(*(wavetablePosition+1), *(wavetablePosition+3), phase - intPhase);
			phase += phaseAdd;
		}
	}
	
	// Scale back down to a factor, and write the final phase value back to AS3
	phase /= tableSize;
	AS3_Set(settings, AS3_String("phase"), AS3_Number(phase));
	
	return 0;
}

/**
 * Scan in another wavetable with an accessory pitch shift table.
 * Wavetable should be at least one longer than the table size.
 */
static AS3_Val waveModIn(void *self, AS3_Val args)
{
	AS3_Val settings;
	int bufferPosition; int channels; int frames;
	float *buffer; 
	int sourceBufferPosition;
	float *sourceBuffer;
	int pitchTablePosition;
	float *pitchTable;
	double phaseArg; float phase;
	double phaseAddArg; float phaseAdd;
	int tableSize;
	int count; 
	int intPhase;
	float *wavetablePosition;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, AS3ValType", 
		&bufferPosition, &sourceBufferPosition, &channels, &frames, &settings);
	AS3_ObjectValue(settings, "tableSize:IntType, phase:DoubleType, phaseAdd:DoubleType, pitchTable:IntType",
		&tableSize, &phaseArg, &phaseAddArg, &pitchTablePosition);

	buffer = (float *) bufferPosition;
	sourceBuffer = (float *) sourceBufferPosition; 
	pitchTable = (float *) pitchTablePosition; // pitch shift in note numbers per frame
	phaseAdd = (float) phaseAddArg * tableSize; // num source frames to add per output frames
	phase = (float) phaseArg * tableSize; // translate into a frame count into the table
		
	// waveModIn does not loop, so phase does not reset
	count=frames;
	if (channels == 1) {
		while (count--) {
			intPhase = (int) phase; // int phase
			wavetablePosition = sourceBuffer + intPhase;
			*buffer++ = interpolate(*wavetablePosition, *(wavetablePosition+1), phase - intPhase);
			// sprintf(trace, "out=%f", *(buffer-1));
			// sztrace(trace);
			
			// now we have to advance phase by the phaseAdd plus the pitch shift so...
			phase += phaseAdd * shiftToFreq(*pitchTable++); 
		}
	} else if (channels == 2 ) {
		while (count--) {
			intPhase = ((int)(phase*0.5))*2; // int phase, round to even frames, for each stereo frame pair
			wavetablePosition = sourceBuffer + intPhase;
			*buffer++ = interpolate(*wavetablePosition, *(wavetablePosition+2), phase - intPhase);
			*buffer++ = interpolate(*(wavetablePosition+1), *(wavetablePosition+3), phase - intPhase);
			phase += phaseAdd * shiftToFreq(*pitchTable++); 
		}
	}
	
	// Scale back down to a factor, and write the final phase value back to AS3
	phase /= tableSize;
	AS3_Set(settings, AS3_String("phase"), AS3_Number(phase));
	
	return 0;
}


static AS3_Val delay(void *self, AS3_Val args)
{
	int bufferPosition; int channels; int frames; int count; 
	float *buffer; 
	int ringBufferPosition;
	float *ringBuffer;
	AS3_Val settings;
	int length;
	double feedbackArg; float feedback;
	double dryMixArg; float dryMix;
	double wetMixArg; float wetMix;
	int offset = 0;
	float echo;
	float *echoPointer;
	
	// Extract	args
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, AS3ValType", 
	    &bufferPosition, &ringBufferPosition, &channels, &frames,  &settings);
	AS3_ObjectValue(settings, "length:IntType, dryMix:DoubleType, wetMix:DoubleType, feedback:DoubleType",
		&length, &dryMixArg, &wetMixArg, &feedbackArg);
	// Cast arguments to the needed types
	buffer = (float *) bufferPosition;
	ringBuffer = (float *) ringBufferPosition;
	dryMix = (float) dryMixArg;
	wetMix = (float) wetMixArg;
	feedback = (float) feedbackArg;
	
	// Show params
	// sprintf(trace, "Echo length=%d, dry=%f, wet=%f, fb=%f", length, dryMix, wetMix, feedback); 
	// sztrace(trace);
	
	count = frames * channels;
	while (count--) {
		if (offset > length) { 
			offset = 0; 
		}
		echoPointer = ringBuffer + offset;
		echo = *echoPointer;
		*echoPointer = *buffer + echo*feedback;
		*buffer = *buffer * dryMix + echo * wetMix + 1e-15 - 1e-15;
		buffer++; offset++;
	}		
	
	
	// Shift the memory so that the echo pointer offset is the start of the buffer
	
	int ringSize = length * channels * sizeof(float);
	int firstChunkSize = offset * channels * sizeof(float);
	int secondChunkSize = ringSize - firstChunkSize;
	float *temp = (float *) malloc(ringSize);
	
	// copy offset-end -> start of temp buffer	
	memcpy(temp, ringBuffer + offset, secondChunkSize);

	// copy start-offset -> second half of temp buffer
	memcpy(temp + offset, ringBuffer, firstChunkSize);
	
	// copy temp buffer back to ringbuffer
	memcpy(ringBuffer, temp, ringSize); 
	free(temp);
	
	return 0;
	
}

/* biquad(samplePointer, stateBuffer, coefficients, rate, channels, frames) */ 

static AS3_Val biquad(void *self, AS3_Val args)
{
	int bufferPosition;  int channels; int frames; int count; 
	float *buffer; 
	int stateBufferPosition;
	float *stateBuffer;
	
	AS3_Val coeffs; // coefficients object
	double a0d, a1d, a2d, b0d, b1d, b2d; // doubles from object
	float a0, a1, a2, b0, b1, b2; // filter coefficients
	float lx, ly, lx1, lx2, ly1, ly2; // left delay line 
	float rx, ry, rx1, rx2, ry1, ry2; // right delay line 
	
	// Extract args
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, AS3ValType", 
		&bufferPosition, &stateBufferPosition, &channels, &frames, &coeffs);
	buffer = (float *) bufferPosition;
	stateBuffer = (float *) stateBufferPosition;	
		
	// Extract filter coefficients from object	
	AS3_ObjectValue(coeffs, "a0:DoubleType, a1:DoubleType, a2:DoubleType, b0:DoubleType, b1:DoubleType, b2:DoubleType",
		&a0d, &a1d, &a2d, &b0d, &b1d, &b2d);
	// Cast to floats
	a0 = (float) a0d; a1 = (float) a1d; a2 = (float) a2d; 	
	b0 = (float) b0d; b1 = (float) b1d; b2 = (float) b2d; 	

	// Make sure we recieved all the correct coefficients 
	// sprintf(trace, "Biquad a0=%f a1=%f a2=%f b0=%f b1=%f b2=%f", a0, a1, a2, b0, b1, b2);
	// sztrace(trace);
		
	count = frames;

	if (channels == 1) {
		lx1 = *stateBuffer;
		lx2 = *(stateBuffer+1);
		ly1 = *(stateBuffer+2);
		ly2 = *(stateBuffer+3);
		while (count--) {
			lx = *buffer + 1e-15 - 1e-15; // input with denormals zapped
            ly = lx*b0 + lx1*b1 + lx2*b2 - ly1*a1 - ly2*a2;
			lx2 = lx1;
			lx1 = lx;
			ly2 = ly1;
			ly1 = ly;
            *buffer++ = ly; // output
		}
		*stateBuffer = lx1;
		*(stateBuffer+1) = lx2;
		*(stateBuffer+2) = ly1;
		*(stateBuffer+3) = ly2;
	} else if (channels == 2) {
		lx1 = *stateBuffer;
		rx1 = *(stateBuffer+1);
		lx2 = *(stateBuffer+2);
		rx2 = *(stateBuffer+3);
		ly1 = *(stateBuffer+4);
		ry1 = *(stateBuffer+5);
		ly2 = *(stateBuffer+6);
		ry2 = *(stateBuffer+7);
		while (count--) {
			lx = *buffer + 1e-15 - 1e-15; // left input
            ly = lx*b0 + lx1*b1 + lx2*b2 - ly1*a1 - ly2*a2;
			lx2 = lx1;
			lx1 = lx;
			ly2 = ly1;
			ly1 = ly;
            *buffer++ = ly; // left output
			rx = *buffer + 1e-15 - 1e-15; // right input
            ry = rx*b0 + rx1*b1 + rx2*b2 - ry1*a1 - ry2*a2;
			rx2 = rx1;
			rx1 = rx;
			ry2 = ry1;
			ry1 = ry;
            *buffer++ = ry; // right output
		}
		*stateBuffer = lx1;
		*(stateBuffer+1) = rx1;
		*(stateBuffer+2) = lx2;
		*(stateBuffer+3) = rx2;
		*(stateBuffer+4) = ly1;
		*(stateBuffer+5) = ry1;
		*(stateBuffer+6) = ly2;
		*(stateBuffer+7) = ry2;
	}

	return 0;
}

static AS3_Val onePole(void *self, AS3_Val args)
{
	int bufferPosition;  int channels; int frames; int count; 
	float *buffer; 
	
	AS3_Val coeffs; // coefficients object
	AS3_Val state; // object for keeping filter state
	
	double a0d, a1d, b1d; // doubles from object
	float a0, a1, b1; // filter coefficients
	double lxd, lyd, rxd, ryd; // state object
	float lx, ly; // left delay line 
	float rx, ry; // right delay line 
	
	// Extract args
	AS3_ArrayValue(args, "IntType, IntType, IntType, AS3ValType, AS3ValType", 
		&bufferPosition, &channels, &frames, &coeffs, &state);
	buffer = (float *) bufferPosition;
		
	// Extract filter coefficients from object	
	AS3_ObjectValue(coeffs, "a0:DoubleType, a1:DoubleType, b1:DoubleType", &a0d, &a1d, &b1d);
	// Cast to floats
	a0 = (float) a0d; a1 = (float) a1d; b1 = (float) b1d; 	

	// Make sure we recieved all the correct coefficients 
	sprintf(trace, "One pole a0=%f a1=%f b1=%f ", a0, a1, b1);
	sztrace(trace);
		
	// Pull state from state object
	AS3_ObjectValue(state, "lx:DoubleType, ly:DoubleType, rx:DoubleType, ry:DoubleType", &lxd, &lyd, &rxd, &ryd);
	// Cast to floats
	lx = (float) lxd; ly = (float) lyd; rx = (float) rxd; ry = (float) ryd;
	
	// loop
	// the formula is more or less ----- out[n] = in[n]*a0 + in[n-1]*a1 + out[n-1]*b1;
	count = frames;
	
	if (channels == 1) {
		while (count--) {
			ly = *buffer*a0 + lx*a1 + ly*b1;
			lx = *buffer + 1e-15 - 1e-15; // denormals zapped
			// sprintf(trace, "out=%f", ly);
			// sztrace(trace);
			*buffer++ = ly;
			sztrace(trace);
		}
	} else if (channels == 2) {
		while (count--) {
			ly = *buffer*a0 + lx*a1 + ly*b1; 
			lx = *buffer + 1e-15 - 1e-15;
			*buffer++ = ly; // left 
			ry = *buffer*a0 + rx*a1 + ry*b1;
			rx = *buffer + 1e-15 - 1e-15; 
			*buffer++ = ry; // right 
		}
	}
	
	// Push state back to state object
	AS3_Set(state, AS3_String("lx"), AS3_Number(lx));
	AS3_Set(state, AS3_String("ly"), AS3_Number(ly));
	AS3_Set(state, AS3_String("rx"), AS3_Number(rx));
	AS3_Set(state, AS3_String("ry"), AS3_Number(ry));
	
	return 0;
	
}


/**
 * Envelope this sample with a modPoint in dbGain.
 */
static AS3_Val envelope(void *self, AS3_Val args)
{
	int bufferPosition, channels, frames;
	float *buffer; 
	float *scratch;
	AS3_Val modPoint;
	int count; 
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, AS3ValType", &bufferPosition, &channels, &frames, &modPoint);
	buffer = (float *) bufferPosition;
	expandSpline(&modPoint, scratch1, frames); // draws spline segment into scratch1
	scratch = (float *) scratch1;

	count = frames*channels;
	if (count % 8 == 0) 
	{
		count /= 8;
		while (count--)
		{
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
			*buffer++ *= dbToPower(*scratch++);
		}
	} else {
		while (count--) 
		{
			*buffer++ *= dbToPower(*scratch++);
		}
	}
	return 0;
}

/**
 * Saturator stage
 */
static AS3_Val overdrive(void *self, AS3_Val args)
{
	int bufferPosition, channels, frames;
	float *buffer; 
	int count; 
	float x;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType", &bufferPosition, &channels, &frames);
	buffer = (float *) bufferPosition;
	count = frames*channels;
	
	while (count--) {
		x = *buffer;
		if( x < -3 ) {
			*buffer++ = -1.0;
		} else if( x > 3 ) {
			*buffer++ = 1.0;
		} else {
			// Fast tangent-shaped approximation drive curve
			*buffer++ = x * ( 27 + x * x ) / ( 27 + 9 * x * x );
		}
	}
	
	return 0;
}

/**
 * Hard clipper stage
 */
static AS3_Val clip(void *self, AS3_Val args)
{
	int bufferPosition, channels, frames;
	float *buffer; 
	int count; 
	float x;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType", &bufferPosition, &channels, &frames);
	buffer = (float *) bufferPosition;
	count = frames*channels;
	
	while (count--) {
		x = *buffer;
		if( x < -1 ) {
			*buffer++ = -1.0;
		} else if( x > 1 ) {
			*buffer++ = 1.0;
		} else {
			buffer++;
		}
	}
	
	return 0;
}



/**
 * Writes a sample out to an as3 byte array.
 * Used for final output to a sample handler.
 */

static AS3_Val writeBytes(void *self, AS3_Val args) 
{
	int bufferPosition; int channels; int frames;
	float *buffer;
	AS3_Val dst;
	int len;
	
	AS3_ArrayValue(args, "IntType, AS3ValType, IntType, IntType", &bufferPosition, &dst, &channels, &frames);
	buffer = (float *) bufferPosition;
	len = frames * channels * sizeof(float);
	
	AS3_ByteArray_writeBytes(dst, buffer, len);
	return 0;
} 


static int fillNoteLookupTable()
{
	int b;
	float n = 0.0;
	
	for (b=0; b<8192; b++) {
		// Concert A = Note 69 = 440Hz. DEAL
		noteToFreqLookup[b] = (float)(440 * pow(2.0, (n-69)/12));
		n += 0.015625; // 1/64
	}
	return 0;
}

static int fillPowerLookupTable()
{
	int b;
	float ln10div20 = 2.3025850929940459011 / 20;
	float db = -128.0;
	for (b=0; b<8192; b++) {
		// From -128db to +128db in 1/32 db steps
		dbToPowerLookup[b] = exp(db * ln10div20);
		db += .03125; // 1/32
	}
	return 0;
}

int main()
{
	// This method does not free all these strings and AS3 vals, but what-ev!
	// This app uses so much freaking memory anyway :p
	
	AS3_Val result = AS3_Object("");
	AS3_SetS(result, "allocateSampleMemory",  AS3_Function(NULL, allocateSampleMemory) );
	AS3_SetS(result, "reallocateSampleMemory",  AS3_Function(NULL, reallocateSampleMemory) );
	AS3_SetS(result, "deallocateSampleMemory",  AS3_Function(NULL, deallocateSampleMemory) );
	AS3_SetS(result, "setSamples",  AS3_Function(NULL, setSamples) );
	AS3_SetS(result, "copy",  AS3_Function(NULL, copy) );
	AS3_SetS(result, "changeGain",  AS3_Function(NULL, changeGain) );
	AS3_SetS(result, "mixIn",  AS3_Function(NULL, mixIn) );
	AS3_SetS(result, "mixInPan",  AS3_Function(NULL, mixInPan) );
	AS3_SetS(result, "multiplyIn",  AS3_Function(NULL, multiplyIn) );
	AS3_SetS(result, "standardize",  AS3_Function(NULL, standardize) );
	AS3_SetS(result, "wavetableIn",  AS3_Function(NULL, wavetableIn) );
	AS3_SetS(result, "waveModIn",  AS3_Function(NULL, waveModIn) );
	AS3_SetS(result, "delay",  AS3_Function(NULL, delay) );
	AS3_SetS(result, "biquad",  AS3_Function(NULL, biquad) );
	AS3_SetS(result, "writeBytes", AS3_Function(NULL, writeBytes) );
	AS3_SetS(result, "envelope", AS3_Function(NULL, envelope) );
	AS3_SetS(result, "overdrive", AS3_Function(NULL, overdrive) );
	AS3_SetS(result, "clip", AS3_Function(NULL, clip) );
	AS3_SetS(result, "onePole", AS3_Function(NULL, onePole) );
	
	// make our note number to frequency lookup table
	fillNoteLookupTable();
	fillPowerLookupTable();
	
	
	// notify that we initialized -- THIS DOES NOT RETURN!
	AS3_LibInit(result);
 
	return 0;
}