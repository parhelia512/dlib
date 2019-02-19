/*
Copyright (c) 2014-2017 Martin Cejp

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

module dlib.filesystem.local;

import std.array;
import std.conv;
import std.datetime;
import std.path;
import std.range;
import std.stdio;
import std.string;

import dlib.core.stream;
import dlib.filesystem.filesystem;
import dlib.filesystem.dirrange;

version (Posix)
{
    import dlib.filesystem.posix.common;
    import dlib.filesystem.posix.directory;
    import dlib.filesystem.posix.file;
}
else version (Windows)
{
    import dlib.filesystem.windows.common;
    import dlib.filesystem.windows.directory;
    import dlib.filesystem.windows.file;
}

// TODO: Should probably check for FILE_ATTRIBUTE_REPARSE_POINT before recursing

/// LocalFileSystem
class LocalFileSystem : FileSystem
{
    override InputStream openForInput(string filename)
    {
        return cast(InputStream) openFile(filename, read, 0);
    }

    override OutputStream openForOutput(string filename, uint creationFlags)
    {
        return cast(OutputStream) openFile(filename, write, creationFlags);
    }

    override IOStream openForIO(string filename, uint creationFlags)
    {
        return openFile(filename, read | write, creationFlags);
    }

    override bool createDir(string path, bool recursive)
    {
        import std.algorithm;

        if (recursive)
        {
            ptrdiff_t index = max(path.lastIndexOf('/'), path.lastIndexOf('\\'));

            if (index != -1)
                createDir(path[0..index], true);
        }

        version(Posix)
        {
            return mkdir(toStringz(path), access_0755) == 0;
        }
        else version (Windows)
        {
            return CreateDirectoryW(toUTF16z(path), null) != 0;
        }
        else
            throw new Exception("Not implemented.");
    }

    override Directory openDir(string path)
    {
        version(Posix)
        {
            DIR* d = opendir(!path.empty ? toStringz(path) : ".");

            if (d == null)
                return null;
            else
                return new PosixDirectory(this, d, !path.empty ? path ~ "/" : "");
        }
        else version(Windows)
        {
            string npath = !path.empty ? buildNormalizedPath(path) : ".";
            DWORD attributes = GetFileAttributesW(toUTF16z(npath));

            if (attributes == INVALID_FILE_ATTRIBUTES)
                return null;

            if (attributes & FILE_ATTRIBUTE_DIRECTORY)
                return new WindowsDirectory(this, npath, !path.empty ? path ~ "/" : "");
            else
                return null;
        }
        else
            throw new Exception("Not implemented.");
    }

    override bool stat(string path, out FileStat stat_out)
    {
        version(Posix)
        {
            stat_t st;

            if (stat_(toStringz(path), &st) != 0)
                return false;

            stat_out.isFile = S_ISREG(st.st_mode);
            stat_out.isDirectory = S_ISDIR(st.st_mode);

            stat_out.sizeInBytes = st.st_size;
            stat_out.creationTimestamp = SysTime(unixTimeToStdTime(st.st_ctime));
            auto modificationStdTime = unixTimeToStdTime(st.st_mtime);
            static if (is(typeof(st.st_mtimensec)))
            {
                modificationStdTime += st.st_mtimensec / 100;
            }
            stat_out.modificationTimestamp = SysTime(modificationStdTime);

            if ((st.st_mode & S_IRUSR) | (st.st_mode & S_IRGRP) | (st.st_mode & S_IROTH))
                stat_out.permissions |= PRead;
            if ((st.st_mode & S_IWUSR) | (st.st_mode & S_IWGRP) | (st.st_mode & S_IWOTH))
                stat_out.permissions |= PWrite;
            if ((st.st_mode & S_IXUSR) | (st.st_mode & S_IXGRP) | (st.st_mode & S_IXOTH))
                stat_out.permissions |= PExecute;

            return true;
        }
        else version(Windows)
        {
            WIN32_FILE_ATTRIBUTE_DATA data;
            
            auto p = toUTF16z(path);

            if (!GetFileAttributesExW(p, GET_FILEEX_INFO_LEVELS.GetFileExInfoStandard, &data))
                return false;

            if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                stat_out.isDirectory = true;
            else
                stat_out.isFile = true;

            stat_out.sizeInBytes = (cast(FileSize) data.nFileSizeHigh << 32) | data.nFileSizeLow;
            stat_out.creationTimestamp = SysTime(FILETIMEToStdTime(&data.ftCreationTime));
            stat_out.modificationTimestamp = SysTime(FILETIMEToStdTime(&data.ftLastWriteTime));
            
            stat_out.permissions = 0;
            
            PACL pacl;
            PSECURITY_DESCRIPTOR secDesc;
            TRUSTEE_W trustee;
            trustee.pMultipleTrustee = null;
            trustee.MultipleTrusteeOperation = MULTIPLE_TRUSTEE_OPERATION.NO_MULTIPLE_TRUSTEE;
            trustee.TrusteeForm = TRUSTEE_FORM.TRUSTEE_IS_NAME;
            trustee.TrusteeType = TRUSTEE_TYPE.TRUSTEE_IS_UNKNOWN;
            trustee.ptstrName = cast(wchar*)"CURRENT_USER"w.ptr;
            GetNamedSecurityInfoW(cast(wchar*)p, SE_OBJECT_TYPE.SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, null, null, &pacl, null, &secDesc);
            if (pacl)
            {
                uint access;
                GetEffectiveRightsFromAcl(pacl, &trustee, &access);
                
                if (access & ACTRL_FILE_READ)
                    stat_out.permissions |= PRead;
                if ((access & ACTRL_FILE_WRITE) && !(data.dwFileAttributes & FILE_ATTRIBUTE_READONLY))
                    stat_out.permissions |= PWrite;
                if (access & ACTRL_FILE_EXECUTE)
                    stat_out.permissions |= PExecute;
            }

            return true;
        }
        else
            throw new Exception("Not implemented.");
    }

    /*
    override bool move(string path, string newPath)
    {
        // TODO: should we allow newPath to actually be a directory?

        return rename(toStringz(path), toStringz(newPath)) == 0;
    }
    */

    override bool remove(string path, bool recursive)
    {
        FileStat stat;

        if (!this.stat(path, stat))
            return false;

        return remove(path, stat.isDirectory, recursive);
    }

   private:
    version(Posix)
    {
        enum access_0644 = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
        enum access_0755 = S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH;
    }

    IOStream openFile(string filename, uint accessFlags, uint creationFlags)
    {
        // TODO: Windows implementation

        version(Posix)
        {
            int flags;

            switch (accessFlags & (read | write))
            {
                case read: flags = O_RDONLY; break;
                case write: flags = O_WRONLY; break;
                case read | write: flags = O_RDWR; break;
                default: flags = 0;
            }

            if (creationFlags & FileSystem.create)
                flags |= O_CREAT;

            if (creationFlags & FileSystem.truncate)
                flags |= O_TRUNC;

            int fd = open(toStringz(filename), flags, access_0644);

            if (fd < 0)
                return null;
            else
                return new PosixFile(fd, accessFlags);
        }
        else version(Windows)
        {
            DWORD access = 0;

            if (accessFlags & read)
                access |= GENERIC_READ;

            if (accessFlags & write)
                access |= GENERIC_WRITE;

            DWORD creationMode;

            final switch (creationFlags & (create | truncate))
            {
                case 0: creationMode = OPEN_EXISTING; break;
                case create: creationMode = OPEN_ALWAYS; break;
                case truncate: creationMode = TRUNCATE_EXISTING; break;
                case create | truncate: creationMode = CREATE_ALWAYS; break;
            }

            HANDLE file = CreateFileW(toUTF16z(filename), access, FILE_SHARE_READ, null, creationMode,
                FILE_ATTRIBUTE_NORMAL, null);

            if (file == INVALID_HANDLE_VALUE)
                return null;
            else
                return new WindowsFile(file, accessFlags);
        }
        else
            throw new Exception("Not implemented.");
    }

    bool remove(string path, bool isDirectory, bool recursive)
    {
        // TODO: Windows implementation

        if (isDirectory && recursive)
        {
            // Remove contents
            auto dir = openDir(path);

            try
            {
                foreach (entry; dir.contents)
                    remove(path ~ "/" ~ entry.name, entry.isDirectory, recursive);
            }
            finally
            {
                dir.close();
            }
        }

        version(Posix)
        {
            if (isDirectory)
                return rmdir(toStringz(path)) == 0;
            else
                return std.stdio.remove(toStringz(path)) == 0;
        }
        else version(Windows)
        {
            if (isDirectory)
                return RemoveDirectoryW(toUTF16z(path)) != 0;
            else
                return DeleteFileW(toUTF16z(path)) != 0;
        }
        else
            throw new Exception("Not implemented.");
    }
}

