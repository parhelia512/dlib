/*
Copyright (c) 2015-2025 Timur Gafarov

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
 * Binary search tree
 *
 * Copyright: Timur Gafarov 2015-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov, Andrey Penechko
 */
module dlib.container.bst;

import dlib.core.memory;

/**
 * GC-free binary search tree implementation.
 */
class BST(T)
{
    bool root;
    BST left = null;
    BST right = null;
    int key = 0;

    T value;

    this()
    {
        root = true;
    }

    this(int k, T v)
    {
        key = k;
        value = v;
        root = false;
    }

    ~this()
    {
        clear();
    }

    void insert(int k, T v)
    {
        if (k < key)
        {
            if (left is null) left = allocate!(BST)(k, v);
            else left.insert(k, v);
        }
        else if (k > key)
        {
            if (right is null) right = allocate!(BST)(k, v);
            else right.insert(k, v);
        }
        else value = v;
    }

    BST find(int k)
    {
        if (k < key)
        {
            if (left !is null) return left.find(k);
            else return null;
        }
        else if (k > key)
        {
            if (right !is null) return right.find(k);
            else return null;
        }
        else return this;
    }

    protected BST findLeftMost()
    {
        if (left is null) return this;
        else return left.findLeftMost();
    }

    void remove(int k, BST par = null)
    {
        if (k < key)
        {
            if (left !is null) left.remove(k, this);
            else return;
        }
        else if (k > key)
        {
            if (right !is null) right.remove(k, this);
            else return;
        }
        else
        {
            if (left !is null && right !is null)
            {
                auto m = right.findLeftMost();
                key = m.key;
                value = m.value;
                right.remove(key, this);
            }
            else if (this == par.left)
            {
                par.left = (left !is null)? left : right;
            }
            else if (this == par.right)
            {
                par.right = (left !is null)? left : right;
            }
        }
    }

    void traverse(void function(int, T) func)
    {
        if (left !is null)
            left.traverse(func);
        if (!root)
            func(key, value);
        if (right !is null)
            right.traverse(func);
    }

    int opApply(scope int delegate(int, ref T) dg)
    {
        int result = 0;

        if (left !is null)
        {
            result = left.opApply(dg);
            if (result)
                return result;
        }

        if (!root)
            dg(key, value);

        if (right !is null)
        {
            result = right.opApply(dg);
            if (result)
                return result;
        }

        return result;
    }

    void clear()
    {
        if (left !is null)
        {
            left.clear();
            deallocate(left);
            left = null;
        }
        if (right !is null)
        {
            right.clear();
            deallocate(right);
            right = null;
        }
    }
}
