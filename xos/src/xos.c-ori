/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/


/****************************************************************
                        xos.c
                        
   This source file defines the functions for the XOS library.
   XOS stands for Cross Operating System, and provides a set of
   functions that wrap highly operating system dependent
   functions in procedures that can be called from any supported
   operating system.  The XOS library supports cross-platform
   threads, semaphores, critical sections, memory-mapped files, 
   and message queues.
   
   Author:           Timothy M. McPhillips, SSRL.
   Last Revision:    February 27, 1998 by TMM.
   
****************************************************************/

#include "xos.h"

/* declarations for private helper functions */

static void xos_vprint_error(int errnoflag, const char *fmt, va_list ap);

#ifdef WIN32

xos_wait_result_t win32_object_wait
   (
   HANDLE      handle,
   xos_time_t  timeout
   );

xos_result_t win32_object_trywait
   (
   HANDLE      handle
   );

xos_result_t win32_object_close
   (
   HANDLE   handle
   );

#else
#include <syslog.h>
#endif


#if defined IRIX || defined LINUX
	extern int errno;
#endif

#ifndef LOG_AUTHPRIV
#ifdef LOG_AUTH
#define LOG_AUTHPRIV LOG_AUTH
#endif
#endif


/****************************************************************
                     xos_thread_create
Description:
   This function constructs the XOS thread object associated with 
   the passed xos_thread_t structure.  It calls OS-dependent 
   functions to create a new thread of execution starting at the 
   passed address (thread_routine) and passing a single void 
   pointer (thread_param) to the new thread. On some non-WIN32 
   systems it also creates data structures needed to support the 
   XOS thread messaging services.
   
Return Values:
   XOS_SUCCESS -- the thread was created successfully.
   XOS_FAILURE -- an error occurred creating the thread.
****************************************************************/

xos_result_t xos_thread_create
   ( 
   xos_thread_t         *thread,
   xos_thread_routine_t *thread_routine,
   void                 *thread_param 
   )
   
#ifdef WIN32
   {
	/* start the thread */
   thread->handle = (HANDLE) _beginthreadex 
      ( NULL, 0, thread_routine, thread_param, 0, & thread->id );

   /* report error if unsuccessful */
   if ( thread->handle == NULL )
      {
      thread->isValid = FALSE;
		xos_error_sys("xos_thread_create -- error creating thread");
      return XOS_FAILURE;
      }
   /* otherwise report success */
   else
      {
      thread->isValid = TRUE;
      return XOS_SUCCESS;
      }
   }
#endif

  
#ifdef PTHREAD
   {

   /* initialize thread message queue */
   thread->headMessage	= NULL;
   thread->tailMessage	= NULL;
   
   /* initialize thread message counter */
   if ( xos_semaphore_create( & thread->messageCount, 0 ) != XOS_SUCCESS )
   	{
   	xos_error( "xos_thread_create -- error creating thread message semaphore");
   	return XOS_FAILURE;
   	}

   /* initialize thread message mutex */
   if ( xos_mutex_create( & thread->messageMutex ) != XOS_SUCCESS )
   	{
   	xos_error( "xos_thread_create -- error creating thread message mutex");
   	return XOS_FAILURE;
   	}
   
   /* start the thread */
	//printf("create thread\n");
	if ( pthread_create ( & thread->handle, PTHREAD_NULL_ATTR, 
   	thread_routine, thread_param ) != 0 )
      {
      thread->isValid = FALSE;
		xos_error_sys("xos_thread_create -- error creating thread");
      return XOS_FAILURE;
      }

	//printf("detach thread\n");
	if ( pthread_detach( thread->handle ) != 0)
		{
		xos_error_sys("xos_thread_create -- could not detach thread");
      thread->isValid = FALSE;
		return XOS_FAILURE;
		}
            
   /* report success */
	thread->isValid = TRUE;
	return XOS_SUCCESS;
   }
#endif




/****************************************************************
                     xos_thread_wait
Description:                  
   This function waits for the thread associated with the passed 
   xos_thread_t structure to terminate, or for the passed timeout 
   value (in milliseconds) to expire.  A timeout of 0 may be 
   passed to force the function to wait for the thread indefinitely.  
	Timeouts are ignored under DEC Unix.
	   
Return Values: 
   XOS_WAIT_SUCCESS -- the thread terminated within the timeout. 
   XOS_WAIT_TIMEOUT -- the timeout expired. 
   XOS_WAIT_FAILURE -- an error occurred.
****************************************************************/

xos_wait_result_t xos_thread_wait
   (
   xos_thread_t   *thread,
   xos_time_t     timeout
   )
   
   {
   /* make sure thread handle is valid */
   assert( thread->isValid == TRUE );

#ifdef WIN32
   return win32_object_wait( thread->handle, timeout );
#endif

#ifdef PTHREAD
	/* join the specified thread */
	if ( pthread_join( thread->handle, NULL ) == 0 )
		{
		return XOS_WAIT_SUCCESS;
		}
	else
		{
		xos_error_sys("xos_thread_wait -- error joining thread");
		return XOS_WAIT_FAILURE;
		}
#endif   
	}


/****************************************************************
                     xos_thread_close
Description:
   This function closes the XOS thread associated with the passed 
   xos_thread_t structure.  Although the thread is not terminated 
   if still running, on some non-WIN32 systems the funtions 
   releases data structures needed to support the XOS thread 
   messaging services.  Thus, this function may be called before 
   a thread terminates, but messages can no longer be sent to the
   thread at that point.
   
Return Values:
   XOS_SUCCESS -- the thread closed successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_thread_close
   (
   xos_thread_t   *thread
   )
   
   {
   /* make sure thread handle still valid */
   assert( thread->isValid == TRUE );

   /* invalidate the thread structure */
   thread->isValid = FALSE;

#ifdef WIN32
   /* close the handle in win32 */
   return win32_object_close( thread->handle );
#endif

#ifdef PTHREAD
	/* report success */
	return XOS_SUCCESS;
#endif
   }


/****************************************************************
                     xos_thread_sleep
Description:
   This function causes the calling thread to sleep for the
   specified number of milliseconds (sleepTime).
   
Return Values:
   XOS_SUCCESS -- the thread slept for the specified amount of time.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_thread_sleep
   (
   xos_time_t  sleepTime
   )
   
#ifdef WIN32
   {
   /* sleep specified number of milliseconds */
   Sleep( sleepTime );

   /* function always succeeds */
   return XOS_SUCCESS;
   }
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
	{
	/* local variables */
	struct timespec 	time;

	/* fill timespec structure */
	time.tv_sec		= sleepTime / 1000;
	time.tv_nsec	= (sleepTime % 1000) * 1000000;

	/* sleep the requested time */
	nanosleep( &time, NULL );

   /* function always succeeds */
   return XOS_SUCCESS;
   }   
#endif

#ifdef VMS
	{
	/* local variables */
	long eventFlag;
	struct {
		long upperLongword;
		long lowerLongword;
		} binaryTime;	
	int syscallResult;
	char timeString[80];
	$DESCRIPTOR(timeStringDescriptor,"");

	/* create a vms string version of the time */
 	sprintf( timeString, "0 00:00:%4.2f", (double) sleepTime / 1000.0 );
 	timeStringDescriptor.dsc$w_length = strlen(timeString);
 	timeStringDescriptor.dsc$a_pointer = timeString;

	/* convert time string to binary time */
	if ( sys$bintim( &timeStringDescriptor, &binaryTime ) != SS$_NORMAL )
		{ 
		xos_error("xos_thread_sleep -- error converting time");
		return XOS_FAILURE;
		}
  		
 	/* get an event flag to use */
	if ( lib$get_ef( &eventFlag ) != SS$_NORMAL )
		{ 
		xos_error("xos_thread_sleep -- error getting event flag");
		return XOS_FAILURE;
		}

   /* clear the event flag */	
	sys$clref( eventFlag );
	
	/* start the timer */
	sys$setimr( eventFlag, &binaryTime, NULL, 0);

	/* wait for the event flag to be set */
	sys$waitfr( eventFlag );
 
	/* free the event flag */
	if ( lib$free_ef( &eventFlag ) != SS$_NORMAL )
		{ 
		xos_error("xos_thread_sleep -- error freeing event flag");
		return XOS_FAILURE;
		}
	
   /* report success */
   return XOS_SUCCESS;
   }
#endif


/****************************************************************
                     xos_thread_exit 
Description:
   This function causes the calling thread to terminate
   immediately.
   
Return Values:
   XOS_SUCCESS -- the thread terminated successfully.  
   XOS_FAILURE -- an error occurred.
****************************************************************/


