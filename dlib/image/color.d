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
 * RGBA color space
 *
 * Copyright: Timur Gafarov 2011-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.image.color;

import dlib.math.vector;
import dlib.math.utils;

/// RGBA color channel
enum Channel
{
    R = 0,
    G = 1,
    B = 2,
    A = 3
}

/// RGBA 16-bit integer color representation (a vector of ushorts)
alias Color4 = Vector!(ushort, 4);

/// ditto
alias ColorRGBA = Color4;

Color4 invert(Color4 c)
{
    return Color4(
        cast(ushort)(255 - c.r),
        cast(ushort)(255 - c.g),
        cast(ushort)(255 - c.b),
        c.a);
}

/**
 * RGBA floating-point color representation,
 * encapsulates Vector4f
 */
struct Color4f
{
    Vector4f vec;
    alias vec this;

    this(Color4 c, uint bitDepth = 8)
    {
        float maxv = (2 ^^ bitDepth) - 1;
        vec.r = c.r / maxv;
        vec.g = c.g / maxv;
        vec.b = c.b / maxv;
        vec.a = c.a / maxv;
    }

    this(Color4f c)
    {
        vec = c.vec;
    }

    this(Vector4f v)
    {
        vec = v;
    }

    this(Vector3f v)
    {
        vec = Vector4f(v.x, v.y, v.z, 1.0f);
    }

    this(float cr, float cg, float cb, float ca = 1.0f)
    {
        vec = Vector4f(cr, cg, cb, ca);
    }

    static Color4f zero()
    {
        return Color4f(0.0f, 0.0f, 0.0f, 0.0f);
    }

    Color4f opAssign(Color4f c)
    {
        vec = c.vec;
        return this;
    }

    Color4f opBinary(string op)(float x) if (op == "+")
    {
        return Color4f(this.vec + x);
    }

    Color4f opBinary(string op)(float x) if (op == "-")
    {
        return Color4f(this.vec - x);
    }

    Color4f opBinary(string op)(float x) if (op == "*")
    {
        return Color4f(this.vec * x);
    }

    Color4f opBinary(string op)(float x) if (op == "/")
    {
        return Color4f(this.vec / x);
    }

    Color4f opBinary(string op)(Vector4f v) if (op == "+")
    {
        return Color4f(this.vec + v);
    }

    Color4f opBinary(string op)(Vector4f v) if (op == "-")
    {
        return Color4f(this.vec - v);
    }

    Color4f opBinary(string op)(Vector4f v) if (op == "*")
    {
        return Color4f(this.vec * v);
    }

    Color4f opBinary(string op)(Vector4f v) if (op == "/")
    {
        return Color4f(this.vec / v);
    }

    Color4 convert(int bitDepth)
    {
        float maxv = (2 ^^ bitDepth) - 1;
        return Color4(
            cast(ushort)(r.clamp(0.0f, 1.0f) * maxv),
            cast(ushort)(g.clamp(0.0f, 1.0f) * maxv),
            cast(ushort)(b.clamp(0.0f, 1.0f) * maxv),
            cast(ushort)(a.clamp(0.0f, 1.0f) * maxv)
        );
    }

    int opCmp(ref const(Color4f) c) const
    {
        return cast(int)((luminance() - c.luminance()) * 100);
    }

    alias luminance = luminance709;

    // ITU-R Rec. BT.709
    float luminance709() const
    {
        return (
            vec.arrayof[0] * 0.2126f +
            vec.arrayof[1] * 0.7152f +
            vec.arrayof[2] * 0.0722f
        );
    }

    // ITU-R Rec. BT.601
    float luminance601() const
    {
        return (
            vec.arrayof[0] * 0.3f +
            vec.arrayof[1] * 0.59f +
            vec.arrayof[2] * 0.11f
        );
    }

    @property Color4f inverse()
    {
        return Color4f(
            1.0f - vec.r,
            1.0f - vec.g,
            1.0f - vec.b,
            vec.a);
    }

    @property Color4f clamped(float minv, float maxv)
    {
        return Color4f(
            vec.r.clamp(minv, maxv),
            vec.g.clamp(minv, maxv),
            vec.b.clamp(minv, maxv),
            vec.a.clamp(minv, maxv)
        );
    }

    /// Converts color from gamma space to linear space
    Color4f toLinear(float gamma = 2.2f)
    {
        float lr = r ^^ gamma;
        float lg = g ^^ gamma;
        float lb = b ^^ gamma;
        return Color4f(lr, lg, lb, a);
    }

    /// Converts color from linear space to gamma space
    Color4f toGamma(float gamma = 2.2f)
    {
        float invGamma = 1.0f / gamma;
        float lr = r ^^ invGamma;
        float lg = g ^^ invGamma;
        float lb = b ^^ invGamma;
        return Color4f(lr, lg, lb, a);
    }
}

/// ditto
alias ColorRGBAf = Color4f;

///
unittest
{
    Color4f c1 = Color4f(0.5f, 0.5f, 0.5f, 1.0f);
    assert(isConsiderZero(c1.luminance - 0.5f));
    assert(isConsiderZero(c1.luminance601 - 0.5f));
    
    Color4f c2 = Color4f(1.0f, 0.0f, 0.0f, 1.0f);
    assert(isAlmostZero(c2.inverse - Color4f(0.0f, 1.0f, 1.0f, 1.0f)));
}

/// Encode a normal vector to color
Color4f packNormal(Vector3f n)
{
    return Color4f((n + 1.0f) * 0.5f);
}

/// 24-bit integer color unpacking
Color4f color3(int hex)
{
    ubyte r = (hex >> 16) & 255;
    ubyte g = (hex >> 8) & 255;
    ubyte b = hex & 255;
    return Color4f(
        cast(float)r / 255.0f,
        cast(float)g / 255.0f,
        cast(float)b / 255.0f);
}

///
unittest
{
    assert(color3(0xff0000) == Color4f(1.0f, 0.0f, 0.0f, 1.0f));
}

/// 32-bit integer color unpacking
Color4f color4(int hex)
{
    ubyte r = (hex >> 24) & 255;
    ubyte g = (hex >> 16) & 255;
    ubyte b = (hex >> 8) & 255;
    ubyte a = hex & 255;
    return Color4f(
        cast(float)r / 255.0f,
        cast(float)g / 255.0f,
        cast(float)b / 255.0f,
        cast(float)a / 255.0f);
}

///
unittest
{
    assert(color4(0xff000000) == Color4f(1.0f, 0.0f, 0.0f, 0.0f));
}

/// Blend two colors taking transparency into account
Color4f alphaOver(Color4f c1, Color4f c2)
{
    Color4f c;
    float a = c2.a + c1.a * (1.0f - c2.a);

    if (a == 0.0f)
        c = Color4f(0, 0, 0, 0);
    else
    {
        c = (c2 * c2.a + c1 * c1.a * (1.0f - c2.a)) / a;
        c.a = a;
    }

    return c;
}

/**
 * Is all elements almost zero
 */
bool isAlmostZero(Color4f c)
{
    return (isConsiderZero(c.r) &&
            isConsiderZero(c.g) &&
            isConsiderZero(c.b) &&
            isConsiderZero(c.a));
}
