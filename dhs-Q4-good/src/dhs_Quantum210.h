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
// dhs_Quantum210.h
// *******************

#ifndef DHS_Q210_H
#define DHS_Q210_H

#include "xos_socket.h"
#include "libimage.h"
#include "dhs_detector.h"

typedef enum
	{
	SLOW					= 0,
	FAST					= 1,
	SLOW_BIN				= 2,
	FAST_BIN				= 3,
	SLOW_DEZING			= 4,
	FAST_DEZING 		= 5,
	SLOW_BIN_DEZING	= 6,
	FAST_BIN_DEZING	= 7,
	INVALID_MODE      = 8
	} detector_mode_t;

// public function declarations

XOS_THREAD_ROUTINE imageAssemblerRoutineQ210( void *arg );
XOS_THREAD_ROUTINE Quantum210ControlThread( void * arg );
XOS_THREAD_ROUTINE Quantum210Thread( void * parameter);
XOS_THREAD_ROUTINE chipReaderRoutineQ210( void *arg );

xos_result_t handleCollectImageCCD( dhs_collect_image_message_t	*message, 
												xos_semaphore_t						   *semaphore  );


typedef enum
	{
	ADSC_DK0,
	ADSC_DK1,
	ADSC_DKC,
	ADSC_IM0,
	ADSC_IM1,
	ADSC_IMX
	} adsc_image_type_t;

xos_result_t writeImageQ210(  img_handle 	 image, 
										const char 	 * directory, 
										const char 	 * filename,
										const char   * message, 
										char	*detector_header);
	
xos_result_t handle_adsc_image( char * filename,
										  const char * directory,
										  xos_index_t runIndex,
										  adsc_image_type_t imageType,
										  const char * xformMessage,
										  detector_mode_t detectorMode );
	


xos_result_t detector_reset_run( int run );



#endif
