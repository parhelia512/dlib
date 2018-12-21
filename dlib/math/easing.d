/*
Copyright (c) 2018 Timur Gafarov

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

module dlib.math.easing;

import dlib.math.interpolation;
   
T easeInQuad(T)(T t)
{
    return t * t;
}
    
T easeOutQuad(T)(T t)
{
    return -t * (t - 2);
}

T easeInOutQuad(T)(T t)
{
    t /= 0.5;
    if (t < 1.0)
        return 0.5 * t * t;
    t--;
    return -0.5 * (t * (t - 2.0) - 1.0);
}
    
T easeInBack(T)(T t)
{
    enum T s = 1.70158;
    return t * t * ((s + 1) * t - s);
}
    
T easeOutBack(T)(T t)
{
    enum T s = 1.70158;
    t = t - 1.0;
    return (t * t * ((s + 1) * t + s) + 1.0);
}

T easeInOutBack(T)(T t)
{
    float s = 1.70158;
    t /= 0.5;
    if (t < 1.0)
    {
        s *= 1.525;
        return 0.5 * (t * t * ((s + 1.0) * t - s));
    }
    t -= 2.0;
    s *= 1.525;
    return 0.5 * (t * t * ((s + 1.0) * t + s) + 2.0);
}

T easeOutBounce(T)(T t)
{
    if (t < (1.0 / 2.75))
    {
        return (7.5625 * t * t);
    }
    else if (t < (2.0 / 2.75))
    {
        t -= (1.5 / 2.75);
        return (7.5625 * (t) * t + 0.75);
    }
    else if (t < (2.5 / 2.75))
    {
        t -= (2.25 / 2.75);
        return (7.5625 * (t) * t + 0.9375);
    }
    else
    {
        t -= (2.625 / 2.75);
        return (7.5625 * (t) * t + 0.984375);
    }
}
