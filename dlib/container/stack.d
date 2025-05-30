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
 * Stack (based on Array)
 *
 * Copyright: Timur Gafarov 2011-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov, Andrey Penechko, Roman Chistokhodov
 */
module dlib.container.stack;

import dlib.container.array;

/**
 * Stack implementation based on Array.
 */
struct Stack(T)
{
    private Array!T array;

    public:
    /**
     * Push element to stack.
     */
    void push(T v)
    {
        array.insertBack(v);
    }

    /**
     * Pop top element out.
     * Returns: Removed element.
     * Throws: Exception on underflow.
     */
    T pop()
    {
        if (empty)
            throw new Exception("Stack!(T): underflow");

        T res = array[$-1];
        array.removeBack(1);
        return res;
    }

    /**
     * Non-throwing version of pop.
     * Returns: true on success, false on failure.
     * Element is stored in value.
     */
    bool pop(ref T value)
    {
        if (empty)
            return false;

        value = array[$-1];
        array.removeBack(1);
        return true;
    }

    /**
     * Top stack element.
     * Note: Stack must be non-empty.
     */
    T top()
    {
        return array[$-1];
    }

    /**
     * Pointer to top stack element.
     * Note: Stack must be non-empty.
     */
    T* topPtr()
    {
        return &array.data[$-1];
    }

    /**
     * Check if stack has no elements.
     */
    @property bool empty() nothrow
    {
        return array.length == 0;
    }

    /**
     * Free memory allocated by Stack.
     */
    void free()
    {
        array.free();
    }
}

///
unittest
{
    import std.exception: assertThrown;

    Stack!int s;
    assertThrown(s.pop());
    s.push(100);
    s.push(3);
    s.push(76);
    assert(s.top() == 76);
    int v;
    s.pop(v);
    assert(v == 76);
    assert(s.pop() == 3);
    assert(s.pop() == 100);
    assert(s.empty);
    s.free();
}