xos_result_t xos_thread_exit
   ( 
   void
   )
   
#ifdef WIN32
   {
   _endthreadex( 0 ); 
   return XOS_SUCCESS;
   }
#endif

#ifdef PTHREAD
   {
   pthread_exit( 0 ); 
   return XOS_SUCCESS;
   }
#endif

/****************************************************************
                     xos_thread_current_id
Description:
   This function get current thread ID.

Return value:
	The thread ID
****************************************************************/
unsigned int xos_thread_current_id( )
{
#ifdef WIN32
	return (unsigned int)GetCurrentThreadId( );
#elif defined(PTHREAD)
	return (unsigned int)pthread_self( );
#else
	return 0;
#endif
}



/****************************************************************
                     xos_semaphore_create
Description:
   This function constructs the XOS semaphore object associated 
   with the passed xos_semaphore_t structure.  It calls 
   OS-dependent functions to create a new semaphore with the 
   specified initial value. The initial value must be non-negative.  
   
Return Values:
   XOS_SUCCESS -- the semaphore was created successfully  
   XOS_FAILURE -- an error occurred
****************************************************************/

xos_result_t xos_semaphore_create
   ( 
   xos_semaphore_t         *semaphore,
   xos_semaphore_value_t   initialValue
   )
   
   {
	/* semaphore starts out invalid */
	semaphore->isValid = FALSE;

#ifdef WIN32
   assert ( initialValue <= XOS_SEMAPHORE_MAX_VALUE );
   semaphore->handle = CreateSemaphore( NULL, initialValue, XOS_SEMAPHORE_MAX_VALUE, NULL );

   /* report error if unsuccessful */
   if ( semaphore->handle == NULL )
      {
      semaphore->isValid = FALSE;		
		xos_error_sys("xos_semaphore_create -- error creating semaphore");
      return XOS_FAILURE;
      }
   /* otherwise report success */
   else
      {
      semaphore->isValid = TRUE;
      return XOS_SUCCESS;
      }
#endif

#ifdef PTHREAD
	/* initialize the semaphore value */
	semaphore->value = initialValue;

	/* initialize the mutex */
	if ( xos_mutex_create( & semaphore->mutex ) != XOS_SUCCESS )
		{
		xos_error("xos_semaphore_create -- error creating mutex");
		return XOS_FAILURE;
		}
		
	/* initialize the condition variable */
	if ( pthread_cond_init( & semaphore->condition, PTHREAD_NULL_ATTR ) != 0 )
		{
		xos_error("xos_semaphore_create -- error creating condition variable");
		return XOS_FAILURE;
		}
	
	/* otherwise report success */
   semaphore->isValid = TRUE;
   return XOS_SUCCESS;
#endif   
	}


/****************************************************************
                     xos_semaphore_wait
Description:
   This function waits for the semaphore associated with the 
   passed xos_semaphore_t structure to be incremented (posted) to 
   a non-zero value.  It then decrements the semaphore and returns.
   The function will also return when the timeout, specified in
   milliseconds, runs out.  A timeout of 0 may be passed to force
   the function to wait indefinitely.
   
Return Values: 
   XOS_WAIT_SUCCESS -- the semaphore was posted within the timeout. 
   XOS_WAIT_TIMEOUT -- the timeout expired.
   XOS_WAIT_FAILURE -- an error occurred.
****************************************************************/

