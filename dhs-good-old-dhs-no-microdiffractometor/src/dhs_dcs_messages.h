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


#ifndef DHS_DCS_MESSAGES_H
#define DHS_DCS_MESSAGES_H

extern "C" {
#include "xos.h"
}
#include "dcs.h"

/* general message handler type definition */
typedef xos_result_t (dcs_general_message_handler_t)
	(
	void
	);

/* device message handler type definition */
typedef xos_result_t (dcs_device_message_handler_t)
	( 
	xos_index_t			deviceIndex, 
	dcs_device_type_t deviceType, 
	xos_thread_t		*deviceThread
	);

/* publice function declarations */

xos_result_t dhs_dcs_messages_initialize
	( 
	void 
	);

xos_result_t dhs_dcs_message_dispatch
	( 
	char *message 
	);




#endif
