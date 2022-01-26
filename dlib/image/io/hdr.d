/*
Copyright (c) 2016-2022 Timur Gafarov

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
 * Decode and encode Radiance HDR/RGBE images
 *
 * Copyright: Timur Gafarov 2016-2022.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.image.io.hdr;

import std.stdio;
import std.math;
import dlib.core.memory;
import dlib.core.stream;
import dlib.core.compound;
import dlib.container.array;
import dlib.filesystem.local;
import dlib.image.color;
import dlib.image.image;
import dlib.image.hdri;
import dlib.image.io;
import dlib.math.utils;

struct ColorRGBE
{
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte e;
}

ColorRGBE floatToRGBE(Color4f c)
{
    ColorRGBE rgbe;

    float v = c.r;
    if (c.g > v)
        v = c.g;
    if (c.b > v)
        v = c.b;
    if (v < EPSILON)
    {
        rgbe.r = 0;
        rgbe.g = 0;
        rgbe.b = 0;
        rgbe.e = 0;
    }
    else
    {
        int e;
        v = frexp(v, e) * 256.0f / v;
        rgbe.r = cast(ubyte)(c.r * v);
        rgbe.g = cast(ubyte)(c.g * v);
        rgbe.b = cast(ubyte)(c.b * v);
        rgbe.e = cast(ubyte)(e + 128);
    }

    return rgbe;
}

void readLineFromStream(InputStream istrm, ref Array!char line)
{
    char c;
    do
    {
        if (istrm.readable)
            istrm.readBytes(&c, 1);
        else
            break;

        if (c != '\n')
            line.append(c);
    }
    while(c != '\n');
}

class HDRLoadException: ImageLoadException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/**
 * Load HDR from file using local FileSystem.
 * Causes GC allocation
 */
SuperHDRImage loadHDR(string filename)
{
    InputStream input = openForInput(filename);
    ubyte[] data = New!(ubyte[])(input.size);
    input.fillArray(data);
    ArrayStream arrStrm = New!ArrayStream(data);
    auto img = loadHDR(arrStrm);
    Delete(arrStrm);
    Delete(data);
    input.close();
    return img;
}

/**
 * Load HDR from stream using default image factory.
 * Causes GC allocation
 */
SuperHDRImage loadHDR(InputStream istrm)
{
    Compound!(SuperHDRImage, string) res =
        loadHDR(istrm, defaultHDRImageFactory);
    if (res[0] is null)
        throw new HDRLoadException(res[1]);
    else
        return res[0];
}

/**
 * Load HDR from stream using specified image factory.
 * GC-free
 */
Compound!(SuperHDRImage, string) loadHDR(
    InputStream istrm,
    SuperHDRImageFactory imgFac)
{
    SuperHDRImage img = null;

    Compound!(SuperHDRImage, string) error(string errorMsg)
    {
        if (img)
        {
            img.free();
            img = null;
        }
        return compound(img, errorMsg);
    }

    char[11] magic;
    istrm.fillArray(magic);
    if (magic != "#?RADIANCE\n")
    {
        if (magic[0..7] == "#?RGBE\n")
        {
            istrm.position = 7;
        }
        else
            return error("loadHDR error: signature check failed");
    }

    // Read header
    Array!char line;
    do
    {
        line.free();
        readLineFromStream(istrm, line);
        // TODO: parse assignments
    }
    while (line.length);

    // Read resolution line
    line.free();
    readLineFromStream(istrm, line);

    char xsign, ysign;
    uint width, height;
    int count = sscanf(line.data.ptr, "%cY %u %cX %u", &ysign, &height, &xsign, &width);
    if (count != 4)
        return error("loadHDR error: invalid resolution line");

    // Read pixel data
    ubyte[] dataRGBE = New!(ubyte[])(width * height * 4);
    ubyte[4] col;
    for (uint y = 0; y < height; y++)
    {
        istrm.readBytes(col.ptr, 4);
        //Header of 0x2, 0x2 is new Radiance RLE scheme
        if (col[0] == 2 && col[1] == 2 && col[2] >= 0)
        {
            // Each channel is run length encoded seperately
            for (uint chi = 0; chi < 4; chi++)
            {
                uint x = 0;
                while (x < width)
                {
                    uint start = (y * width + x) * 4;
                    ubyte num = 0;
                    istrm.readBytes(&num, 1);
                    if (num <= 128) // No run, just read the values
                    {
                        for (uint i = 0; i < num; i++)
                        {
                            ubyte value;
                            istrm.readBytes(&value, 1);
                            dataRGBE[start + chi + i*4] = value;
                        }
                    }
                    else // We have a run, so get the value and set all the values for this run
                    {
                        ubyte value;
                        istrm.readBytes(&value, 1);
                        num -= 128;
                        for (uint i = 0; i < num; i++)
                        {
                            dataRGBE[start + chi + i*4] = value;
                        }
                    }

                    x += num;
                }
            }
        }
        else // Old Radiance RLE scheme
        {
            for (uint x = 0; x < width; x++)
            {
                if (x > 0)
                    istrm.readBytes(col.ptr, 4);

                uint prev = (y * width + x - 1) * 4;
                uint start = (y * width + x) * 4;

                // Check for the RLE header for this scanline
                if (col[0] == 1 && col[1] == 1 && col[2] == 1)
                {
                    // Do the run
                    int num = (cast(int)col[3]) & 0xFF;

                    ubyte r = dataRGBE[prev];
                    ubyte g = dataRGBE[prev + 1];
                    ubyte b = dataRGBE[prev + 2];
                    ubyte e = dataRGBE[prev + 3];

                    for (uint i = 0; i < num; i++)
                    {
                        dataRGBE[start + i*4 + 0] = r;
                        dataRGBE[start + i*4 + 1] = g;
                        dataRGBE[start + i*4 + 2] = b;
                        dataRGBE[start + i*4 + 3] = e;
                    }

                    x += num-1;
                }
                else // No runs here, just read the data
                {
                    dataRGBE[start] = col[0];
                    dataRGBE[start + 1] = col[1];
                    dataRGBE[start + 2] = col[2];
                    dataRGBE[start + 3] = col[3];
                }
            }
        }
    }

    // Convert RGBE to IEEE floats
    img = imgFac.createImage(width, height);
    foreach(y; 0..height)
    foreach(x; 0..width)
    {
        size_t start = (width * y + x) * 4;
        ubyte exponent = dataRGBE[start + 3];
        if (exponent == 0)
        {
            img[x, y] = Color4f(0, 0, 0, 1);
        }
        else
        {
            float v = ldexp(1.0, cast(int)exponent - (128 + 8));
            float r = cast(float)(dataRGBE[start]) * v;
            float g = cast(float)(dataRGBE[start + 1]) * v;
            float b = cast(float)(dataRGBE[start + 2]) * v;
            img[x, y] = Color4f(r, g, b, 1);
        }
    }

    Delete(dataRGBE);

    return compound(img, "");
}