xos_wait_result_t xos_semaphore_wait
   (
   xos_semaphore_t   *semaphore,
   xos_time_t        timeout
   )
   
   {
#ifdef PTHREAD
    int waitStatus;
    struct timespec waitTime;
    xos_boolean_t outOfTime = FALSE;
#endif /* PTHREAD */
   /* make sure semaphore handle is valid */
   assert( semaphore->isValid == TRUE );

#ifdef WIN32
   /* ask win32 to wait for the semaphore */
   return win32_object_wait( semaphore->handle, timeout );
#endif
 
#ifdef PTHREAD
	/* lock the semaphore mutex */
	if ( xos_mutex_lock( & (semaphore->mutex) ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_semaphore_wait -- error locking mutex");
		return XOS_WAIT_FAILURE;
		}
    /* Timeout of 0 is an infinite wait  so use pthread_cond_wait*/
	if ( timeout == 0 )
        {
        while ( semaphore->value == 0 )
            {
            waitStatus = pthread_cond_wait( &(semaphore->condition), &(semaphore->mutex.handle));
            if ( waitStatus != 0 )
                {
                    xos_error_sys("xos_semaphore_wait -- error waiting for condition variable (pthreads)");
                    return XOS_WAIT_FAILURE;
                }
            }
        }
    else /* Finite timeout, use pthread_cond_timedwait*/
        {
        if (clock_gettime( CLOCK_REALTIME, &waitTime )) {
            xos_error_sys("xos_semaphore_wait -- clock_gettime failed");
            return XOS_WAIT_FAILURE;
        }

        waitTime.tv_sec  += timeout / 1000;
        waitTime.tv_nsec += (timeout % 1000) * 1000000;
        if (waitTime.tv_nsec > 1000000000) {
            ++waitTime.tv_sec;
            waitTime.tv_nsec -= 1000000000;
        }
    	/* wait for semaphore value to go non-zero */
    	while ( semaphore->value == 0 )
    		{
            waitStatus = pthread_cond_timedwait( &(semaphore->condition), 
                                                &(semaphore->mutex.handle), &waitTime );
    		if ( waitStatus != 0 )
    			{
                if ( waitStatus == ETIMEDOUT )
                    {
                    if ( semaphore->value == 0 )
                        {
                        outOfTime = TRUE;
                        }
                    break;
                    }
    			xos_error_sys("xos_semaphore_wait -- error waiting for condition variable");
                if ( xos_mutex_unlock( & semaphore->mutex ) != XOS_SUCCESS )
		            {
	            	xos_error_sys("xos_semaphore_wait -- error unlocking mutex");
		            }
    			return XOS_WAIT_FAILURE;
    			}
    		}
        }
	
	/* decrement the semaphore */
    if ( outOfTime != TRUE)
        {
        	semaphore->value --;
        }
	/* release the semaphore mutex */
	if ( xos_mutex_unlock( & semaphore->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_semaphore_wait -- error unlocking mutex");
		return XOS_WAIT_FAILURE;
		}
    if ( outOfTime == TRUE )
        {
            return XOS_WAIT_TIMEOUT;
        }
	/* report success */
	return XOS_WAIT_SUCCESS;
#endif
   }


/****************************************************************
                     xos_semaphore_post
Description:
   This function increments (posts) the semaphore associated with
   the passed xos_semaphore_t structure.

Return Values:
   XOS_SUCCESS -- the semaphore was posted successfully.  
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_semaphore_post
   (
   xos_semaphore_t   *semaphore
   )

   {
   /* make sure semaphore structure handle is valid */
   assert ( semaphore->isValid == TRUE );

#ifdef WIN32
   /* post the semaphore */
	if ( ReleaseSemaphore( semaphore->handle, 1, NULL ) == TRUE )
		{
      /* report success */
      return XOS_SUCCESS;
      }
	else         
      {
      /* report failure */
		xos_error_sys("xos_semaphore_post -- error posting semaphore");
		return XOS_FAILURE;
      }
#endif

#ifdef PTHREAD
	/* lock the semaphore mutex */
	if ( xos_mutex_lock( & semaphore->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_semaphore_post -- error locking mutex");
		return XOS_FAILURE;
		}

	/* increment the semaphore */
	semaphore->value ++;
	
	/* signal threads waiting on semaphore */
	if ( pthread_cond_signal( &semaphore->condition ) != 0 )
		{
		xos_error_sys("xos_semaphore_post-- error signaling condition");
        if ( xos_mutex_unlock( & semaphore->mutex ) != XOS_SUCCESS )
		    {
		    xos_error_sys("xos_semaphore_post -- error unlocking mutex");
		    return XOS_FAILURE;
        	}
		return XOS_FAILURE;
		}
			
	/* release the semaphore mutex */
	if ( xos_mutex_unlock( & semaphore->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_semaphore_post -- error unlocking mutex");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
#endif
   }


/****************************************************************
                     xos_semaphore_close
Description:
   This function closes the XOS semaphore associated with the 
   passed xos_semaphore_t structure.
   
Return Values:
   XOS_SUCCESS -- the semaphore was closed successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_semaphore_close
   (
   xos_semaphore_t   *semaphore
   )
   
   {
   /* make sure semaphore handle still valid */
   assert( semaphore->isValid == TRUE );

   /* invalidate the semaphore structure */
   semaphore->isValid = FALSE;

#ifdef WIN32
   /* close the handle in win32 */
   return win32_object_close( semaphore->handle );
#endif

#ifdef PTHREAD
	/* destroy the mutex */
	if ( xos_mutex_close( & semaphore->mutex ) != XOS_SUCCESS )
		{
		xos_error("xos_semaphore_close -- error closing mutex");
		return XOS_FAILURE;
		}
		
	/* destroy the condition variable */
	if ( pthread_cond_destroy( & semaphore->condition ) != 0 )
		{
		xos_error("xos_semaphore_close -- error destroying condition variable");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;		
#endif
   }


/****************************************************************
                     xos_event_create
Description:
   This function constructs the XOS event object associated 
   with the passed xos_event_t structure.  It calls 
   OS-dependent functions to create a new event with the 
   specified initial value. The initial value must be non-negative.  
   
Return Values:
   XOS_SUCCESS -- the event was created successfully  
   XOS_FAILURE -- an error occurred
****************************************************************/
xos_result_t xos_event_create
   ( 
   xos_event_t         *event,
   xos_boolean_t       manualReset,
   xos_boolean_t       initialstate
   )
   
   {
	/* event starts out invalid */
	event->isValid = FALSE;

#ifdef WIN32
   event->handle = CreateEvent( NULL, manualReset, initialstate, NULL );	//manual reset

   /* report error if unsuccessful */
   if ( event->handle == NULL )
      {
      event->isValid = FALSE;		
		xos_error_sys("xos_event_create -- error creating event");
      return XOS_FAILURE;
      }
   /* otherwise report success */
   else
      {
      event->isValid = TRUE;
      return XOS_SUCCESS;
      }
#endif

#ifdef PTHREAD
	/* initialize the event value */
	event->value = initialstate;
    event->isManualReset = manualReset;

	/* initialize the mutex */
	if ( xos_mutex_create( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error("xos_event_create -- error creating mutex");
		return XOS_FAILURE;
		}
		
	/* initialize the condition variable */
	if ( pthread_cond_init( & event->condition, PTHREAD_NULL_ATTR ) != 0 )
		{
		xos_error("xos_event_create -- error creating condition variable");
		return XOS_FAILURE;
		}
	
	/* otherwise report success */
   event->isValid = TRUE;
   return XOS_SUCCESS;
#endif   
	}
/****************************************************************
                     xos_event_wait
Description:
   This function waits for the event associated with the 
   passed xos_event_t structure to be signaled) to 
   a non-zero value.  It then returns.
   The function will also return when the timeout, specified in
   milliseconds, runs out.  A timeout of 0 may be passed to force
   the function to wait indefinitely.
   
Return Values: 
   XOS_WAIT_SUCCESS -- the event was posted within the timeout. 
   XOS_WAIT_TIMEOUT -- the timeout expired.
   XOS_WAIT_FAILURE -- an error occurred.
****************************************************************/

xos_wait_result_t xos_event_wait
(
   xos_event_t   *event,
   xos_time_t        timeout
)
{
   /* make sure event handle is valid */
   assert( event->isValid == TRUE );

#ifdef WIN32
   /* ask win32 to wait for the event */
   return win32_object_wait( event->handle, timeout );
#endif
 
#ifdef PTHREAD
	/* lock the event mutex */
	if ( xos_mutex_lock( & event->mutex ) != XOS_SUCCESS )
	{
		xos_error_sys("xos_event_wait -- error locking mutex");
		return XOS_WAIT_FAILURE;
	}
	
	/* wait for event value to go non-zero */
    while ( event->value == 0 )
    {
	    if ( pthread_cond_wait( & event->condition, &event->mutex.handle ) != 0 )
	    {
		    xos_error_sys("xos_event_wait -- error waiting for condition variable");
		    return XOS_WAIT_FAILURE;
	    }
    }
	
	/* decrement the event */
    if (!event->isManualReset)
    {
	    event->value = 0;
    }
	
	/* release the event mutex */
	if ( xos_mutex_unlock( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_event_wait -- error unlocking mutex");
		return XOS_WAIT_FAILURE;
		}

	/* report success */
	return XOS_WAIT_SUCCESS;
#endif
   }

/****************************************************************
                     xos_event_set
Description:
   This function signal the XOS event associated with the 
   passed xos_event_t structure.
   
Return Values:
   XOS_SUCCESS -- the event was signaled successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/
xos_result_t xos_event_set
   (
   xos_event_t   *event
   )
{
   /* make sure event structure handle is valid */
   assert ( event->isValid == TRUE );

#ifdef WIN32
   /* post the event */
	if ( SetEvent( event->handle ) == TRUE )
	{
	      /* report success */
		  return XOS_SUCCESS;
    }
	else         
    {
      /* report failure */
		xos_error_sys("xos_event_post -- error posting event");
		return XOS_FAILURE;
    }
#endif

#ifdef PTHREAD
	/* lock the event mutex */
	if ( xos_mutex_lock( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_event_wait -- error locking mutex");
		return XOS_FAILURE;
		}

	/* increment the event */
   	event->value = 1;
	
	/* signal threads waiting on event */
	if ( pthread_cond_broadcast( &event->condition ) != 0 )
		{
		xos_error_sys("xos_event_wait -- error signaling condition");
		return XOS_FAILURE;
		}
			
	/* release the event mutex */
	if ( xos_mutex_unlock( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_event_wait -- error unlocking mutex");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
#endif
}




/****************************************************************
                     xos_event_reset
Description:
   This function unsignal the XOS event associated with the 
   passed xos_event_t structure.
   
Return Values:
   XOS_SUCCESS -- the event was unsignaled successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/
xos_result_t xos_event_reset
   (
   xos_event_t   *event
   )
{
   /* make sure event structure handle is valid */
   assert ( event->isValid == TRUE );

#ifdef WIN32
   /* post the event */
	if ( ResetEvent( event->handle ) == TRUE )
		{
      /* report success */
      return XOS_SUCCESS;
      }
	else         
      {
      /* report failure */
		xos_error_sys("xos_event_post -- error posting event");
		return XOS_FAILURE;
      }
#endif

#ifdef PTHREAD
	/* lock the event mutex */
	if ( xos_mutex_lock( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_event_wait -- error locking mutex");
		return XOS_FAILURE;
		}

	event->value = 0;
				
	/* release the event mutex */
	if ( xos_mutex_unlock( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error_sys("xos_event_wait -- error unlocking mutex");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
#endif
}





/****************************************************************
                     xos_event_close
Description:
   This function closes the XOS event associated with the 
   passed xos_event_t structure.
   
Return Values:
   XOS_SUCCESS -- the event was closed successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_event_close
   (
   xos_event_t   *event
   )
   
   {
   /* make sure event handle still valid */
   assert( event->isValid == TRUE );

   /* invalidate the event structure */
   event->isValid = FALSE;

#ifdef WIN32
   /* close the handle in win32 */
   return win32_object_close( event->handle );
#endif

#ifdef PTHREAD
	/* destroy the mutex */
	if ( xos_mutex_close( & event->mutex ) != XOS_SUCCESS )
		{
		xos_error("xos_event_close -- error closing mutex");
		return XOS_FAILURE;
		}
		
	/* destroy the condition variable */
	if ( pthread_cond_destroy( & event->condition ) != 0 )
		{
		xos_error("xos_event_close -- error destroying condition variable");
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;		
#endif
   }









/****************************************************************
                     xos_mutex_create
Description:
   This function constructs the XOS mutex object associated 
   with the passed xos_mutex_t structure.  It calls 
   OS-dependent functions to create a new mutex.

Return Values:
   XOS_SUCCESS -- the mutex was created successfully  
   XOS_FAILURE -- an error occurred
****************************************************************/

xos_result_t xos_mutex_create
   ( 
   xos_mutex_t    *mutex
   )
   
   {

#ifdef WIN32
   /* create unnamed mutex in signaled state */
   mutex->handle = CreateMutex( NULL, FALSE, NULL );

   /* report error if unsuccessful */
   if ( mutex->handle == NULL )
      {
		xos_error_sys("xos_mutex_create -- error creating mutex");
      mutex->isValid = FALSE;
      return XOS_FAILURE;
      }
   /* otherwise report success */
   else
      {
      mutex->isValid = TRUE;
      return XOS_SUCCESS;
      }
#endif

#ifdef PTHREAD
   /* create the mutex */
   if ( pthread_mutex_init( & mutex->handle, PTHREAD_NULL_ATTR ) != 0 )
      {
      mutex->isValid = FALSE;
		xos_error_sys("xos_mutex_create -- error creating mutex");
      return XOS_FAILURE;
      }
   else
      {
      mutex->isValid = TRUE;
      return XOS_SUCCESS;
      }
#endif   
   }


/****************************************************************
                     xos_mutex_lock
Description:
   This function waits for the mutex associated with the 
   passed xos_mutex_t structure to be signaled.  It then 
   locks the mutex.
   
Return Values: 
   XOS_SUCCESS -- the mutex was posted within the timeout. 
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_mutex_lock
   (
   xos_mutex_t		*mutex
   )
   
   {
   /* make sure mutex handle is valid */
   assert( mutex->isValid == TRUE );

#ifdef WIN32
   /* ask win32 to wait for the mutex */
   return win32_object_wait( mutex->handle, 0 );
#endif

#ifdef PTHREAD
   /* lock the mutex */
	if ( pthread_mutex_lock( & mutex->handle ) == 0 )
		{
		return XOS_SUCCESS;
		}
	else
		{
		xos_error_sys("xos_mutex_lock -- error locking mutex");
		return XOS_FAILURE;
		}
#endif
   }


/****************************************************************
                     xos_mutex_trylock
Description:
   This function tries to lock the mutex. If it is locked the func
   returns immediately without waiting. If not it will lock the mutex.
   
Return Values: 
   XOS_SUCCESS -- the mutex was posted within the timeout. 
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_mutex_trylock
   (
   xos_mutex_t		*mutex
   )
   
   {
   /* make sure mutex handle is valid */
   assert( mutex->isValid == TRUE );

#ifdef WIN32
   /* ask win32 to wait for the mutex for 0 msec */
   return win32_object_trywait(mutex->handle);
#endif

#ifdef PTHREAD
   /* lock the mutex */
	if ( pthread_mutex_trylock( &(mutex->handle) ) == 0 )
		return XOS_SUCCESS;
	return XOS_FAILURE;
	
#endif
   }


/****************************************************************
                     xos_mutex_unlock
Description:
   This function unlocks the mutex associated with
   the passed xos_mutex_t structure.

Return Values:
   XOS_SUCCESS -- the mutex was unlocked successfully.  
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_mutex_unlock
   (
   xos_mutex_t *mutex
   )

   {
   /* make sure mutex structure handle is valid */
   assert ( mutex->isValid == TRUE );

#ifdef WIN32
      {
      /* local variables */
      BOOL syscallResult;

      /* wait for the mutex */
      syscallResult= ReleaseMutex( mutex->handle );

      if ( syscallResult == TRUE )
         /* report success */
         return XOS_SUCCESS;
      else
         /* report failure */
		xos_error_sys("xos_mutex_unlock -- error unlocking mutex");
		return XOS_FAILURE;
      }
#endif

#ifdef PTHREAD
   /* unlock the mutex */
	if ( pthread_mutex_unlock( & mutex->handle ) == 0 )
		{
		return XOS_SUCCESS;
		}
	else
		{
		xos_error_sys("xos_mutex_unlock -- error unlocking mutex");
		return XOS_FAILURE;
		}
#endif
   }


/****************************************************************
                     xos_mutex_close
Description:
   This function closes the XOS mutex associated with the 
   passed xos_mutex_t structure.
   
Return Values:
   XOS_SUCCESS -- the mutex was closed successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_mutex_close
   (
   xos_mutex_t *mutex
   )
   
   {
   /* make sure semaphore handle still valid */
   assert( mutex->isValid == TRUE );

   /* invalidate the semaphore structure */
   mutex->isValid = FALSE;

#ifdef WIN32
   /* close the handle in win32 */
   return win32_object_close( mutex->handle );
#endif

#ifdef PTHREAD
   /* destroy the mutex */
	if ( pthread_mutex_destroy( & mutex->handle ) == 0 )
		{
		return XOS_SUCCESS;
		}
	else
		{
		xos_error_sys("xos_mutex_close -- error closing mutex");
		return XOS_FAILURE;
		}
#endif

   }


/****************************************************************
                     xos_mapped_file_open
Description:
   This function constructs the passed xos_mapped_file_t object
   by opening a file with specified filename, and mapping the
   file into memory.  The address of the beginning of the mapped
   memory is returned in the mapAddress parameter if the function
   succeeds.

Parameters:
   mappedFile
      Pointer to xos_mapped_file_t.
   fileName
      String specifying name of disk file to map.
   mapAddress
      void ** address of map in memory.
   openMode 
      XOS_OPEN_NEW      -- create new file overwriting existing file
      XOS_OPEN_EXISTING -- open a previously created file
   mappingSize
      32-bit unsigned integer number of bytes to map to memory.
      If file is shorter than (fileOffset + mappingSize), it is
      extended on disk appropriately.

Return Values:
   XOS_SUCCESS -- the file was mapped to memory successfully.
   XOS_FAILURE -- an error occurred mapping the file.
****************************************************************/

xos_result_t xos_mapped_file_open
   ( 
   xos_mapped_file_t *mappedFile,
   const char        *fileName,
   void              **mapAddress,
   xos_open_mode_t   openMode,
   xos_size_t        mappingSize
   )

   {
   /* mapped file object starts out invalid */
   mappedFile->isValid = FALSE;

#ifdef WIN32
      {
      /* local variables */
      HANDLE   fileHandle;
      HANDLE   mappingHandle;

      DWORD dwCreateFileDesiredAccess;
      DWORD dwCreateFileShareMode;
      DWORD fdwCreateMappingProtect;
      DWORD dwMapViewDesiredAccess;
      DWORD dwCreateDisposition;
      DWORD dwMaximumSizeLow;
      
      dwCreateFileShareMode = 0;
      dwCreateFileDesiredAccess  = GENERIC_READ | GENERIC_WRITE;
      fdwCreateMappingProtect    = PAGE_READWRITE;
      dwMapViewDesiredAccess     = FILE_MAP_WRITE;

      /* set disposition flag */
      switch ( openMode ) 
         {
         case XOS_OPEN_EXISTING:
            dwCreateDisposition = OPEN_EXISTING;
            dwMaximumSizeLow = 0;
            break;
         case XOS_OPEN_NEW:
            dwCreateDisposition = CREATE_ALWAYS;
            dwMaximumSizeLow = mappingSize;
            break;
         default:
            xos_error("xos_mapped_file_open -- unsupported open mode");
				return XOS_FAILURE;
         }

      /* attempt to open handle to existing file */
      fileHandle = CreateFile (
         fileName, dwCreateFileDesiredAccess, 
         dwCreateFileShareMode, NULL,
         dwCreateDisposition, FILE_ATTRIBUTE_NORMAL, NULL );
   
      /* return an error if file cannot be opened */
      if ( fileHandle == INVALID_HANDLE_VALUE )
         {
			xos_error_sys("xos_mapped_file_open -- file %s could not be opened",
				fileName );
         return XOS_FAILURE;
         }

      /* attempt to create a file mapping object */
      mappingHandle = CreateFileMapping (
         fileHandle, NULL, fdwCreateMappingProtect,
         0, dwMaximumSizeLow, NULL );

      /* return an error if file cannot be opened */
      if ( mappingHandle == NULL )
         {
			xos_error_sys("xos_mapped_file_open -- error creating file mapping");
			CloseHandle( fileHandle );
         return XOS_FAILURE;
         }

      /* attempt to map file to memory */
      *mapAddress = MapViewOfFile( 
         mappingHandle, dwMapViewDesiredAccess,
         0, 0, mappingSize );
      
      /* return an error if file cannot be mapped to memory */
      if ( *mapAddress == NULL )
         {
			xos_error_sys("xos_mapped_file_open -- error mapping file to memory");
         CloseHandle( mappingHandle );
         CloseHandle( fileHandle );
         return XOS_FAILURE;
         }

      /* close file and mapping handles since mapping successful */
      CloseHandle( mappingHandle );
      CloseHandle( fileHandle );
      
      /* store address and size of map */
      mappedFile->address 		= *mapAddress;
		mappedFile->mappingSize = mappingSize;
      }
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
      {
      /* local variables */
      int	fileHandle;
      int	openFlags 			= O_RDWR;
		int	memoryProtections	= PROT_READ | PROT_WRITE;
		int	openPermissions 	= S_IRUSR | S_IWUSR;
		int	mappingFlags 		= MAP_FILE | MAP_SHARED;

      /* set disposition flag */
      switch ( openMode ) 
         {
         case XOS_OPEN_EXISTING:
            break;
         case XOS_OPEN_NEW:
         	openFlags |= O_CREAT | O_TRUNC;
            break;
         default:
            xos_error("xos_mapped_file_open -- unsupported open mode");
				return XOS_FAILURE;
         }

      /* attempt to open handle to existing file */
     if ( ( fileHandle = open( fileName, openFlags, openPermissions ) ) == -1 )
	 		{
			xos_error_sys("xos_mapped_file_open -- file %s could not be opened",
				fileName );
 			return XOS_FAILURE;
			}

		/* set desired size of file if new */
		if ( openMode == XOS_OPEN_NEW )
			{	
			/* set file pointer to the desired end of the database file */
			if ( lseek( fileHandle, mappingSize - 1, SEEK_SET ) == (off_t) -1 )
				{
				xos_error_sys( "xos_mapped_file_open -- error setting size of database file (lseek)" );
				close ( fileHandle );
				return XOS_FAILURE;
				}
				
			/* write a zero at end of file to set the size */
			if ( write( fileHandle, "", 1 ) == -1 ) 
				{			
				xos_error_sys("xos_mapped_file_open -- error setting size of database file (write)" );
				close ( fileHandle );
				return XOS_FAILURE;
				}
			}

      /* attempt to map file to memory */
		if ( ( *mapAddress = mmap( NULL, mappingSize, memoryProtections, 
			mappingFlags, fileHandle, 0 ) ) == (caddr_t) -1 )
			{		
			xos_error_sys("xos_mapped_file_open -- error mapping database to memory");
			close ( fileHandle );
			return XOS_FAILURE;
         }

		/* close the handle to the file */
		close ( fileHandle );

      /* store address and size of map */
      mappedFile->address 		= *mapAddress;
		mappedFile->mappingSize	= mappingSize;
      }
#endif

#ifdef VMS
     {
      /* local variables */
   	struct dsc$descriptor	fileNameDescriptor;
		struct FAB					fab = cc$rms_fab;
		int 							section_flags = SEC$M_EXPREG | SEC$M_WRT;
		vms_memory_range_t		inaddr = { 0, 0};
		struct XABPRO 				xpro = cc$rms_xabpro;
		unsigned short 			xabflag;
		int 							syscallResult;
		
		/* construct descriptor for file name */
		fileNameDescriptor.dsc$a_pointer = (char*) fileName;
		fileNameDescriptor.dsc$w_length	= strlen(fileName);

		/* set protections */
  		xabflag =
        XAB$M_NOWRITE << XAB$V_WLD |
        XAB$M_NOWRITE << XAB$V_GRP |
        XAB$M_NOWRITE << XAB$V_SYS |

        XAB$M_NODEL << XAB$V_WLD |
        XAB$M_NODEL << XAB$V_GRP |
        XAB$M_NOWRITE << XAB$V_WLD;		
        
		xpro.xab$w_pro = xabflag;
		
		/* fill in FAB data structure */
		fab.fab$l_dna = fileNameDescriptor.dsc$a_pointer;
		fab.fab$b_dns = fileNameDescriptor.dsc$w_length;
		fab.fab$l_fna = fileNameDescriptor.dsc$a_pointer;
		fab.fab$b_fns = fileNameDescriptor.dsc$w_length;
		fab.fab$b_rfm = FAB$C_STMLF;
		fab.fab$l_fop = FAB$M_UFO;
		fab.fab$b_fac = FAB$M_GET | FAB$M_PUT;
		fab.fab$b_shr = FAB$M_SHRGET | FAB$M_SHRPUT | FAB$M_UPI;
		fab.fab$l_xab = (char *) &xpro;
		fab.fab$l_alq = mappingSize / 512 + 1;

      /* open or create file as requested */
      switch ( openMode ) 
         {
         case XOS_OPEN_EXISTING:
				if ( ( sys$open( & fab ) & 1 ) != 1 )
					{
					xos_error_sys("xos_mapped_file_open -- file %s could not be opened",
						fileName );
 					return XOS_FAILURE;
 					}            
 				break;
 					
         case XOS_OPEN_NEW:
				if ( ( sys$create( & fab ) & 1 ) != 1 )
					{
					xos_error_sys("xos_mapped_file_open -- file %s could not be created",
						fileName );
 					return XOS_FAILURE;
 					}            
           	break;

         default:
            xos_error("xos_mapped_file_open -- unsupported open mode");
				return XOS_FAILURE;
         }

		
		/* attempt to map file to memory */		
		if (((syscallResult = SYS$CRMPSC( &inaddr, &mappedFile->mapRange,
			0, section_flags, 0, 0, 0, fab.fab$l_stv, 0, 0, 0, 0)) & 1 ) != 1 )
			{		
			xos_error_sys("xos_mapped_file_open -- error mapping memory");
			lib$signal( syscallResult );
			return XOS_FAILURE;
			}
			
	   /* store address and size of map */
  	 	*mapAddress = (void *) mappedFile->mapRange.start;
		mappedFile->mappingSize	= mappingSize;           
		}
#endif
	
	/* report success */
	mappedFile->isValid = TRUE;
	return XOS_SUCCESS;   
	}


/****************************************************************
                     xos_mapped_file_flush
Description:
   This function flushes the memory-mapped file associated with 
   the passed xos_mapped_file_t structure to disk.
   
Return Values:
   XOS_SUCCESS -- the memory map was flushed successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_mapped_file_flush
   (
   xos_mapped_file_t *mappedFile
   )

   {
   /* make sure mapped file is still valid */
   assert ( mappedFile->isValid == TRUE );
 
#ifdef WIN32
	/* attempt to unmap the file from memory */
	if ( FlushViewOfFile( mappedFile->address, 0 ) == FALSE )
 		{
 		xos_error_sys("xos_mapped_file_flush -- error flushing to disk");
 		return XOS_FAILURE;
 		}
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
 	/* synchronize the memory map with the file */
 	if ( msync( mappedFile->address, mappedFile->mappingSize, 
 		MS_SYNC ) != 0 )
 		{
 		xos_error_sys("xos_mapped_file_flush -- error flushing to disk");
 		return XOS_FAILURE;
 		}
#endif

#ifdef VMS
		{
		/* local variables */
		int syscallResult;
	
		/* update section on disk */
		syscallResult = sys$updsecw( &mappedFile->mapRange, 0, 0, 1, 0, 0, 0, 0);
	
		if ( syscallResult != SS$_NORMAL && syscallResult != SS$_NOTMODIFIED )	
			{
 			xos_error_sys("xos_mapped_file_flush -- error flushing to disk");
 			return XOS_FAILURE;
 			}
 		}
 					
#endif
	/* report sucess */
	return XOS_SUCCESS;
   }


/****************************************************************
                     xos_mapped_file_close
Description:
   This function flushes the memory-mapped file associated with 
   the passed xos_mapped_file_t structure to disk and then
   unmaps the file from memory.
   
Return Values:
   XOS_SUCCESS -- the semaphore was closed successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_mapped_file_close
   (
   xos_mapped_file_t *mappedFile
   )

   {
   /* make sure mapped file is still valid */
   assert ( mappedFile->isValid == TRUE );

   /* invalidate the mapped file object */
   mappedFile->isValid = FALSE;

#ifdef WIN32
      /* attempt to unmap the file from memory */
      if ( UnmapViewOfFile( mappedFile->address ) == FALSE )
		{
 		xos_error_sys("xos_mapped_file_close -- error unmapping memory map");
 		return XOS_FAILURE;
 		}
 		
 	/* report success */
 	return XOS_SUCCESS;
#endif


#if defined DEC_UNIX || defined IRIX || defined LINUX
     /* attempt to unmap the file from memory */
      if ( munmap( mappedFile->address, mappedFile->mappingSize ) != 0 )
		{
 		xos_error_sys("xos_mapped_file_close -- error unmapping memory map");
 		return XOS_FAILURE;
 		}
 		
 	/* report success */
 	return XOS_SUCCESS;
#endif

#ifdef VMS
	{
	/* local variables */
	vms_memory_range_t	deletedArea[2];
	
	/* delete the memory map */
	if ( sys$deltva( &mappedFile->mapRange, &deletedArea, 0 ) != SS$_NORMAL )
		{
 		xos_error_sys("xos_mapped_file_close -- error deleting memory map");
 		return XOS_FAILURE;
 		}
 	}
 	/* report success */
   return XOS_SUCCESS;
#endif

   }


/****************************************************************
                     xos_thread_message_send
Description:
   This function sends a XOS message to the thread associated
   with the passed xos_thread_t parameter.  It sends the 
   recipient a 32-bit message ID, the address of a semaphore 
   the recipient can signal the sending thread with, and the 
   address to data associated with the message.  NULL may be
   passed for either of the latter parameters as appropriate.

Return Values:
   XOS_SUCCESS -- the message was sent successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/


xos_result_t xos_thread_message_send
   (
   xos_thread_t      *thread,
   xos_message_id_t  messageID,
   xos_semaphore_t   *semaphore,
   void              *parameters
   )

   {
    assert( thread != NULL );

   /* make sure a valid thread was specified */
   assert ( thread->isValid == TRUE );

   /* need either the address of a valid semaphore or NULL */ 
   assert ( semaphore == NULL || semaphore->isValid == TRUE );

#ifdef WIN32
	/* send the message to the threads posted message queue */
   if ( PostThreadMessage( thread->id, messageID, 
		(WPARAM) semaphore,(LPARAM) parameters ) == FALSE )
		{
		xos_error_sys("xos_thread_message_send -- error posting thread message");
		return XOS_FAILURE;
		}
#endif

#ifdef PTHREAD
	{
   /* local variables */
   xos_thread_message_t		*newMessage;
   
   /* lock mutex */
   if ( xos_mutex_lock( & thread->messageMutex ) != XOS_SUCCESS )
   	{
 		xos_error("xos_thread_message_send -- error locking mutex");
		return XOS_FAILURE;
	  	}
   
	/* allocate memory for thread message */
	if (  ( newMessage = (xos_thread_message_t *) 
   	malloc( sizeof( xos_thread_message_t ) ) ) == NULL )
   	{
   	xos_error("xos_thread_message_send -- error allocating memory" );
   	return XOS_FAILURE;
   	}

   /* fill in data structure */
   newMessage->messageId	= messageID;
   newMessage->semaphore 	= semaphore;
   newMessage->parameters	= parameters;
   newMessage->nextMessage = NULL;

	if ( thread->headMessage == NULL )
		{
   	thread->headMessage = newMessage;
		thread->tailMessage = newMessage;
		}
	else
		/* update linked list pointers */
		{
		/*update the current tail message's next message pointer
		  to point to the next message*/
   	thread->tailMessage->nextMessage = newMessage;
		/*change the tail pointer to point at the new message*/
		thread->tailMessage=newMessage;
		}


	/* post the semaphore */
   if ( xos_semaphore_post( & thread->messageCount ) != XOS_SUCCESS )
   	{
 		xos_error("xos_thread_message_send -- error posting semaphore");
		return XOS_FAILURE;
	  	}
	
   /* unlock mutex */
   if ( xos_mutex_unlock( & thread->messageMutex ) != XOS_SUCCESS )
   	{
 		xos_error("xos_thread_message_send -- error unlocking mutex");
		return XOS_FAILURE;
	  	}
	}
#endif
	/* report success */
	return XOS_SUCCESS;
   }


/****************************************************************
                  xos_thread_message_receive
Description:
   This function reads an XOS message from a thread-specific
   message queue associated with the calling thread.  If the
   queue is empty, the thread sleeps until a message is received.
   When a message is read from the queue, the message ID of the
   message is written the address passed through the pointer
   messageID, the address of the passed semaphore is written to
   semaphore, and the address of the passed data is written to
   parameters.  NULL may be passed for any of the these pointers,
   if the associated information is not needed.

Return Values:
   XOS_SUCCESS -- a message was read successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_thread_message_receive
   (
   xos_thread_t      *thread,
   xos_message_id_t  *messageId,
   xos_semaphore_t   **semaphore,
   void              **parameters
   )

#ifdef WIN32
   {
   /* local variables */
   MSG windowsMessage;

   /* send the message to the threads posted message queue */
	if ( GetMessage( &windowsMessage, NULL, 0, 0 ) == -1 )
		{
		xos_error_sys("xos_thread_message_receive -- error getting message");
      return XOS_FAILURE;
		}

   /* extract message ID from windows message if requested */
   if ( messageId != NULL )
      *messageId  = windowsMessage.message;

   /* extract address of semaphore from message if requested */
   if ( semaphore != NULL )
      *semaphore  = (xos_semaphore_t*) windowsMessage.wParam;
   
   /* extract address of parameters from message if requested */
   if ( parameters != NULL )
      *parameters = (void*) windowsMessage.lParam;

   /* report success */
   return XOS_SUCCESS;
   }

#endif

#ifdef PTHREAD
	{
   /* local variables */
   xos_thread_message_t		*message;

	/* wait for semaphore */
   if ( xos_semaphore_wait( & thread->messageCount, 0 ) != XOS_SUCCESS )
   	{
 		xos_error("xos_thread_message_receive -- error waiting for semaphore");
		return XOS_FAILURE;
	  	}
  
   /* lock mutex */
   if ( xos_mutex_lock( & thread->messageMutex ) != XOS_SUCCESS )
   	{
 		xos_error("xos_thread_message_receive -- error locking mutex");
		return XOS_FAILURE;
	  	}
 	
 	/* get pointer to message */
 	message = thread->headMessage;
 
   /* extract message ID from message if requested */
   if ( messageId != NULL )
      *messageId  = message->messageId;

   /* extract address of semaphore from message if requested */
   if ( semaphore != NULL )
      *semaphore  = message->semaphore;
   
   /* extract address of parameters from message if requested */
   if ( parameters != NULL )
      *parameters = message->parameters;
	
   /* update linked list pointer */
   thread->headMessage = thread->headMessage->nextMessage;

	/* free memory holding thread message */
	free( message );
   
   /* unlock mutex */
   if ( xos_mutex_unlock( & thread->messageMutex ) != XOS_SUCCESS )
   	{
 		xos_error("xos_thread_message_receive -- error unlocking mutex");
		return XOS_FAILURE;
	  	}
	
	/* report success */
	return XOS_SUCCESS;
	}
#endif



/****************************************************************
                     xos_message_queue_create
Description:
   This function constructs the passed xos_message_queue_t object
   by creating a message queue and storing handles for reading and
	writing the queue.  Mutexes for reading and writing are also
	initialized.  The queue name is used only on some platforms.
	Messages are fixed in size for a particular queue.

Parameters:
   messageQueue
      Pointer to xos_message_queue_t.
	maxMessages
		Number of messages that can be stored in the queue at the
		same time.
	messageSize
		Size of each message in the queue.

Return Values:
   XOS_SUCCESS -- the message queue was created successfully.
   XOS_FAILURE -- an error occurred creating the queue.
****************************************************************/

xos_result_t xos_message_queue_create
	(
	xos_message_queue_t 	*messageQueue,
	xos_index_t				maxMessages,
	xos_size_t				messageSize
	)

	{
	/* make sure passed arguments are valid */
	assert( messageQueue != NULL );
	assert( maxMessages > 0 );
	assert( messageSize > 0 );
	
	/* initialize message indices */
	messageQueue->isValid		= FALSE;
	messageQueue->maxMessages	= maxMessages;
	messageQueue->messageSize	= messageSize;
	
	/* allocate memory for message queue */
	if ( ( messageQueue->startAddress = malloc ( messageSize * maxMessages ) ) == NULL )
  		{
	  	xos_error("xos_message_queue_create -- error allocating memory");
	 	return XOS_FAILURE;
	 	}
	 
	/* calculate address of last byte in buffer */	
   messageQueue->endAddress 	= messageQueue->startAddress + 
   	messageSize * maxMessages - 1;
   		
	/* initialize the queue read mutex */
	if ( xos_mutex_create( &messageQueue->readMutex ) == XOS_FAILURE )
  		{
	  	xos_error("xos_message_queue_create -- error initializing read mutex");
	 	return XOS_FAILURE;
	 	}

	/* initialize the queue write mutex */
	if ( xos_mutex_create( &messageQueue->writeMutex ) == XOS_FAILURE )
  		{
	  	xos_error("xos_message_queue_create -- error initializing write mutex");
	 	return XOS_FAILURE;
	 	}	
   
   /* initialize message slots used semaphore */
   if ( xos_semaphore_create( & messageQueue->messageSlotsUsed, 0 ) != XOS_SUCCESS )
   	{
   	xos_error( "xos_message_queue_create -- error creating slots used semaphore");
   	return XOS_FAILURE;
   	}

   /* initialize message slots used semaphore */
   if ( xos_semaphore_create( & messageQueue->messageSlotsFree, maxMessages ) != XOS_SUCCESS )
   	{
   	xos_error( "xos_message_queue_create -- error creating slots used semaphore");
   	return XOS_FAILURE;
   	}	

   /* report success */
	messageQueue->firstMessage	= messageQueue->startAddress;
	messageQueue->lastMessage	= messageQueue->startAddress;
   messageQueue->isValid = TRUE;
   return XOS_SUCCESS;
	}

/****************************************************************
                     xos_message_queue_write
Description:
   This function writes a message to the queue associated
   with the passed xos_message_queue_t parameter.  It copies
	the message from the passed buffer, taking a number of bytes
	equal the message size specified when the queue was created.
	A mutex protects the queue from being written to by multiple
	threads at the same time.  If the queue is full, this function
	blocks until a message is read from the queue.

Return Values:
   XOS_SUCCESS -- the message was written successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_message_queue_write
	(
	xos_message_queue_t 	*messageQueue,
	const char *			buffer
	)
	
	{
	/* make sure passed parameters are valid */
	assert ( messageQueue != NULL );
	assert ( messageQueue->isValid == TRUE );
	assert ( buffer != NULL );

	/* acquire the mutex for writing the message queue */
	if ( xos_mutex_lock( &messageQueue->writeMutex ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_write -- error locking write mutex");
		return XOS_FAILURE;
		};

	/* wait for an empty slot to write message in */
	if ( xos_semaphore_wait( &messageQueue->messageSlotsFree, 0 ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_write -- error waiting for empty slot");
		return XOS_FAILURE;
		};
	
	/* copy message into queue */
	memcpy( messageQueue->firstMessage, buffer, messageQueue->messageSize );
	
	/* update first message pointer */
	messageQueue->firstMessage += messageQueue->messageSize;
	
	/* wrap message buffer */
	if ( messageQueue->firstMessage > messageQueue->endAddress )
		messageQueue->firstMessage = messageQueue->startAddress;
	
	/* increment the message count */
	if ( xos_semaphore_post( &messageQueue->messageSlotsUsed ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_write -- error posting slots used semaphore");
		return XOS_FAILURE;
		};
				
	/* release the mutex for writing the message queue */
	if ( xos_mutex_unlock(&messageQueue->writeMutex ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_write -- error unlocking write mutex");
		return XOS_FAILURE;
		};
			
   /* report success */
   return XOS_SUCCESS;
	}
	

/****************************************************************
                     xos_message_queue_read
Description:
   This function reads a message from the queue associated
   with the passed xos_message_queue_t parameter.  It copies
	the message into the passed buffer, taking a number of bytes
	equal the message size specified when the queue was created.
	A mutex protects the queue from being read by multiple
	threads at the same time.  If there are no messages in the
	queue, this function blocks until a message is written to
	the queue.

Return Values:
   XOS_SUCCESS -- the message was read successfully.
   XOS_FAILURE -- an error occurred.
****************************************************************/

xos_result_t xos_message_queue_read
	(
	xos_message_queue_t 	*messageQueue,
	char *					buffer
	)

	{
	/* make sure passed parameters are valid */
	assert ( messageQueue != NULL );
	assert ( messageQueue->isValid == TRUE );
	assert ( buffer != NULL );

	/* acquire the mutex for reading the message queue */
	if ( xos_mutex_lock( &messageQueue->readMutex ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_read -- error locking read mutex");
		return XOS_FAILURE;
		};

	/* wait for a messagae */
	if ( xos_semaphore_wait( &messageQueue->messageSlotsUsed, 0 ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_read -- error waiting for a message");
		return XOS_FAILURE;
		};
	
	/* copy message into buffer */
	memcpy( buffer, messageQueue->lastMessage, messageQueue->messageSize );
	
	/* update last message pointer */
	messageQueue->lastMessage += messageQueue->messageSize;
	
	/* wrap message buffer */
	if ( messageQueue->lastMessage > messageQueue->endAddress )
		messageQueue->lastMessage = messageQueue->startAddress;
	
	/* increment the slot free count */
	if ( xos_semaphore_post( &messageQueue->messageSlotsFree ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_read -- error posting slots free semaphore");
		return XOS_FAILURE;
		};
				
	/* release the mutex for reading the message queue */
	if ( xos_mutex_unlock(&messageQueue->readMutex ) != XOS_SUCCESS )
		{
		xos_error("xos_message_queue_read -- error unlocking read mutex");
		return XOS_FAILURE;
		};
			
   /* report success */
   return XOS_SUCCESS;
	}



/****************************************************************
                     xos_message_queue_destroy
Description:
   This function destroys the passed xos_message_queue_t object
   by closing the handles for reading and writing the queue.  
	The mutexes for reading and writing are also closed. 

Return Values:
   XOS_SUCCESS -- the message queue was destroyed successfully.
   XOS_FAILURE -- an error occurred destroying the queue.
****************************************************************/
		
xos_result_t xos_message_queue_destroy
	(
	xos_message_queue_t 	*messageQueue
	)

	{
	/* make sure passed parameters are valid */
	assert ( messageQueue != NULL );
	assert ( messageQueue->isValid == TRUE );

	/* invalidate the message queue structure */
	messageQueue->isValid = FALSE;

	/* free memory for message queue */
	free(messageQueue->startAddress );

	/* close the queue read mutex */
	if ( xos_mutex_close( &messageQueue->readMutex ) == XOS_FAILURE )
  		{
	  	xos_error("xos_message_queue_destroy -- error closing read mutex");
	 	return XOS_FAILURE;
	 	}

	/* close the queue write mutex */
	if ( xos_mutex_close( &messageQueue->writeMutex ) == XOS_FAILURE )
  		{
	  	xos_error("xos_message_queue_destroy -- error closing write mutex");
	 	return XOS_FAILURE;
	 	}	
   
   /* close message slots used semaphore */
   if ( xos_semaphore_close( & messageQueue->messageSlotsUsed ) != XOS_SUCCESS )
   	{
   	xos_error( "xos_message_queue_destroy -- error closing slots used semaphore");
   	return XOS_FAILURE;
   	}

   /* close message slots used semaphore */
   if ( xos_semaphore_close( & messageQueue->messageSlotsFree ) != XOS_SUCCESS )
   	{
   	xos_error( "xos_message_queue_destroy -- error closing slots used semaphore");
   	return XOS_FAILURE;
   	}

	/* report success */
	return XOS_SUCCESS;	
	}



xos_result_t xos_clock_reset
	(
	xos_clock_t		* xosClock
	)
	
	{
	/* local variables */
	clock_t 	clockNow;
	time_t	timeNow;
	
	/* get current clock() value */
	if ( ( clockNow = clock() ) == (clock_t) -1 )
		{
		xos_error("xos_clock_reset -- error in clock()" );
		return XOS_FAILURE;
		}
		 
	/* get current time() value */
	if ( ( timeNow = time(NULL) ) == -1 )
		{
		xos_error("xos_clock_reset -- error in time()" );
		return XOS_FAILURE;
		}
	
	xosClock->startTicks = clockNow;
	xosClock->startSeconds = timeNow;
	return XOS_SUCCESS;
	}


double xos_clock_get_cpu_time
	(
	xos_clock_t		* xosClock
	)
	
	{
	/* local variables */
	clock_t 	clockNow;

	/* get current clock() value */
	if ( ( clockNow = clock() ) == (clock_t) -1 )
		{
		xos_error("xos_clock_get_cpu_time -- error in clock()" );
		return -1;
		}

	return difftime( clockNow ,xosClock->startTicks) / XOS_CLOCK_CONSTANT;
	}


time_t xos_clock_get_real_time
	(
	xos_clock_t		* xosClock
	)
	
	{
	/* local variables */
	time_t	timeNow;

	/* get current time() value */
	if ( ( timeNow = time(NULL) ) == -1 )
		{
		xos_error("xos_clock_get_real_time -- error in time()" );
		return XOS_FAILURE;
		}

	return timeNow - xosClock->startSeconds ;
	}


/* win32 specific helper functions */

#ifdef WIN32

xos_wait_result_t win32_object_wait
   (
   HANDLE      handle,
   xos_time_t  timeout
   )
   
   {
   /* local variables */
   DWORD syscallResult;
   
   /* make sure non-negative value passed */
   assert ( timeout >= 0 );

   /* time-out of zero means wait forever */
   if ( timeout == 0 )
      timeout = INFINITE;

   /* wait for the semaphore */
   syscallResult= WaitForSingleObject( handle, timeout );

   switch ( syscallResult ) {

      case WAIT_OBJECT_0:
         /* semaphore posted */
         return XOS_WAIT_SUCCESS;

      case WAIT_TIMEOUT:
         /* wait timed out */
			xos_error("win32_object_wait -- wait timed out");
         return XOS_WAIT_TIMEOUT;

      case WAIT_FAILED:
         /* wait errored */
			xos_error_sys("win32_object_wait -- error waiting on object");
         return XOS_WAIT_FAILURE;
   
      default:
         /* unhandled return value */
			xos_error("win32_object_wait -- invalid return value from Win32");
			return XOS_WAIT_FAILURE;
		}
   }


xos_wait_result_t win32_object_trywait
   (
   HANDLE      handle
   )
   
   {
   
   /* local variables */
   DWORD syscallResult;
   xos_time_t  timeout = 0;

   
   /* make sure non-negative value passed */
   assert ( timeout >= 0 );

   /* wait for the semaphore */
   syscallResult= WaitForSingleObject( handle, timeout );
   
   if (syscallResult == WAIT_OBJECT_0)
   	return XOS_SUCCESS;
   	
   	
   return XOS_FAILURE;
   
   
   }

xos_result_t win32_object_close
   (
   HANDLE handle
   )
   
   {
   /* close handle to the object */
	if ( CloseHandle( handle ) != TRUE )
		{
		xos_error_sys("win32_object_close -- error closing handle");
      return XOS_FAILURE;
		}

	/* report success */
   return XOS_SUCCESS;
   }

#endif


/* Nonfatal error related to a system call.
 * Print a message and return. */

void xos_error_sys(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(1, fmt, ap);
   va_end(ap);
   return;
}


/* Fatal error related to a system call.
 * Print a message and terminate. */

void xos_error_sys_exit(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(1, fmt, ap);
   va_end(ap);
   exit(1);
}
/* Thread fatal error related to a system call.
 * Print a message and terminate thread. */


void xos_error_sys_thread_exit(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(1, fmt, ap);
   va_end(ap);
   xos_thread_exit();
}


/* Fatal error related to a system call.
 * Print a message, dump core, and terminate. */

void xos_error_sys_abort(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(1, fmt, ap);
   va_end(ap);
   abort();    /* dump core and terminate */
   exit(1);    /* shouldn't get here */
}



/* Fatal error related to a system call.
 * Print a message, dump core, and terminate. */

void xos_error_abort(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(0, fmt, ap);
   va_end(ap);
   abort();    /* dump core and terminate */
   exit(1);    /* shouldn't get here */
}


/* Nonfatal error unrelated to a system call.
 * Print a message and return. */

void xos_error(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(0, fmt, ap);
   va_end(ap);
   return;
}


/* Fatal error unrelated to a system call.
 * Print a message and terminate. */

void xos_error_exit(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(0, fmt, ap);
   va_end(ap);
   exit(1);
}


/* Thread fatal error unrelated to a system call.
 * Print a message and terminate thread. */

void xos_error_thread_exit(const char *fmt, ...)
{
   va_list     ap;

   va_start(ap, fmt);
   xos_vprint_error(0, fmt, ap);
   va_end(ap);
   xos_thread_exit();
}

/**
 * @var err_stream
 * @brief an error stream used by xos_vprint_error.
 *
 * An application can set this stream to any file stream by calling
 * xos_set_err_stream() or reset the stream to stderr by calling
 * xos_reset_err_stream().
 *
 */
static FILE* err_stream = NULL;
static int want_output = 1;
/**
 * @fn xos_set_err_stream
 * @brief A function to set error stream to a file stream.
 *
 * By default the error stream is stderr. An application can
 * to disable the error being printed out completely
 * by open a file stream to /dev/null.
 * @param s File stream to be used as error stream.
 */
void xos_error_set_stream(FILE* s)
{
	err_stream = s;
	
	if (err_stream == NULL)
		want_output = 0;
}

/**
 * @fn xos_reset_err_stream
 * @brief A function to reset error stream to a stderr.
 *
 */
void xos_error_reset_stream()
{
    err_stream = stderr;
}

/* Print a message and return to caller.
 * Caller specifies "errnoflag". */
static void xos_vprint_error(int errnoflag, const char *fmt, va_list ap)
{
   int   errno_save;
   char  buf[200];

   if (!want_output)
        return;
   
   if (!err_stream)
	   err_stream = stderr;

   errno_save = ERRNO;     /* value caller might want printed */
   vsprintf(buf, fmt, ap);
   if (errnoflag)
      sprintf(buf+strlen(buf), ": %s (%d)",
      strerror(errno_save), errno_save);
   strcat(buf, "\n");
   fputs(buf, err_stream);
   fflush(err_stream);     /* flushes all stdio output streams */
   return;
}
#ifdef PTHREAD
void restart_in_daemon( int argc, char* argv[] )
{
    pid_t i;
    if (getppid( ) == 1)
    {
        //already a daemon
        return;
    }
    //copied from unix command "setsid"
    i = fork();
    switch(i){
    case -1:
        perror("fork");
        exit(1);

    case 0:
        break;

    default:    /* parent */
        printf("daemon PID=%d\n", i);
        exit(0);
    }

    setsid();  /* no error possible */
    freopen("/dev/null", "r", stdin);
    freopen("/dev/null", "w", stdout);
    freopen("/dev/null", "w", stderr);

    execvp(argv[0], argv);
    //shoud never return

    perror("execvp");
    exit(1);
}


void daemonize_save_output( const char* filename )
{
    int i = -1;

    if (getppid( ) == 1)
    {
        //already a daemon
        return;
    }

    i = fork( );
    if (i < 0)
    {
        printf( "fork failed\n" );
        exit(1);
    }
    else if (i > 0)
    {
        printf( "daemon pid %d\n", i );
        exit(0);
    }

    /////////////////DAEMIN CODE/////////////////

    setsid( );

    // close all files
    for (i = getdtablesize( ) - 1; i >= 0; --i)
    {
        close(i);
    }
    //open std IO
    i = open( filename, O_RDWR );
    dup( i );
    dup( i );
}
void daemonize( ) {
    daemonize_save_output( "/dev/null" );
}
FILE* checkLockFile( const char* lockFileName )
{
    FILE *lockFileHandle = NULL;
    struct stat statbuf;

    if (lockFileName == NULL || lockFileName[0] == '\0')
    {
        return NULL;
    }
    /* secure coding */
    /* open without touching contents of the file
     * to prevent tmp file hacker
     */

    lockFileHandle = fopen( lockFileName, "r+" );
    if (lockFileHandle == NULL)
    {
        if (errno == ENOENT) {
            lockFileHandle = fopen( lockFileName, "w" );
        }
    }
    if (lockFileHandle == NULL)
    {
        printf( "open lock file failed\n" );
        return NULL;
    }

    /* secure coding */
    /*
     * fail in following situation
     * alarm if running as root
     ***************************
     * if it is not normal file
     * if its number of hard links >1
     * if its size > 1k
     * if not owner
     *
     */
    if (lstat( lockFileName, &statbuf )) {
        fclose( lockFileHandle );
        printf( "stat lock file failed\n" );
        return NULL;
    }
    if (!S_ISREG(statbuf.st_mode) || statbuf.st_nlink > 1 ||
    statbuf.st_size > 1024 || statbuf.st_uid != geteuid( )
    ) {
        if (getuid() < 500 || geteuid( ) < 500) {
#ifndef Win32
            syslog( LOG_AUTHPRIV | LOG_WARNING,
                "maybe tmp file hacker using DCS"
            );
#endif
        }
        fclose( lockFileHandle );
        printf( "security check failed\n" );
        return NULL;
    }


    if (lockf( fileno( lockFileHandle ), F_TLOCK, 0))
    {
        printf( "lock lock file failed\n" );
        fclose( lockFileHandle );
        return NULL;
    }

    //now truncate that file
    if (ftruncate( fileno( lockFileHandle ), 0 )) {
        printf( "truncate lock file failed\n" );
        fclose( lockFileHandle );
        return NULL;
    }

    //tell watcher to wait us to start
    fprintf( lockFileHandle, "w" );
    fflush( lockFileHandle );
    chmod( lockFileName, 0744 );

    return lockFileHandle;
}
void updateLockFile( FILE* handle )
{
    if (fseek( handle, 0, SEEK_SET )) {
        return;
    }
    fprintf( handle, "%u", getpid( ) );
    fflush( handle );
}
void releaseLockFile( FILE* handle )
{
    /* secure coding */
    /* do not delete file if not necessary */
    fclose( handle );
}
#endif

char* my_fgets( char* buffer, int max_len, int fd ) {
    int i = 0;

    if (max_len < 1) return NULL;

    memset(buffer, 0, max_len);

    --max_len;

    while (i < max_len) {
        size_t nRead = read( fd, buffer+i, 1 );
        if (nRead <= 0) {
            if (i <= 0)
	    	return NULL;
        }

        if (buffer[i] == '\n') {
            break;
        }
        ++i;
    }
//    if (i <= 0) return NULL;

    return buffer;
}
