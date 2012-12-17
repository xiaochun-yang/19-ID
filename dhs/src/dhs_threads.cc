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

/*
This class keeps a list of threads that have declared themselves.
*/
#include "xos.h"
#include "xos_semaphore_set.h"

#include "dhs_messages.h"
#include "dhs_threads.h"


/*CODE REVIEW 7: make this a constructor*/
/*do this before adding any threads to the list*/
xos_result_t threadList::initialize(xos_index_t MaxThread)
	{
	threadCount = 0;
	/*CODE REVIEW 6: maxThreadCnt not used anywhere except this routine*/
	maxThreadCnt = MaxThread;
	
	/* initialize mutex to protect list during modifications */
	if ( xos_mutex_create( &threadListMutex ) == XOS_FAILURE )
		{
			xos_error_exit("dhs_threadlist constructor:  "
								"Could not create the threadList critical section mutex.");
		}
	
  	/* create a set of semaphores */
  	if ( xos_semaphore_set_create( & semaphoreSet, maxThreadCnt ) == XOS_FAILURE )
  		{
			xos_error_exit( "dhs_threadList Constructor:  error creating semaphore set");
		}
	//printf ("created semaphore set at %x\n",semaphoreSet);
	
	return (XOS_SUCCESS);
	}




/*add a thread to the list*/
xos_result_t	threadList::addThread(xos_thread_t *pThread)
	{

	/*CODE REVIEW 8: XOS failure can occur here*/
	/*enter critical section*/
  	xos_mutex_lock( & threadListMutex );
	
	/*CODE REVIEW 10: check for end of array*/
	threadArray[threadCount] = pThread;
	
	threadCount++;
	
	/*CODE REVIEW 9: XOS failure can occur here*/
	/* leave critical section */
	xos_mutex_unlock( & threadListMutex );
	
	return(XOS_SUCCESS);
	}


/*This member function sends a single message to all threads
  in the list.*/
xos_result_t threadList::sendMessage( dhs_message_id_t 	messageID,
												  void					*message,
												  xos_time_t	  		timeout )
	{
	xos_index_t				cnt;
	xos_semaphore_t		*pSemaphore;
	
	/* initialize set of semaphores */
	if ( xos_semaphore_set_initialize( &semaphoreSet ) == XOS_FAILURE )
		{
			xos_error("threadList:  error initializing semaphore set.");
			return XOS_FAILURE;
	  	}
	
	for( cnt = 0 ; cnt < threadCount ; cnt++)
		{
			
			/* get the next semaphore */
		
			if ( xos_semaphore_set_get_next( & semaphoreSet, & pSemaphore ) != XOS_SUCCESS )
				{
				xos_error("threadList:sendMessage:  cannot get semaphore." );
				return XOS_FAILURE;
				}
			
			//		  			printf("cnt: %d, threadArray: %d, messageID: %d, pSemaphore: %d, message: %d\n",cnt, threadArray[cnt], (int)(dhs_message_id_t) messageID,
			//									pSemaphore, message );
			
			/* send message to device's thread */
			if ( xos_thread_message_send( threadArray[cnt], messageID,
													pSemaphore, message ) == XOS_FAILURE )
				{
				xos_error("threadList.sendMessage:  error waiting for threads to respond." );
				return XOS_FAILURE;
				}
			//	printf("threadList.sendMessage: sent message with semaphore %x\n", (int)pSemaphore);
		}
	
	/* wait up to "timeout" for threads to signal that they received message */
	/*printf("wait for semaphore set at %x\n",(int)&semaphoreSet);*/
		if ( xos_semaphore_set_wait( & semaphoreSet, timeout ) != XOS_WAIT_SUCCESS )
		{
			xos_error("threadList Object:  error waiting for threads to respond." );
			return XOS_FAILURE;
		}
	
	return XOS_SUCCESS;
	}




/*thread list destructor*/

threadList::~threadList()
	{
  	/* deallocate the set of semaphores */
  	if ( xos_semaphore_set_destroy( & semaphoreSet ) == XOS_FAILURE )
  		{
			xos_error( "threadList destructor:  error destroying semaphore set");
			/*sorry, program is going to die now..*/
  		};
	}






