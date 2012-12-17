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


#ifndef DHS_THREADS_H
#define DHS_THREADS_H
#include "xos_semaphore_set.h"
#include "dhs_messages.h"

class threadList
	{
	private:
	xos_thread_t			*threadArray[64];

	xos_mutex_t				threadListMutex;
	xos_index_t				threadCount;
	xos_semaphore_set_t	semaphoreSet;
	xos_index_t				maxThreadCnt;


	public:
	/*member functions*/
	xos_result_t addThread(xos_thread_t *pThread);	
	xos_result_t initialize(xos_index_t MaxThread);

	xos_result_t sendMessage( dhs_message_id_t	messageID,
									  void					*message,
									  xos_time_t	  		timeout );

	/*constructor & destructor*/
	~threadList(void);
	};

#endif
