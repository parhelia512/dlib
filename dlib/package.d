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
 * dlib - general purpose library
 *
 * Description:
 * dlib is a high-level general purpose library for 
 * $(LINK2 https://dlang.org, D language) intended to 
 * game engine developers. It provides basic building blocks for writing
 * graphics-intensive applications: containers, data streams, linear algebra 
 * and image decoders.
 *
 * dlib has no external dependencies aside D's standard library. dlib is created
 * and maintained by $(LINK2 https://github.com/gecko0307, Timur Gafarov).
 *
 * If you like dlib, please support its development on
 * $(LINK2 https://www.patreon.com/gecko0307, Patreon) or
 * $(LINK2 https://liberapay.com/gecko0307, Liberapay). You can also make one-time 
 * donation via $(LINK2 https://www.paypal.me/tgafarov, PayPal) or
 * $(LINK2 https://nowpayments.io/donation/gecko0307, NOWPayments).
 *
 * If you want to use dlib on macOS then, please, first read the 
 * $(LINK2 https://github.com/gecko0307/dlib/wiki/Why-doesn't-dlib-support-macOS, manifesto).
 *
 * Currently dlib consists of the following packages:
 *
 * - $(LINK2 dlib/core.html, dlib.core) - basic functionality used by other modules (memory management, streams, threads, etc.)
 *
 * - $(LINK2 dlib/container.html, dlib.container) - generic data structures (GC-free dynamic and associative arrays and more)
 *
 * - $(LINK2 dlib/filesystem.html, dlib.filesystem) - abstract FS interface and its implementations for Windows and POSIX filesystems
 *
 * - $(LINK2 dlib/math.html, dlib.math) - linear algebra and numerical analysis (vectors, matrices, quaternions, linear system solvers, interpolation functions, etc.)
 *
 * - $(LINK2 dlib/geometry.html, dlib.geometry) - computational geometry (ray casting, primitives, intersection, etc.)
 *
 * - $(LINK2 dlib/image.html, dlib.image) - image processing (8-bit, 16-bit and 32-bit floating point channels, common filters and convolution kernels, resizing, FFT, HDRI, animation, graphics formats I/O: JPEG, PNG/APNG, BMP, TGA, HDR)
 *
 * - $(LINK2 dlib/audio.html, dlib.audio) - sound processing (8 and 16 bits per sample, synthesizers, WAV export and import)
 *
 * - $(LINK2 dlib/network.html, dlib.network) - networking and web functionality
 *
 * - $(LINK2 dlib/memory.html, dlib.memory) - memory allocators
 *
 * - $(LINK2 dlib/text.html, dlib.text) - text processing, GC-free strings, Unicode decoding and encoding
 *
 * - $(LINK2 dlib/random.html, dlib.random) - random number generation
 *
 * - $(LINK2 dlib/serialization.html, dlib.serialization) - data serialization (XML and JSON parsers)
 *
 * - $(LINK2 dlib/coding.html, dlib.coding)- various data compression and coding algorithms
 *
 * - $(LINK2 dlib/concurrency.html, dlib.concurrency) - a thread pool.
 *
 * Copyright: Timur Gafarov 2011-2025.
 * License: $(LINK2 https://boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib;

public
{
    import dlib.audio;
    import dlib.coding;
    import dlib.concurrency;
    import dlib.container;
    import dlib.core;
    import dlib.filesystem;
    import dlib.geometry;
    import dlib.image;
    import dlib.math;
    import dlib.memory;
    import dlib.network;
    import dlib.random;
    import dlib.serialization;
    import dlib.text;
}
