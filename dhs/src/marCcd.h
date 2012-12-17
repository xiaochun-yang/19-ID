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


// *******************
// dhs_MarCcd.h
// *******************

#ifndef DHS_MARCCD_DETECTOR_H
#define DHS_MARCCD_DETECTOR_H

#include "dhs_detector.h"

typedef enum
	{
	NORMAL				= 0,
	DEZINGER				= 1,
	INVALID_MODE      = 3
	} marCcd_mode_t;


/* Task numbers */
#define TASK_ACQUIRE            0
#define TASK_READ               1
#define TASK_CORRECT            2
#define TASK_WRITE              3
#define TASK_DEZINGER           4

/* The status bits for each task are: */
/* Task Status bits */
#define TASK_STATUS_QUEUED      0x1
#define TASK_STATUS_EXECUTING   0x2
#define TASK_STATUS_ERROR       0x4
#define TASK_STATUS_RESERVED    0x8

#define TASK_STATE_BUSY 8

/* These are the definitions of masks for looking at task state bits */
#define STATE_MASK              0xf
#define STATUS_MASK             0xf
#define TASK_STATUS_MASK(task)  (STATUS_MASK << (4*((task)+1)))

/* These are some convenient macros for checking and setting the state of each task */
/* They are used in the marccd code and can be used in the client code */
#define TASK_STATE(current_status) ((current_status) & STATE_MASK)
#define TASK_STATUS(current_status, task) (((current_status) & TASK_STATUS_MASK(task)) >> (4*((task) + 1)))
#define TEST_TASK_STATUS(current_status, task, status) (TASK_STATUS(current_status, task) & (status))


// public function declarations

XOS_THREAD_ROUTINE MarCcdControlThread( void * arg );
XOS_THREAD_ROUTINE MarCcdThread( void * parameter);


#endif
