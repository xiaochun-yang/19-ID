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
							xos_semaphore_set.h
								
	This header file is included by xos_semaphore_set.c and any 
	source file that use functions defined therein.	 This file
	defines the xos_semaphore_set_t abstract data type which
	encapsulates a set of XOS semaphores and operations that may
	be performed on them.
	
	Author:				Timothy M. McPhillips, SSRL.
	Last Revision:		March 1, 1998 by TMM.
	
****************************************************************/

#ifndef XOS_SEMAPHORE_SET_H
#define XOS_SEMAPHORE_SET_H

/* include the master XOS file */
#include "xos.h"

#ifdef __cplusplus
extern "C" {
#endif

/* define the xos_semaphore_set_t data type */
typedef struct {
	xos_semaphore_t	*semaphoreArray;
	unsigned int		semaphoreCount;
	unsigned int		useCount;
	xos_boolean_t		isValid;
	} xos_semaphore_set_t;


/* declare public functions */

xos_result_t xos_semaphore_set_create
	(
	xos_semaphore_set_t	*semaphoreSet,
	unsigned int			semaphoreCount
	);

xos_result_t xos_semaphore_set_initialize
	(
	xos_semaphore_set_t	*semaphoreSet
	);

xos_result_t xos_semaphore_set_get_next
	(
	xos_semaphore_set_t	*semaphoreSet,
	xos_semaphore_t		**semaphorePointer
	);

xos_wait_result_t xos_semaphore_set_wait
	(
	xos_semaphore_set_t	*semaphoreSet,
	xos_time_t				timeout
	);

xos_result_t xos_semaphore_set_destroy
	(
	xos_semaphore_set_t	*semaphoreSet
	);
	
#ifdef __cplusplus
}
#endif

	
#endif
