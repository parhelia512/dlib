/*
Copyright (c) 2014-2021 Timur Gafarov, Martin Cejp

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
 * Load and save images
 *
 * Copyright: Timur Gafarov, Martin Cejp 2014-2021.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov, Martin Cejp
 */
module dlib.image.io;

import std.path;
import dlib.image.image;
import dlib.image.animation;
import dlib.image.hdri;

public
{
    import dlib.image.io.bmp;
    import dlib.image.io.hdr;
    import dlib.image.io.png;
    import dlib.image.io.tga;
    import dlib.image.io.jpeg;
}

class ImageLoadException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

/**
 * Saves an image to file, selects encoder by filename extension
 */
void saveImage(SuperImage img, string filename)
{
    switch(filename.extension)
    {
        case ".png", ".PNG":
            img.savePNG(filename);
            break;
        case ".bmp", ".BMP":
            img.saveBMP(filename);
            break;
        case ".tga", ".TGA":
            img.saveTGA(filename);
            break;
        default:
            assert(0, "Image I/O error: unsupported image format or illegal extension");
    }
}

/**
 * Loads an image from file, selects decoder by filename extension
 */
SuperImage loadImage(string filename)
{
    switch(filename.extension)
    {
        case ".bmp", ".BMP":
            return loadBMP(filename);
        case ".hdr", ".HDR":
            return loadHDR(filename);
        case ".jpg", ".JPG", ".jpeg", ".JPEG":
            return loadJPEG(filename);
        case ".png", ".PNG":
            return loadPNG(filename);
        case ".tga", ".TGA":
            return loadTGA(filename);
        default:
            assert(0, "Image I/O error: unsupported image format or illegal extension");
    }
}

/**
 * Loads an animated image from file, selects decoder by filename extension
 */
SuperAnimatedImage loadAnimatedImage(string filename)
{
    switch(filename.extension)
    {
        case ".png", ".apng", ".PNG", ".APNG":
            return loadAPNG(filename);
        default:
            assert(0, "Image I/O error: unsupported image format or illegal extension");
    }
}

/**
 * Saves an animated image to file, selects encoder by filename extension
 */
void saveAnimatedImage(SuperAnimatedImage img, string filename)
{
    switch(filename.extension)
    {
        case ".png", ".PNG", ".apng", ".APNG":
            img.saveAPNG(filename);
            break;
        default:
            assert(0, "Image I/O error: unsupported image format or illegal extension");
    }
}

/**
 * Loads an HDR image from file, selects decoder by filename extension
 */
SuperImage loadHDRImage(string filename)
{
    switch(filename.extension)
    {
        case ".hdr", ".HDR":
            return loadHDR(filename);
        default:
            assert(0, "Image I/O error: unsupported image format or illegal extension");
    }
}

/**
 * Saves an HDR to file, selects encoder by filename extension
 */
void saveHDRImage(SuperHDRImage img, string filename)
{
    switch(filename.extension)
    {
        case ".hdr", ".HDR":
            img.saveHDR(filename);
            break;
        default:
            assert(0, "Image I/O error: unsupported image format or illegal extension");
    }
}
