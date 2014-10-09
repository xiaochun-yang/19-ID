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

/* image_channel.h */

#ifndef IMAGE_CHANNEL_H
#define IMAGE_CHANNEL_H

/* standard include files */
#include <tcl.h>
#include <tk.h>
#include "tcl_macros.h"

extern "C" {
#include <xos_socket.h>
#include <xos_hash.h>
}


/* typedefs */
typedef struct
	{
	Tcl_Interp * 			interp;
	char			 			channelName[200];
   xos_boolean_t        channelReady;
	char 						serverName[200];
	xos_socket_port_t		listeningPort;
	int                  authProtocol;
	unsigned char * 		imageBuffer;
	int 						imageBufferSize;
	int 						width;
	int 						height;	
	Tk_PhotoImageBlock 	photoImageBlock;
	xos_message_queue_t	requestQueue;
	xos_semaphore_t		loadSemaphore;
	xos_boolean_t			loadComplete;
	xos_boolean_t			errorHappened;
	xos_boolean_t			synchronous;
	char 						userName[200];
	char                 imageParameters[2000];
} image_channel_t;


/* function prototypes */
xos_result_t image_channel_create_table( int size );
XOS_THREAD_ROUTINE image_channel_thread_routine
	( 
	void *arg 
	);

void image_channel_post_semaphore
	(
	image_channel_t * channel
	);

DECLARE_TCL_COMMAND(image_channel_create);
DECLARE_TCL_COMMAND(image_channel_delete);
DECLARE_TCL_COMMAND(image_channel_update);
DECLARE_TCL_COMMAND(image_channel_blank);
DECLARE_TCL_COMMAND(image_channel_load);
DECLARE_TCL_COMMAND(image_channel_load_complete);
DECLARE_TCL_COMMAND(image_channel_resize);
DECLARE_TCL_COMMAND(image_channel_error_happened);
DECLARE_TCL_COMMAND( image_channel_allocate_channels );

#endif
