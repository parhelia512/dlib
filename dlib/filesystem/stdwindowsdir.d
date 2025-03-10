/*
Copyright (c) 2016-2025 Timur Gafarov

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

module dlib.filesystem.stdwindowsdir;

import std.string;
import std.conv;
import std.range;
import core.stdc.string;
import core.stdc.wchar_;

version(Windows)
{
    import core.sys.windows.windows;
}

import dlib.core.memory;
import dlib.filesystem.filesystem;
import dlib.text.utf16;

version(Windows):

string unmanagedStrFromCStrW(wchar* cstr)
{
    return cast(string)convertUTF16ztoUTF8(cstr);
}

class StdWindowsDirEntryRange: InputRange!(DirEntry)
{
    HANDLE hFind = INVALID_HANDLE_VALUE;
    WIN32_FIND_DATAW findData;
    DirEntry frontEntry;
    bool _empty = false;
    wchar* path;
    bool initialized = false;

    this(wchar* cwstr)
    {
        this.path = cwstr;
    }

    ~this()
    {
        if (frontEntry.name.length)
            Delete(frontEntry.name);

        close();
    }

    import std.stdio;

    bool advance()
    {
        bool success = false;

        if (frontEntry.name.length)
            Delete(frontEntry.name);

        if (!initialized)
        {
            hFind = FindFirstFileW(path, &findData);
            initialized = true;
            if (hFind != INVALID_HANDLE_VALUE)
                success = true;

            string name = unmanagedStrFromCStrW(findData.cFileName.ptr);
            if (name == "." || name == "..")
            {
                success = false;
                Delete(name);
            }
            else
            {
                bool isDir = cast(bool)(findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY);
                bool isFile = !isDir;
                frontEntry = DirEntry(name, isFile, isDir);
            }
        }

        if (!success && hFind != INVALID_HANDLE_VALUE)
        {
            string name;
            while(!success)
            {
                auto r = FindNextFileW(hFind, &findData);
                if (!r)
                    break;

                name = unmanagedStrFromCStrW(findData.cFileName.ptr);
                if (name != "." && name != "..")
                    success = true;
                else
                    Delete(name);
            }

            if (success)
            {
                bool isDir = cast(bool)(findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY);
                bool isFile = !isDir;
                frontEntry = DirEntry(name, isFile, isDir);
            }
        }

        if (!success)
        {
            FindClose(hFind);
            hFind = INVALID_HANDLE_VALUE;
        }

        return success;
    }

    override DirEntry front()
    {
        return frontEntry;
    }

    override void popFront()
    {
        _empty = !advance();
    }

    override DirEntry moveFront()
    {
        _empty = !advance();
        return frontEntry;
    }

    override bool empty()
    {
        return _empty;
    }

    int opApply(scope int delegate(DirEntry) dg)
    {
        int result = 0;

        for (size_t i = 0; !empty; i++)
        {
            popFront();
            if (!empty())
                result = dg(frontEntry);

            if (result != 0)
                break;
        }

        return result;
    }

    int opApply(scope int delegate(size_t, DirEntry) dg)
    {
        int result = 0;

        for (size_t i = 0; !empty; i++)
        {
            popFront();
            if (!empty())
                result = dg(i, frontEntry);

            if (result != 0)
                break;
        }

        return result;
    }

    void reset()
    {
        close();
    }

    void close()
    {
        if (hFind != INVALID_HANDLE_VALUE)
        {
            FindClose(hFind);
            hFind = INVALID_HANDLE_VALUE;
        }
        initialized = false;
        _empty = false;
    }
}

class StdWindowsDirectory: Directory
{
    StdWindowsDirEntryRange drange;
    wchar* path;

    this(wchar* cwstr)
    {
        path = cwstr;
        drange = New!StdWindowsDirEntryRange(path);
    }

    void close()
    {
        drange.close();
    }

    StdWindowsDirEntryRange contents()
    {
        if (drange)
            drange.reset();
        return drange;
    }

    ~this()
    {
        Delete(drange);
        drange = null;
        Delete(path);
    }
}