private ReadOnlyFileSystem rofs;
private FileSystem fs;

static this()
{
    // decouple dependency from the rest of this module
    import dlib.filesystem.local;

    setFileSystem(new LocalFileSystem);
}

void setFileSystem(FileSystem fs_)
{
    rofs = fs_;
    fs = fs_;
}

void setFileSystemReadOnly(ReadOnlyFileSystem rofs_)
{
    rofs = rofs_;
    fs = null;
}

// ReadOnlyFileSystem

bool stat(string filename, out FileStat stat)
{
    return rofs.stat(filename, stat);
}

InputStream openForInput(string filename)
{
    InputStream ins = rofs.openForInput(filename);

    if (ins is null)
        throw new Exception("Failed to open '" ~ filename ~ "'");

    return ins;
}

Directory openDir(string path)
{
    return rofs.openDir(path);
}

InputRange!DirEntry findFiles(string baseDir, bool recursive)
{
    return dlib.filesystem.filesystem.findFiles(rofs, baseDir, recursive);
}

// FileSystem

OutputStream openForOutput(string filename, uint creationFlags = FileSystem.create | FileSystem.truncate)
{
    OutputStream outs = fs.openForOutput(filename, creationFlags);

    if (outs is null)
        throw new Exception("Failed to open '" ~ filename ~ "' for writing");

    return outs;
}

