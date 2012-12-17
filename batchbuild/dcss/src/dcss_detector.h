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

/* dcss_detector.h */

#ifndef DCSS_DETECTOR_H
#define DCSS_DETECTOR_H

#include "xos.h"
#include "xos_socket.h"
#include "libimage.h"

/* public function declarations */
xos_result_t initialize_detector( void );
XOS_THREAD_ROUTINE detector_thread_routine( void *arg );
XOS_THREAD_ROUTINE xform_thread_routine( void *arg );

xos_result_t detector_send_stop( const char * state );
xos_result_t detector_send_flush( void );

typedef enum {

	ADSC_DK0,
	ADSC_DK1,
	ADSC_DKC,
	ADSC_IM0,
	ADSC_IM1,
	ADSC_IMX

} adsc_image_type_t;

xos_result_t write_ccd_image( xos_boolean_t isDark,
										img_object 	* image, 
										const char 	* directory, 
										const char 	* filename,
										const char  * xformMessage );
	
xos_result_t handle_adsc_image( char * filename,
										  const char * fileroot,
										  const char * directory,
										  xos_index_t runIndex,
										  adsc_image_type_t imageType,
										  const char * xformMessage );
	
xos_result_t detector_send_start( int				rundIndex,
											 const char * 	filename,
											 const char *	fileroot,
											 const char *	directory,
											 xos_boolean_t 	fastreadout,
											 int 				binning,
											 double			time,
											 adsc_image_type_t imageType,
											 int				collectionAxis,
											 double			oscStart, 
											 double			oscRange, 
											 double			distance,
											 double			wavelength, 
											 double			detectorX, 
											 double			detectorY );

xos_result_t detector_reset_run( int run );

xos_result_t set_detector_chips( int numChips);

typedef enum
	{
	FIRST_DARK,
	SECOND_DARK,
	VALID
	} dark_step_t;


typedef struct
  	{
	time_t	creationTime;
	dark_step_t    status;
  	} dark_t;

#endif
