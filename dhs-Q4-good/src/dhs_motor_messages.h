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


#ifndef DHS_MOTOR_MESSAGES_H
#define DHS_MOTOR_MESSAGES_H


extern "C" {
#include "xos.h"
}
#include "dcs.h"


xos_result_t stoh_register_operation( 
	xos_index_t			deviceIndex, 
	dcs_device_type_t	deviceType, 
	xos_thread_t		*deviceThread );

xos_result_t stoh_register_string( 
	xos_index_t			deviceIndex, 
	dcs_device_type_t	deviceType, 
	xos_thread_t		*deviceThread );

xos_result_t stoh_start_operation( 
	xos_index_t deviceIndex, 
	dcs_device_type_t	deviceType, 
	xos_thread_t		*deviceThread );

xos_result_t stoh_register_ion_chamber( 
	xos_index_t			deviceIndex, 
	dcs_device_type_t	deviceType, 
	xos_thread_t		*deviceThread );

xos_result_t stoh_read_ion_chambers( 
	xos_index_t			deviceIndex, 
	dcs_device_type_t	deviceType, 
	xos_thread_t		*deviceThread );

xos_result_t stoh_register_real_motor(
	xos_index_t			deviceIndex, 
	dcs_device_type_t deviceType, 
	xos_thread_t		*deviceThread
	);

xos_result_t stoh_configure_real_motor(
	xos_index_t			deviceIndex, 
	dcs_device_type_t deviceType, 
	xos_thread_t		*deviceThread
	);

xos_result_t stoh_start_motor_move(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	);


xos_result_t stoh_abort_motor_move(
	xos_index_t			deviceIndex,
	dcs_device_type_t deviceType,
	xos_thread_t		*deviceThread
	);

xos_result_t stoh_set_motor_position(
	xos_index_t			deviceIndex, 

	dcs_device_type_t deviceType, 

	xos_thread_t		*deviceThread

	);

xos_result_t stoh_correct_motor_position(
	xos_index_t			deviceIndex, 

	dcs_device_type_t deviceType, 

	xos_thread_t		*deviceThread

	);


xos_result_t stoh_abort_all ( void );

xos_result_t stoh_register_shutter( xos_index_t			deviceIndex, 
												dcs_device_type_t deviceType,
												xos_thread_t		*deviceThread );


xos_result_t stoh_set_shutter_state ( xos_index_t			deviceIndex,
												  dcs_device_type_t deviceType,
												  xos_thread_t		*deviceThread );


xos_result_t stoh_start_oscillation(
	xos_index_t			deviceIndex, 
	dcs_device_type_t deviceType, 
	xos_thread_t		*deviceThread
	);

xos_result_t stoh_start_vector_move(
	xos_index_t			deviceIndex_1, 
	dcs_device_type_t deviceType_1,
	xos_thread_t		*deviceThread
	);

xos_result_t stoh_stop_vector_move(
	xos_index_t			deviceIndex_1, 
	dcs_device_type_t deviceType_1,
	xos_thread_t		*deviceThread
	);

xos_result_t stoh_change_vector_speed(
	xos_index_t			deviceIndex_1,
	dcs_device_type_t deviceType_1, 
	xos_thread_t		*deviceThread
	);


xos_result_t stoh_register_encoder( xos_index_t			deviceIndex, 
												dcs_device_type_t deviceType, 
												xos_thread_t		*deviceThread );

xos_result_t stoh_set_encoder( xos_index_t			deviceIndex, 
										 dcs_device_type_t   deviceType, 
										 xos_thread_t		  *deviceThread );

xos_result_t stoh_get_encoder( xos_index_t			deviceIndex, 
										 dcs_device_type_t   deviceType, 
										 xos_thread_t		  *deviceThread );

#endif