IOStream openForIO(string filename, uint creationFlags)
{
    IOStream ios = fs.openForIO(filename, creationFlags);

    if (ios is null)
        throw new Exception("Failed to open '" ~ filename ~ "' for writing");

    return ios;
}

bool createDir(string path, bool recursive)
{
    return fs.createDir(path, recursive);
}

/*
bool move(string path, string newPath)
{
    return fs.move(path, newPath);
}
*/

bool remove(string path, bool recursive)
{
    return fs.remove(path, recursive);
}

unittest
{
    // TODO: test >4GiB files

    import std.algorithm;
    import std.file;

    alias remove = dlib.filesystem.local.remove;

    remove("tests/test_data", true);
    assert(openDir("tests/test_data") is null);

    assert(createDir("tests/test_data/main", true));

    enum dir = "tests";
    auto d = openDir(dir);

    try
    {
        chdir(dir);
        auto expected = dirEntries("", SpanMode.shallow)
                                  .filter!(e => e.isFile)
                                  .array;
        size_t i;
        chdir("..");

        foreach (entry; d.contents)
        {
            if (entry.isFile)
            {
                assert(expected[i] == entry.name);
                ++i;
            }
        }
    }
    finally
    {
        d.close();
    }

    //
    OutputStream outp = openForOutput("tests/test_data/main/hello_world.txt", FileSystem.create | FileSystem.truncate);
    string expected = "Hello, World!\n";
    assert(outp);

    try
    {
        assert(outp.writeArray(expected));
    }
    finally
    {
        outp.close();
    }

    //
    InputStream inp = openForInput("tests/test_data/main/hello_world.txt");
    assert(inp);

    try
    {
        while (inp.readable)
        {
            char[1] buffer;

            auto have = inp.readBytes(buffer.ptr, buffer.length);
            assert(buffer[0..have] == expected[0..have]);
            expected.popFrontN(have);
        }
    }
    finally
    {
        inp.close();
    }
}

unittest
{
    import std.algorithm;
    import std.file;

    auto expected = dirEntries("", SpanMode.depth)
                              .filter!(e => e.isFile)
                              .filter!(e => e.name.baseName.endsWith(".d"))
                              .map!(e => e.name.replace("\\", "/"))
                              .array;
    size_t i;

    foreach (entry; findFiles("", true)
            .filter!(entry => entry.isFile)
            .filter!(e => e.name.baseName.globMatch("*.d")))
    {
        FileStat stat_;
        assert(stat(entry.name, stat_)); // make sure we're getting the expected path
        assert(expected[i] == entry.name);
        assert(stat_.sizeInBytes == expected[i].getSize());

        SysTime modificationTime, accessTime;
        expected[i].getTimes(accessTime, modificationTime);
        assert(modificationTime ==  stat_.modificationTimestamp);

        ++i;
    }
}
