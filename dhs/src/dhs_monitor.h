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


/* DHS_MONITOR.H */
#include "dhs_threads.h"

#ifndef MONITOR_THREAD
#define MONITOR_THREAD 0
#define WM_USER 0

#define DHS_CONTROLLER_MESSAGE_BASE (WM_USER + 512)

typedef struct
	{
	xos_semaphore_t	semaphore;
	xos_time_t   devicePollingPeriod;
	} MonitorThreadStruct;


XOS_THREAD_ROUTINE dhs_device_polling_thread_routine(
	MonitorThreadStruct * monitorThreadInitData
	);

XOS_THREAD_ROUTINE dhs_watchdog_thread_routine(void *param);


// message specifically for controller

#endif
