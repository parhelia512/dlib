/*
Copyright (c) 2019-2025 Timur Gafarov

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
 * Copyright: Timur Gafarov 2019-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.concurrency.threadpool;

import std.functional;
import dlib.core.memory;
import dlib.core.mutex;
import dlib.concurrency.workerthread;
import dlib.concurrency.taskqueue;

/**
 * An object that manages worker threads and runs tasks on them
 */
class ThreadPool
{
    protected:
    uint maxThreads;
    WorkerThread[] workerThreads;
    TaskQueue taskQueue;
    bool running = true;
    Mutex mutex;

    public:
    
    /// Constructor
    this(uint maxThreads)
    {
        this.maxThreads = maxThreads;
        workerThreads = New!(WorkerThread[])(maxThreads);
        taskQueue = New!TaskQueue();

        mutex.init();

        foreach(i, ref t; workerThreads)
        {
            t = New!WorkerThread(i, this);
            t.start();
        }
    }

    ~this()
    {
        mutex.lock();
        running = false;
        mutex.unlock();

        foreach(i, ref t; workerThreads)
        {
            t.join();
            Delete(t);
        }

        Delete(taskQueue);
        Delete(workerThreads);

        mutex.destroy();
    }

    /// Create a task from delegate
    Task submit(void delegate() taskDele)
    {
        Task task = Task(TaskState.Valid, taskDele);
        if (!taskQueue.enqueue(task))
        {
            task.run();
        }
        return task;
    }

    /// Create a task from function pointer
    Task submit(void function() taskFunc)
    {
        return submit(toDelegate(taskFunc));
    }

    Task request()
    {
        return taskQueue.dequeue();
    }

    bool isRunning()
    {
        return running;
    }

    /// Returns true if all tasks are finished
    bool tasksDone()
    {
        if (taskQueue.count == 0)
        {
            foreach(i, t; workerThreads)
            {
                if (t.busy)
                    return false;
            }

            return true;
        }
        else
            return false;
    }
}

/*
///
unittest
{
    import std.stdio;

    int x = 0;
    int y = 0;

    void task1()
    {
        while(x < 100)
            x += 1;
    }

    void task2()
    {
        while(y < 100)
            y += 1;
    }

    ThreadPool threadPool = New!ThreadPool(2);

    threadPool.submit(&task1);
    threadPool.submit(&task2);

    while(!threadPool.tasksDone) {}

    if (x != 100) writeln(x);
    if (y != 100) writeln(y);

    assert(x == 100);
    assert(y == 100);

    Delete(threadPool);
}
*/
