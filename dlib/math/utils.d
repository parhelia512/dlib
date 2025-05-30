/*
Copyright (c) 2011-2025 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

/**
 * Utility math functions
 *
 * Copyright: Timur Gafarov 2011-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.math.utils;

private
{
    import core.stdc.stdlib;
    import std.math;
}

public:

/**
 * Very small value
 */
enum EPSILON = 0.000001;

/**
 * Axes of Cartesian space
 */
enum Axis
{
    x = 0, y = 1, z = 2
}

/**
 * Convert degrees to radians
 */
T degtorad(T) (T angle) nothrow
{
    return (angle / 180.0) * PI;
}

/**
 * Convert radians to degrees
 */
T radtodeg(T) (T angle) nothrow
{
    return (angle / PI) * 180.0;
}

/**
 * Convert radians to revolutions
 */
T radtorev(T)(T angle) nothrow
{
    return angle / (2.0 * PI);
}

/**
 * Convert revolutions to radians
 */
T revtorad(T)(angle) nothrow
{
    return angle * (2.0 * PI);
}

/**
 * Find maximum of two values
 */
T max2(T) (T x, T y) nothrow
{
    return (x > y)? x : y;
}

///
unittest
{
    assert(max2(2, 1) == 2);
}

/**
 * Find minimum of two values
 */
T min2(T) (T x, T y) nothrow
{
    return (x < y)? x : y;
}

///
unittest
{
    assert(min2(2, 1) == 1);
}

/**
 * Find maximum of three values
 */
T max3(T) (T x, T y, T z) nothrow
{
    T temp = (x > y)? x : y;
    return (temp > z) ? temp : z;
}

///
unittest
{
    assert(max3(3, 2, 1) == 3);
}

/**
 * Find minimum of three values
 */
T min3(T) (T x, T y, T z) nothrow
{
    T temp = (x < y)? x : y;
    return (temp < z) ? temp : z;
}

///
unittest
{
    assert(min3(3, 2, 1) == 1);
}

/**
 * Limit to given range
 */
static if (__traits(compiles, (){import std.algorithm: clamp;}))
{
    public import std.algorithm: clamp;
}
else
{
    T clamp(T) (T v, T minimal, T maximal) nothrow
    {
        if (v > minimal)
        {
            if (v < maximal) return v;
                else return maximal;
        }
        else return minimal;
    }
}

/**
 * Is less than EPSILON
 */
bool isConsiderZero(T) (T f) nothrow
{
    return (abs(f) < EPSILON);
}

/**
 * Is power of 2
 */
bool isPowerOfTwo(T)(T x) nothrow
{
    return (x != 0) && ((x & (x - 1)) == 0);
}

///
unittest
{
    assert(isPowerOfTwo(16));
    assert(!isPowerOfTwo(20));
}

/**
 * Round to next power of 2
 */
T nextPowerOfTwo(T) (T k) nothrow
{
    if (k == 0)
        return 1;
    k--;
    for (T i = 1; i < T.sizeof * 8; i <<= 1)
        k = k | k >> i;
    return k + 1;
}

///
unittest
{
    assert(nextPowerOfTwo(0) == 1);
    assert(nextPowerOfTwo(5) == 8);
}

/**
 * Round to next power of 10
 */
T nextPowerOfTen(T) (T k) nothrow
{
    return pow(10, cast(int)ceil(log10(k)));
}

///
unittest
{
    assert(nextPowerOfTen!double(80) == 100);
}

/**
 * If at least one element is zero
 */
bool oneOfIsZero(T) (T[] array...) nothrow
{
    foreach(i, v; array)
        if (v == 0) return true;
    return false;
}

/**
 * Byte operations
 */
