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
 * Singly linked list
 *
 * Copyright: Timur Gafarov 2011-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov, Andrey Penechko, Roman Chistokhodov, ijet
 */
module dlib.container.linkedlist;

import dlib.core.memory;

/**
 * Element of single linked list.
 */
struct LinkedListElement(T)
{
    LinkedListElement!(T)* next = null;
    T datum;

    this(LinkedListElement!(T)* n)
    {
        next = n;
        datum = T.init;
    }
}

/**
 * GC-free single linked list implementation.
 */
struct LinkedList(T, bool ordered = true)
{
    ///Head of the list.
    LinkedListElement!(T)* head = null;
    
    ///Tail of the list.
    LinkedListElement!(T)* tail = null;
    
    ///Number of elements in the list.
    size_t length = 0;

    /**
     * Check if list has no elements.
     */
    @property bool empty()
    {
        return length == 0;
    }

    ///
    unittest
    {
        LinkedList!int list;
        assert(list.empty);
    }

    /**
     * Remove all elements and free used memory.
     */
    void free()
    {
        LinkedListElement!(T)* element = head;
        while (element !is null)
        {
            auto e = element;
            element = element.next;
            Delete(e);
        }
        head = null;
        tail = null;
        length = 0;
    }

    /**
     * Iterating over list via foreach.
     */
    int opApply(scope int delegate(size_t, ref T) dg)
    {
        int result = 0;
        uint index = 0;

        LinkedListElement!(T)* element = head;
        while (element !is null)
        {
            result = dg(index, element.datum);
            if (result)
                break;
            element = element.next;
            index++;
        }

        return result;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        list.append(1);
        list.append(2);
        list.append(3);
        list.append(4);

        int[4] values;

        foreach(size_t i, ref int val; list) {
            values[i] = val;
        }

        assert(values[] == [1,2,3,4]);
    }

    /**
     * Iterating over list via foreach.
     */
    int opApply(scope int delegate(ref T) dg)
    {
        int result = 0;

        LinkedListElement!(T)* element = head;
        while (element !is null)
        {
            result = dg(element.datum);
            if (result)
                break;
            element = element.next;
        }

        return result;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        list.append(1);
        list.append(2);
        list.append(3);
        list.append(4);

        int[] values;

        foreach(ref int val; list) {
            values ~= val;
        }

        assert(values[] == [1,2,3,4]);
    }

    /**
     * Appen value v to the end.
     * Returns: Pointer to added list element.
     */
    LinkedListElement!(T)* insertBack(T v)
    {
        length++;

        if (tail is null)
        {
            tail = New!(LinkedListElement!(T))(null);
            tail.datum = v;
        }
        else
        {
            tail.next = New!(LinkedListElement!(T))(null);
            tail.next.datum = v;
            tail = tail.next;
        }

        if (head is null) head = tail;

        return tail;
    }

    // Insert operator
    auto opCatAssign(T v)
    {
        insertBack(v);
        return this;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        auto element = list.append(13);
        assert(element.datum == 13);
        assert(list.length == 1);
        element = list.append(42);
        assert(element.datum == 42);
        assert(list.length == 2);
    }

    /**
     * Insert value v after element.
     * Returns: Pointer to inserted element.
     * Note: element must be not null.
     */
    LinkedListElement!(T)* insertAfter(LinkedListElement!(T)* element, T v)
    {
        length++;
        auto newElement = New!(LinkedListElement!(T))(null);
        newElement.datum = v;
        newElement.next = element.next;
        element.next = newElement;
        if (element is tail) tail = newElement;
        return newElement;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        auto first = list.append(1);
        auto last = list.append(2);
        list.insertAfter(first, 3);

        assert(list.length == 3);
        auto arr = list.toArray();
        assert(arr == [1,3,2]);
        Delete(arr);
    }

    /**
     * Insert value v at the beginning.
     */
    LinkedListElement!(T)* insertFront(T v)
    {
        length++;
        auto newElement = New!(LinkedListElement!(T))(null);
        newElement.datum = v;
        newElement.next = head;
        head = newElement;
        if (tail is null) {
            tail = head;
        }
        return newElement;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        list.insertBeginning(1);
        list.insertBack(2);
        list.insertBeginning(0);

        import std.algorithm : equal;
        assert(equal(list.byElement(), [0,1,2]));
    }

