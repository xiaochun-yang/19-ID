#ifndef __Include_XosThread_h__
#define __Include_XosThread_h__

/**
 * @file XosThread.h
 * Header file for Thread class.
 */

extern "C" {
#include "xos.h"
}

#include <string>
#include "XosException.h"

enum ThreadStatus {
	XOS_THREAD_NOT_STARTED,
	XOS_THREAD_STARTED,
	XOS_THREAD_FINISHED
};

/**
 * @class Runnable
 * An interface class for thread
 */
class Runnable
{
public:

    /**
     * @brief This method is called by the thread routine.
     *
     * It runs inside the newly created thread. Subclass must override this method.
     * When this method returns, the thread will automatically exit.
     **/
    virtual void run() = 0;
};

/**
 * @class XosThread
 * Subclass overrides run() method for execution inside a new thread. Thread exits
 * when run() method returns. This is a thin C++ wrapper of the xos_thread.
 * Example
 *
 * @code

   class ChildThread public XosThread
   {
       // This method runs in the newly created thread
       // Once this method exits, the thread will terminate.
       virtual void run()
       {
           int count = 0;

           // Loop for 1000 times.
           while (count < 1000) {

               // Print out name of the current thread
               printf("I am %s\n", getName().c_str());

               // Put this current thread to sleep for 5 seconds
               XosThread::sleep(5*1000);
           }
       }
   }

   void main(int argc, char** argv)
   {
       XosThread child1("thread 1");
       XosThread child2("thread 3");

       child1.start();

       child2.start();

       int childCount = 2;

       // Loop for 1000 times.
       while (childCount > 0) {

           // Print out name of the current thread
           printf("I am parent\n");

           // Put this current thread to sleep for 5 seconds
           XosThread::sleep(5*1000);

           // How many threads are still alive?
           childCount = 0;

           if (child1.isAlive())
               ++count;
           if (!child2.isAlive())
               ++count;
       }


   }

 * @endcode
 */
class XosThread : public Runnable
{
public:

    /**
     * @brief Default constructor.
     *
     * Create a thread object with a no name.
     * The thread will not start until start() is called.
     **/
    XosThread();

    /**
     * @brief Constructor. Creates a thread object with the name.
     *
     * The thread will not start until start() is called.
     * @param name Thread name
     **/
    XosThread(const std::string& name);

    /**
     * @brief Constructor. Creates a thread object with the name.
     *
     * The thread will not start until start() is called.
     * @param runnable A class that implements Runnable interface
     **/
    XosThread(Runnable* runnable);

    /**
     * @brief Destructor.
     *
     * Terminates the thread if it is still running and frees up the resources.
     **/
    virtual ~XosThread();

    /**
     * @brief Returns the name of this thread
     * @return Name of this thread.
     **/
    std::string getName() const
    {
        return name;
    }


    /**
     * @brief This method is called by the thread routine.
     *
     * It runs inside the newly created thread. Subclass must override this method.
     * When this method returns, the thread will automatically exit.
     **/
    virtual void run() {}

    /**
     * @brief Causes this thread to begin execution; the threadRoutine calls the
     * run method of this thread.
     *
     * The result is that two threads are running concurrently:
     * the current thread (which returns from the call to the start method)
     * and the other thread (which executes its run method).
     * @exception XosException Thrown if thread creation fails.
     **/
    void start()
        throw (XosException);

    /**
     * @brief Waits at forever for this thread to die.
     * @exception XosException Thrown if thread creation fails.
     **/
    void join()
        throw (XosException);

    /**
     * Waits at most millis milliseconds for this thread to die.
     *
     * A timeout of 0 means to wait forever.
     * @exception XosException Thrown if wait fails.
     **/
    void join(unsigned int millisec)
        throw (XosException);

    /**
     * @brief Tests if this thread is alive.
     *
     * A thread is alive if it has
     * been started and has not yet died
     * @exception XosException Thrown if wait fails or timeout occurs.
     **/
    bool isAlive() const;

    /**
     * @brief Tests if this thread is finished (has started and finished)
     *
     * A thread is alive if it has
     * been started and died
     * @exception XosException Thrown if wait fails or timeout occurs.
     **/
    bool isFinished() const;


    /**
     * @brief Causes the currently executing thread to sleep (temporarily cease execution)
     * for the specified number of milliseconds.
     * @param millisec Number of milli seconds for this thread to sleep.
     * @exception XosException Thrown when sleep fails
     **/
    static void sleep(unsigned int millisec)
        throw (XosException);




private:

    /**
     * @brief Name of instance of this class
     **/
    std::string name;

    
    /**
     * @brief The class that implements Runnable interface
     **/
    Runnable* runnable;
    
    
    ThreadStatus status;
    
    /**
     * @brief The underlying thread object
     **/
    xos_thread_t threadHandle;
    


    /**
     * @brief All threads start here
     **/
    static XOS_THREAD_ROUTINE threadRoutine(void* arg);

};

#endif // __Include_XosThread_h__


