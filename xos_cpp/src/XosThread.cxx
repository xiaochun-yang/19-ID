extern "C" {
#include "xos.h"
}

#include "XosException.h"
#include "XosThread.h"

/**********************************************************
 *
 * Default constructor
 *
 **********************************************************/
XosThread::XosThread()
	: runnable(NULL), status(XOS_THREAD_NOT_STARTED)
{
}

/**********************************************************
 *
 * Constructor
 * Every thread has a name for identification purposes.
 * More than one thread may have the same name.
 * If a name is not specified when a thread is created,
 * a new name is generated for it.
 *
 **********************************************************/
XosThread::XosThread(const std::string& name)
	: runnable(NULL), status(XOS_THREAD_NOT_STARTED)
{
}

/**********************************************************
 *
 * Constructor

 *
 **********************************************************/
XosThread::XosThread(Runnable* runnable)
{
    status = XOS_THREAD_NOT_STARTED;
	this->runnable = runnable;
}

/**********************************************************
 *
 * Destructor must be virtual
 *
 **********************************************************/
XosThread::~XosThread()
{
    xos_thread_close(&threadHandle);
}


/**********************************************************
 *
 * Causes this thread to begin execution; the threadRoutine calls the
 * run method of this thread.
 * The result is that two threads are running concurrently:
 * the current thread (which returns from the call to the start method)
 * and the other thread (which executes its run method).
 *
 **********************************************************/
void XosThread::start()
    throw (XosException)
{
    // A thread that waits and handles all channel access events.
    if ( xos_thread_create( &threadHandle,
                            XosThread::threadRoutine,
                            this) != XOS_SUCCESS )
        throw XosException("Failed in xos_thread_create");

}

/**********************************************************
 *
 * Waits at forever for this thread to die.
 *
 **********************************************************/
void XosThread::join()
    throw (XosException)
{
    join(0);
}

/**********************************************************
 *
 * Waits at most millis milliseconds for this thread to die.
 * A timeout of 0 means to wait forever.
 *
 **********************************************************/
void XosThread::join(unsigned int millisec)
    throw (XosException)
{
    xos_wait_result_t ret = xos_thread_wait(&threadHandle, millisec);

    switch (ret) {
        case XOS_WAIT_SUCCESS:
            return;
        case XOS_WAIT_TIMEOUT:
            throw XosException("Time out in xos_thread_wait");

    }

    throw XosException("Failed in xos_thread_wait");

}



/**********************************************************
 *
 * Tests if this thread is alive. A thread is alive if it has
 * been started and has not yet died
 *
 **********************************************************/
bool XosThread::isAlive() const
{
    return (threadHandle.isValid && (status == XOS_THREAD_STARTED));
}


/**********************************************************
 *
 * Tests if this thread is finished. 
 *
 **********************************************************/
bool XosThread::isFinished() const
{
    return (!threadHandle.isValid && (status == XOS_THREAD_FINISHED));
}

/**********************************************************
 *
 * Causes the currently executing thread to sleep (temporarily cease execution)
 * for the specified number of milliseconds.
 *
 **********************************************************/
void XosThread::sleep(unsigned int millisec)
    throw (XosException)
{
    if (xos_thread_sleep(millisec) != XOS_SUCCESS)
        throw XosException("Failed in xos_thread_sleep\n");
}



/**********************************************************
 *
 * All threads start here
 *
 **********************************************************/
XOS_THREAD_ROUTINE XosThread::threadRoutine(void* arg)
{
    XosThread* threadObj = (XosThread*)arg;
        
    if (threadObj == NULL)
    	throw XosException("Invalid thread object passed to thread routine");
    	
    try {
    
		threadObj->status = XOS_THREAD_STARTED;

		if (threadObj->runnable != NULL) {
			threadObj->runnable->run();
		} else {
			// Call the run method to let the application
			// do the job inside this thread
			threadObj->run();
		}
		
		// Set the isValid to false and clear the lock
		xos_thread_close(&threadObj->threadHandle);

		threadObj->status = XOS_THREAD_FINISHED;

	} catch (XosException& e) {
	
		// Set the isValid to false and clear the lock
		xos_thread_close(&threadObj->threadHandle);
		threadObj->status = XOS_THREAD_FINISHED;
		
		throw;
	}


    XOS_THREAD_ROUTINE_RETURN;
}



