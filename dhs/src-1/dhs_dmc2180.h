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





#ifndef DHS_DMC2180_H
#define DHS_DMC2180_H

#include <string>
#include <dmc2180API.h>
#include <time.h>

#define DMC2180_MAX_AXES	8
#define DMC2180_MAX_SHUTTERS 8
#define DMC2180_MAX_ENCODERS 8

#define SCALED2UNSCALED(position,scaleFactor) ( (dcs_unscaled_t)floor(position*scaleFactor + 0.5) )

XOS_THREAD_ROUTINE dmc2180_unsolicited_handler( void *arg );


/* private function declarations */
xos_result_t dmc2180_get_configuration( Dmc2180 & dmc2180 );

xos_result_t dmc2180_get_script( Dmc2180 & dmc2180, char * scriptName  );

xos_result_t dmc2180_initialize( Dmc2180				& dmc2180 );

xos_result_t dmc2180_messages( xos_thread_t	*pThread,
							  Dmc2180 & dmc2180 );

xos_result_t dmc2180_motor_messages( dhs_message_id_t	messageID, 
												 xos_semaphore_t	*semaphore, 
												 void					*message );

xos_result_t dmc2180_motor_start_move( dhs_motor_start_move_message_t	*message, 
													xos_semaphore_t						*semaphore );
xos_result_t dmc2180_motor_start_home( dhs_motor_start_move_message_t   *message,

                        xos_semaphore_t                                         *semaphore );
xos_result_t dmc2180_motor_start_script( dhs_motor_start_move_message_t   *message,

    xos_semaphore_t                                         *semaphore );

xos_result_t dmc2180_motor_abort_move( dhs_motor_abort_move_message_t	*message, 
													xos_semaphore_t						*semaphore );

xos_result_t dmc2180_start_operation( dhs_start_operation_t *message, xos_semaphore_t *semaphore );

xos_result_t dmc2180_motor_start_oscillation( dhs_motor_start_oscillation_message_t	*message,
															 xos_semaphore_t								*semaphore );

xos_result_t dmc2180_motor_abort_oscillation( dhs_motor_abort_oscillation_message_t	*message, 
															 xos_semaphore_t								*semaphore );

xos_result_t dmc2180_motor_configure( dhs_motor_configure_message_t	*message, 
												  xos_semaphore_t					*semaphore );

xos_result_t dmc2180_motor_register( dhs_motor_register_message_t	*message, 
												 xos_semaphore_t					*semaphore );

xos_result_t dmc2180_set_current_position( xos_index_t		deviceIndex,
														 dcs_scaled_t	scaledPosition );

xos_result_t dmc2180_set_speed_acceleration( xos_index_t		deviceIndex,
															dcs_unscaled_t	speed,
															dcs_unscaled_t	accelerationTime );

xos_result_t dmc2180_motor_poll(
	dhs_motor_register_message_t	*message,
	xos_semaphore_t					*semaphore
	);

void dmc2180_set_motor_direction(
	xos_index_t		deviceIndex,
	dcs_flag_t		reverseFlag
	);


xos_result_t dmc2180_motor_set(
	dhs_motor_set_message_t	*message,
	xos_semaphore_t			*semaphore
	);

xos_result_t dmc2180_local_motor_poll(
	xos_index_t deviceIndex
	);

void dmc2180_set_output_bit(
	xos_index_t		deviceIndex,
	int				newState
	);

xos_result_t dmc2180_shutter_messages(
	dhs_message_id_t	messageID,
	xos_semaphore_t	*semaphore,
	void					*message
	);


xos_result_t dmc2180_shutter_register(
	dhs_shutter_register_message_t	*message,
	xos_semaphore_t					*semaphore
	);


xos_result_t dmc2180_set_shutter_state( xos_index_t		deviceIndex,
													 shutter_state_t				newState );

xos_result_t dmc2180_shutter_set(
	dhs_motor_set_shutter_message_t	*message,
	xos_semaphore_t						*semaphore
	);


xos_result_t dmc2180_motor_start_vector_move(
	dhs_motor_start_vector_move_message_t	*message, 
	xos_semaphore_t								*semaphore 
	);

xos_result_t dmc2180_motor_stop_vector_move(
	dhs_motor_stop_vector_move_message_t	*message,
	xos_semaphore_t								*semaphore
	);

xos_result_t dmc2180_motor_change_vector_speed(
   dhs_motor_change_vector_speed_message_t		*message,
   xos_semaphore_t 										*semaphore
);

xos_result_t dmc2180_check_vector_complete( Dmc2180 & dmc2180);

xos_result_t dmc2180_card_messages( dhs_message_id_t	messageID,
												xos_semaphore_t	*semaphore,
												void					*message );

xos_result_t dmc2180_kick_watchdog( dhs_watchdog_kick_message_t *message,
												Dmc2180 & dmc2180,
												xos_semaphore_t *semaphore);

xos_result_t dmc2180_start_watchdog( Dmc2180 & dmc2180);

dcs_unscaled_t scaled2unscaledPosition(xos_index_t deviceIndex, dcs_scaled_t scaledPosition );

xos_result_t handle_vector_move_start_error( xos_index_t			deviceIndex_1,
															xos_index_t			deviceIndex_2,
															int					errorCode,
															Dmc2180_motor		*motor1,
															Dmc2180_motor		*motor2);

#endif