/**
 * Save HDR to file using local FileSystem.
 * Causes GC allocation
 */
void saveHDR(SuperHDRImage img, string filename)
{
    OutputStream output = openForOutput(filename);
    Compound!(bool, string) res = saveHDR(img, output);
    output.close();
}

/**
 * Save HDR to stream.
 * GC-free
 */
Compound!(bool, string) saveHDR(SuperHDRImage img, OutputStream output)
{
    Compound!(bool, string) error(string errorMsg)
    {
        return compound(false, errorMsg);
    }

    // Signature and header
    string hdrStart = "#?RADIANCE\n\n"; // double LF needed to mark end of header
    output.writeArray(hdrStart);

    // Resolution line
    char[256] resolution;
    int len = sprintf(resolution.ptr, "-Y %d +X %d\n", img.height, img.width);
    output.writeArray(resolution[0..len]);

    ubyte[] scanline = New!(ubyte[])(img.width * 4);

    for (uint y = 0; y < img.height; y++)
    {
        ubyte[4] scanlineHeader;
        scanlineHeader[0] = 2;
        scanlineHeader[1] = 2;
        scanlineHeader[2] = cast(ubyte)(img.width >> 8);
        scanlineHeader[3] = cast(ubyte)(img.width & 0xFF);
        output.writeArray(scanlineHeader);

        // Convert a scanline to RGBE decomposing channels
        for (uint x = 0; x < img.width; x++)
        {
            ColorRGBE rgbe = img[x, y].floatToRGBE;
            scanline[x] = rgbe.r;
            scanline[x + img.width] = rgbe.g;
            scanline[x + img.width * 2] = rgbe.b;
            scanline[x + img.width * 3] = rgbe.e;
        }

        // Write channels
        foreach(ch; 0..4)
        {
            uint offset = ch * img.width;
            writeBufferRLE(output, scanline[offset..offset+img.width]);
        }
    }

    Delete(scanline);

    return compound(true, "");
}

/*
 * Based on code by Bruce Walter:
 * http://www.graphics.cornell.edu/~bjw/rgbe/rgbe.c
 */
void writeBufferRLE(OutputStream output, ubyte[] data)
{
    enum MINRUNLENGTH = 4;
    int cur, beg_run, run_count, old_run_count, nonrun_count;
    ubyte[2] buf;

    cur = 0;
    while(cur < data.length)
    {
        beg_run = cur;

        // find next run of length at least 4 if one exists
        run_count = old_run_count = 0;
        while((run_count < MINRUNLENGTH) && (beg_run < data.length))
        {
            beg_run += run_count;
            old_run_count = run_count;
            run_count = 1;
            while((beg_run + run_count < data.length) && (run_count < 127)
                && (data[beg_run] == data[beg_run + run_count]))
                run_count++;
        }

        // if data before next big run is a short run then write it as such
        if ((old_run_count > 1) && (old_run_count == beg_run - cur))
        {
            buf[0] = cast(ubyte)(128 + old_run_count); // write short run
            buf[1] = data[cur];
            output.writeArray(buf);
            cur = beg_run;
        }

        // write out bytes until we reach the start of the next run
        while(cur < beg_run)
        {
            nonrun_count = beg_run - cur;
            if (nonrun_count > 128)
                nonrun_count = 128;
            buf[0] = cast(ubyte)nonrun_count;
            output.writeBytes(buf.ptr, 1);
            output.writeBytes(&data[cur], nonrun_count);
            cur += nonrun_count;
        }

        // write out next run if one was found
        if (run_count >= MINRUNLENGTH)
        {
            buf[0] = cast(ubyte)(128 + run_count);
            buf[1] = data[beg_run];
            output.writeArray(buf);
            cur += run_count;
        }
    }
}