    /**
     * Remove value after element.
     * Note: element must be not null.
     */
    void removeAfter(LinkedListElement!(T)* element)
    {
        length--;
        auto obsolete = element.next;
        if (obsolete !is null)
        {
            if (obsolete is tail) tail = element;
            element.next = obsolete.next;
            Delete(obsolete);
        }
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        auto first = list.insertBack(1);
        auto second = list.insertBack(2);
        auto third = list.insertBack(3);
        list.removeAfter(first);

        import std.algorithm : equal;
        assert(equal(list.byElement(), [1,3]));
    }

    /**
     * Remove the first element.
     * Note: list must be non-empty.
     */
    void removeFront()
    {
        length--;
        auto obsolete = head;
        if (obsolete !is null)
        {
            head = obsolete.next;
            Delete(obsolete);
        }
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        list.insertBack(0);
        list.removeFront();
        assert(list.length == 0);

        list.insertBack(1);
        list.insertBack(2);
        list.insertBack(3);
        list.removeFront();
        assert(list.length == 2);
        import std.algorithm : equal;
        assert(equal(list.byElement(), [2,3]));
    }

    /**
     * Append other list.
     * Note: Appended list should not be freed. It becomes part of this list.
     */
    void appendList(LinkedList!(T) list)
    {
        length += list.length;
        if (tail !is null) {
            tail.next = list.head;
        }
        if (head is null) {
            head = list.head;
        }
        tail = list.tail;
    }

    ///
    unittest
    {
        LinkedList!int list1;
        scope(exit) list1.free();
        LinkedList!int list2;
        LinkedList!int list3;

        list2.insertBack(1);
        list2.insertBack(2);

        list1.appendList(list2);

        import std.algorithm : equal;
        assert(equal(list1.byElement(), [1,2]));

        list3.insertBack(3);
        list3.insertBack(4);
        list1.appendList(list3);

        assert(equal(list1.byElement(), [1,2,3,4]));
    }

    /**
     * Search for element with value v.
     * Returns: Found element or null if could not find.
     */
    LinkedListElement!(T)* find(T v)
    {
        LinkedListElement!(T)* element = head;
        LinkedListElement!(T)* prevElement = head;
        while (element !is null)
        {
            if (element.datum == v)
            {
                static if (!ordered)
                {
                   /*
                    * Move-to-front heuristic:
                    * Move an element to the beginning of the list once it is found.
                    * This scheme ensures that the most recently used items are also
                    * the quickest to find again.
                    */
                    prevElement.next = element.next;
                    element.next = head;
                    head = element;
                }

                return element;
            }

            prevElement = element;
            element = element.next;
        }

        return null;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        assert(list.find(42) is null);

        list.insertBack(13);
        list.insertBack(42);

        auto first = list.find(13);
        assert(first && first.datum == 13);

        auto second = list.find(42);
        assert(second && second.datum == 42);

        assert(list.find(0) is null);
    }

    /**
     * Convert to array.
     */
    T[] toArray()
    {
        T[] arr = New!(T[])(length);
        foreach(i, v; this)
            arr[i] = v;
        return arr;
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        list.insertBack(1);
        list.insertBack(2);
        list.insertBack(3);

        auto arr = list.toArray();
        assert(arr == [1,2,3]);
        Delete(arr);
    }

    auto byElement()
    {
        struct ByElement
        {
        private:
            LinkedListElement!(T)* _first;

        public:
            @property bool empty() {
                return _first is null;
            }

            @property T front() {
                return _first.datum;
            }

            void popFront() {
                _first = _first.next;
            }

            auto save() {
                return this;
            }
        }

        return ByElement(head);
    }

    ///
    unittest
    {
        LinkedList!int list;
        scope(exit) list.free();

        assert(list.byElement().empty);

        list.insertBack(1);
        list.insertBack(2);
        list.insertBack(3);

        auto range = list.byElement();
        import std.range: isInputRange;
        import std.algorithm: equal;
        static assert(isInputRange!(typeof(range)));

        assert(equal(range, [1, 2, 3]));

        range = list.byElement();
        auto saved = range.save();
        range.popFront();
        assert(equal(range, [2, 3]));
        assert(equal(saved, [1, 2, 3]));
    }

    // For backward compatibility
    alias append = insertBack;
    alias insertBeginning = insertFront;
    alias removeBeginning = removeFront;
    alias search = find;
}
