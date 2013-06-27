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


#ifndef DHS_CONFIG_H
#define DHS_CONFIG_H

#include "xos.h"
#include "xos_semaphore_set.h"
#include "dhs_threads.h"

typedef struct 
	{
	xos_thread_t		*pThread;
	xos_semaphore_t	*semaphorePointer;
	xos_iterator_t    threadIterator;
	} dhs_thread_init_t;


xos_result_t dhs_config_initialize( threadList &controllerList );

xos_result_t dhs_config_read_file( 
	const char * configFileName 
	);

xos_iterator_t dhs_config_get_next_thread_entry( 
	xos_iterator_t		* iteratorPtr
	);

xos_iterator_t dhs_config_get_next_card_entry( 
	xos_iterator_t		* iteratorPtr
	);
	
xos_iterator_t dhs_config_get_next_device_entry( 
	xos_iterator_t		* iteratorPtr
	);


const char * dhs_config_get_token( 
	xos_index_t line, 
	xos_index_t token
	);


xos_index_t dhs_config_get_token_count ( 
	xos_index_t line 
	);


#endif