version (BigEndian)
{
    ushort bigEndian(ushort value) nothrow
    {
        return value;
    }
    
    ///
    unittest
    {
        assert(bigEndian(cast(ushort)0x00FF) == 0x00FF);
    }

    uint bigEndian(uint value) nothrow
    {
        return value;
    }

    ///
    unittest
    {
        assert(bigEndian(cast(uint)0x000000FF) == cast(uint)0x000000FF);
    }

    ushort networkByteOrder(ushort value) nothrow
    {
        return value;
    }

    ///
    unittest
    {
        assert(networkByteOrder(cast(ushort)0x00FF) == 0x00FF);
    }

    uint networkByteOrder(uint value) nothrow
    {
        return value;
    }

    ///
    unittest
    {
        assert(networkByteOrder(cast(uint)0x000000FF) == cast(uint)0x000000FF);
    }
}

version (LittleEndian)
{
    ushort bigEndian(ushort value) nothrow
    {
        return ((value & 0xFF) << 8) | ((value >> 8) & 0xFF);
    }

    ///
    unittest
    {
        assert(bigEndian(cast(ushort)0x00FF) == 0xFF00);
    }

    uint bigEndian(uint value) nothrow
    {
        return value << 24
            | (value & 0x0000FF00) << 8
            | (value & 0x00FF0000) >> 8
            |  value >> 24;
    }

    ///
    unittest
    {
        assert(bigEndian(cast(uint)0x000000FF) == cast(uint)0xFF000000);
    }

    ushort networkByteOrder(ushort value) nothrow
    {
        return bigEndian(value);
    }

    ///
    unittest
    {
        assert(networkByteOrder(cast(ushort)0x00FF) == 0xFF00);
    }

    uint networkByteOrder(uint value) nothrow
    {
        return bigEndian(value);
    }

    ///
    unittest
    {
        assert(networkByteOrder(cast(uint)0x000000FF) == cast(uint)0xFF000000);
    }
}

/**
 * Returns 16-bit integer n with swapped endianness
 */
T swapEndian16(T)(T n)
{
    return cast(T)((n >> 8) | (n << 8));
}

///
unittest
{
    assert(swapEndian16(cast(ushort)0xFF00) == 0x00FF);
}

/**
 * Constructs uint from an array of bytes
 */
uint bytesToUint(ubyte[4] src) nothrow
{
    return (src[0] << 24 | src[1] << 16 | src[2] << 8 | src[3]);
}

///
unittest
{
    assert(bytesToUint([0xee, 0x10, 0xab, 0xff]) == 0xee10abff);
}

/**
 * Field of view angle Y from X
 */
T fovYfromX(T) (T xfov, T aspectRatio) nothrow
{
    xfov = degtorad(xfov);
    T yfov = 2.0 * atan(tan(xfov * 0.5)/aspectRatio);
    return radtodeg(yfov);
}

/**
 * Field of view angle X from Y
 */
T fovXfromY(T) (T yfov, T aspectRatio) nothrow
{
    yfov = degtorad(yfov);
    T xfov = 2.0 * atan(tan(yfov * 0.5) * aspectRatio);
    return radtodeg(xfov);
}

/**
 * Sign of a number
 */
int sign(T)(T x) nothrow
{
    return (x > 0) - (x < 0);
}

/**
 * Swap values
 */
void swap(T)(T* a, T* b)
{
    T c = *a;
    *a = *b;
    *b = c;
}

/**
 * Is perfect square
 */
bool isPerfectSquare(float n) nothrow
{
    float r = sqrt(n);
    return(r * r == n);
}

///
unittest
{
    assert(isPerfectSquare(64.0f));
}

/**
 * Integer part
 */
real integer(real v)
{
    real ipart;
    modf(v, ipart);
    return ipart;
}

///
unittest
{
    assert(integer(54.832f) == 54.0f);
}

/**
 * Fractional part
 */
real frac(real v)
{
    real ipart;
    return modf(v, ipart);
}

///
unittest
{
    assert(abs(frac(54.832f) - 0.832f) <= EPSILON);
}
