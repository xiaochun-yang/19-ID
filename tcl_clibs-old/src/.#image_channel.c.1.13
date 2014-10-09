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

/* image_channel.c */

#include <iostream>

extern "C" {
#include <xos_socket.h>
#include <xos_hash.h>
#include <jpegsoc.h>
#include "auth.h"
}


/* local include files */
#include "image_channel.h"
#include <tcl.h>
#include <tk.h>


/* module data */
static xos_hash_t		mImageChannelTable;

DECLARE_TCL_COMMAND( image_channel_allocate_channels )
	{
	int size;
	
	if ( argc != 2 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_allocate_channels numChannels\"",TCL_STATIC);
		return TCL_ERROR;
		}
	
	size = atoi( argv[1] );

	if ( size <= 0 )
		{
		Tcl_SetResult(interp,"numChannels <= 0",TCL_STATIC);
		return TCL_ERROR;
		}

	/* initialize the hash table */

	/*printf ("image_channel_allocate_channels: %d\n",size );*/
	
	if ( xos_hash_initialize( &mImageChannelTable, size, 
									  NULL ) == XOS_FAILURE )
		{
		xos_error("Error initializing image channel hash table.");
		return TCL_ERROR;
		}
	
	return TCL_OK;
	}


XOS_THREAD_ROUTINE image_channel_thread_routine
	( 
	void *arg 
	)
	
	{
	/* local variables */
	char 						messageBuffer[1000];
	xos_socket_t 			socket;
	dcs_message_t dcsMessage;
	image_channel_t *		channel;
	JINFO 					jinfo;
	xos_socket_address_t serverAddress;

	/* for authentication protocol 1.0 */
	char						challengeString[200];
	char						responseString[200];
	auth_key					key;

	/* access passed image channel structure */
	channel = (image_channel_t *) arg;

	//initialize the input buffers for the socket messages
	xos_initialize_dcs_message( &dcsMessage, 1000, 10 );

	/* loop forever */
	for(;;)
		{
   	channel->channelReady = 0;
      
		/* create the client socket */
		if ( xos_socket_create_client( & socket ) == XOS_FAILURE ) 
			{
			xos_error("Error creating image client socket.");
			goto disconnect;
			}	

		/* set address of image server using listening port */
		xos_socket_address_init( & serverAddress );
		xos_socket_address_set_ip_by_name( & serverAddress, channel->serverName );
		xos_socket_address_set_port( & serverAddress, channel->listeningPort );
				
		/* connect to listening port on image server */
		if ( xos_socket_make_connection( & socket, & serverAddress ) == XOS_FAILURE ) {
			xos_error("Error connecting to listening port on image server.");
			goto disconnect;
		}

		if ( channel->authProtocol == 1 )
			{
			/* write user name to server */
			/* strcpy( userName, getlogin() ); */
			if ( xos_socket_write( & socket, channel->userName, 200 ) != XOS_SUCCESS )
				{
				xos_error( "gui_client_thread -- error writing user name to server" );
				goto disconnect;
				}
			
			/* load security key for user */
			if ( auth_load_key( channel->userName, & key ) != XOS_SUCCESS )
				{
				xos_error( "Error loading security key for user %s", channel->userName );
				goto disconnect;
				}
			
			/* read challenge string from server */
			if ( xos_socket_read( & socket, challengeString, 200 ) != XOS_SUCCESS )
				{
				xos_error( "error reading challenge from server" );
				goto disconnect;
				}
			
			/* generate the response string */
			auth_get_response_string( responseString, challengeString, & key );
			
			/* write the response string to the server */
			if ( xos_socket_write( & socket, responseString, 200 ) != XOS_SUCCESS )
				{
				xos_error("error writing response to server");
				goto disconnect;
				}
			}

   	channel->channelReady = 1;

   /* read images until an error occurs */
		for(;;)
			{
			/* read next message from the queue */
			if ( xos_message_queue_read( &channel->requestQueue, messageBuffer ) == -1 )
			  	xos_error_exit("Error reading from image request message queue");	


			if ( strcmp( messageBuffer, "image_channel_delete" ) == 0 )
				{
				if ( xos_hash_delete_entry( &mImageChannelTable, channel->channelName ) != XOS_SUCCESS )
					{
					xos_error("could not remove image channel from has table");
					}
				free(channel->imageBuffer);
				
				if ( xos_semaphore_post( &channel->loadSemaphore ) != XOS_SUCCESS )
					{
					xos_error("Error posting load complete semaphore");
					}
					
				xos_send_dcs_text_message( &socket, "#done" );


				image_channel_post_semaphore( channel );
				free (channel);

				xos_socket_destroy( & socket );
				xos_destroy_dcs_message( &dcsMessage );
				xos_thread_exit();
				}
				
			/* send the request for the next image */
			if ( xos_send_dcs_text_message( &socket, messageBuffer ) != XOS_SUCCESS )
				{
				xos_error("image_channel_thread_routine: Error writing request to image server.");
				channel->errorHappened = TRUE;
				image_channel_post_semaphore( channel );
				goto disconnect;
				}
						
			/* read a message from the diffraction image server */
			if ( xos_receive_dcs_message( & socket, &dcsMessage ) != XOS_SUCCESS )
				{
				xos_error("image_channel_thread_routine: error reading status from image server.\n");
				channel->errorHappened = TRUE;
				image_channel_post_semaphore( channel );
				goto disconnect;	
				}
			
			
			/* make sure request could be satisfied */
			/* printf("%s\n",dcsMessage.textInBuffer); */
			if ( strncmp( dcsMessage.textInBuffer, "success",7 ) != 0 )
				{
				channel->errorHappened = TRUE;
				image_channel_post_semaphore( channel );
				continue;
				}
		
			strncpy( channel->imageParameters, dcsMessage.textInBuffer, 1999 );

			/* free image buffer if currently allocated */
			if ( channel->imageBuffer != NULL )
				{
				free(channel->imageBuffer);
				channel->imageBuffer = NULL;
				}
				

			/* read the image from the server */
			if ( receive_jpeg_buffer ( & socket, & channel->imageBuffer, 
				& jinfo ) != XOS_SUCCESS ) 
				{
				xos_error_sys("Error reading image from server.");
				channel->errorHappened = TRUE;	
				image_channel_post_semaphore( channel );
				goto disconnect;
				}
			

			/* post the semaphore */
			image_channel_post_semaphore( channel );
			}
			
		/* disconnect from image server */
		disconnect:
		xos_socket_destroy( & socket );

		/* wait a second before reconnecting */
		xos_thread_sleep( 1000 );
		}
	}


void image_channel_post_semaphore
	(
	image_channel_t * channel
	)
	
	{
	/* set the load complete flag */
	channel->loadComplete = TRUE;

	/* post the semaphore if request was synchronous */
	if ( channel->synchronous ) 
		{
		if ( xos_semaphore_post( & channel->loadSemaphore ) != XOS_SUCCESS )
			{
			xos_error_exit("Error posting load complete semaphore");
			}
		}
	}
	
	
DECLARE_TCL_COMMAND(image_channel_create)
	{
	/* local data */
	char * channelName;
	char * serverName;
	int listeningPort;
	int authProtocol;
	int width;
	int height;
	char * userName;
	xos_thread_t newThread;
	image_channel_t * newChannel;
		
	
	if ( argc != 8 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_create channelName serverName listeningPort authenticationProtocol width height userName\"",TCL_STATIC);
		
		puts("error in image_channel_create: wrong # args\n");
		return TCL_ERROR;
		}

	channelName = argv[1];
	serverName = argv[2];
	listeningPort = atoi( argv[3] );
   authProtocol = atoi( argv[4] );
	width = atoi( argv[5] );
	height = atoi( argv[6] );
	userName = argv[7];

	/* allocate a new image channel structure */
	if ( (newChannel = (image_channel_t *) malloc( sizeof( image_channel_t ))) == NULL )
		{
		Tcl_SetResult(interp,"Error allocating memory for new image channel.",TCL_STATIC);
		puts("error in image_channel_create: Error allocating memory for new image channel\n");
		return TCL_ERROR;
		}
	
	/* add image channel to hash table */
	if ( xos_hash_add_entry( &mImageChannelTable, channelName, 
			(xos_hash_data_t) newChannel ) != XOS_SUCCESS )
		{
		Tcl_SetResult(interp,"Error adding new image channel to hash table.",TCL_STATIC);
		puts("error in image_channel_create: Error adding new image channel to hash table\n");
		return TCL_ERROR;
		}

	/* fill in channel structure */
	newChannel->interp = interp;
	strcpy( newChannel->userName, userName );
	newChannel->channelReady = 0;
	strcpy( newChannel->channelName, channelName );
	strcpy( newChannel->serverName, serverName );
	newChannel->listeningPort = listeningPort;
	newChannel->width = width;
	newChannel->height = height;
	newChannel->imageBuffer = NULL;
   newChannel->authProtocol = authProtocol;
	
	/* set Tk photo parameters */
	newChannel->photoImageBlock.width 		= width;
	newChannel->photoImageBlock.height 		= height;
	newChannel->photoImageBlock.pitch 		= width * 3;
	newChannel->photoImageBlock.offset[0] 	= 0;
	newChannel->photoImageBlock.offset[1] 	= 1;
	newChannel->photoImageBlock.offset[2] 	= 2;
	newChannel->photoImageBlock.pixelSize 	= 3;


	/* create the request message queue */
	if ( xos_message_queue_create( & newChannel->requestQueue, 100, 200 ) != XOS_SUCCESS )
	  	xos_error_exit("Error creating request message queue");

	/* initialize the load semaphore */
	newChannel->loadComplete = TRUE;
	newChannel->errorHappened = FALSE;
	if ( xos_semaphore_create( & newChannel->loadSemaphore, 0 ) != XOS_SUCCESS )
		xos_error_exit("Error creating load semaphore");
	

	/* create a thread to handle image channel */
	if ( xos_thread_create( &newThread, image_channel_thread_routine, 
		(void *) newChannel ) != XOS_SUCCESS )
		{
		xos_error_exit("error creating image channel thread");
		}
		

	return TCL_OK;
	}


DECLARE_TCL_COMMAND(image_channel_update)
	{
	/* local variables */
	Tk_PhotoHandle handle;
	char * channelName = argv[1];
	image_channel_t * channel;
		
	if ( argc != 2 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_update channelName\"",TCL_STATIC);
		puts("error in image_channel_update: wrong # args\n");
		return TCL_ERROR;
		}

	/* lookup diffraction image */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName,
								 (xos_hash_data_t *) & channel ) != XOS_SUCCESS)
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("error in image_channel_update: Image channel not found\n");
		return TCL_ERROR;
		}


	//reject the request to display the image if the image isn't finished loading
	if ( channel->loadComplete == FALSE )
		{
		Tcl_SetResult(interp,"Diffraction image not ready for display.",TCL_STATIC);
		puts("error in image_channel_update: Diffraction image not ready for display\n");
		return TCL_ERROR;
		}


	/* get handle to the photo object */
	handle = Tk_FindPhoto( interp, channelName );

	/* point photo image block to prepared buffer */
	channel->photoImageBlock.pixelPtr = channel->imageBuffer;
	

	/* write out the photo object */
	Tk_PhotoPutBlock( handle, &(channel->photoImageBlock), 0, 0, 
		channel->width, channel->height );

	//interp->result = channel->imageParameters;

	Tcl_SetResult(interp,channel->imageParameters,TCL_VOLATILE);
		

	return TCL_OK;
	}


DECLARE_TCL_COMMAND(image_channel_blank)
	{
	/* local variables */
	Tk_PhotoHandle handle;
	char * channelName = argv[1];
	image_channel_t * channel;
		
	if ( argc != 2 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_blank channelName\"",TCL_STATIC);
		puts("error in image_channel_blank: wrong # args\n");
		return TCL_ERROR;
		}

	/* lookup diffraction image */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName,
								 (xos_hash_data_t *) & channel ) != XOS_SUCCESS)
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("error in image_channel_blank: Image channel not found\n");
		return TCL_ERROR;
		}


	//reject the request to display the image if the image isn't finished loading
	if ( channel->loadComplete == FALSE )
		{
		Tcl_SetResult(interp,"Diffraction image not ready for blank display",TCL_STATIC);
		puts("error in image_channel_blank: Diffraction image not ready for blank display\n");
		return TCL_ERROR;
		}


	/* get handle to the photo object */
	handle = Tk_FindPhoto( interp, channelName );

	/* point photo image block to prepared buffer */
	channel->photoImageBlock.pixelPtr = channel->imageBuffer;
	

	/* write out blank photo */
	Tk_PhotoSetSize(handle, channel->width, channel->height);
	Tk_PhotoBlank(handle);
			

	return TCL_OK;
	}



DECLARE_TCL_COMMAND(image_channel_load)
	{
	/* local variables */
	const char * channelName = argv[1];
	const char * mode = argv[2];
	const char * request = argv[3];
	image_channel_t * channel;	
	

	if ( argc != 4 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_load channelName mode request\"",TCL_STATIC);
		puts("error in image_channel_load: wrong # args\n");
		return TCL_ERROR;
		}

	/* lookup image channel */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName, 
								 (xos_hash_data_t *) & channel ) != XOS_SUCCESS )
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("error in image_channel_load: Image channel not found\n");
		return TCL_ERROR;
		}
	
	//reject this request if the connection is bad
	if ( channel->channelReady == 0 )
		{
		Tcl_SetResult(interp,"Image server offline.",TCL_STATIC);
		puts("Image server offline.");
		return TCL_ERROR;
      }
   
	//reject this request if there is an asynchronous request outstanding
	if ( channel->loadComplete == FALSE && channel->synchronous == FALSE )
		{
		//puts("async load not complete");
		Tcl_SetResult(interp,"Asynchronous load of diffraction image not complete.",TCL_STATIC);
		puts("error in image_channel_load: Asynchronous load of diffraction image not complete\n");
		return TCL_ERROR;
		}

	/* store load mode */
	if ( strcmp( mode, "sync" ) == 0 ) 
		{
		channel->synchronous = TRUE;
		}
	else
		{
		channel->synchronous = FALSE;
		}
	
	/* set the load complete flag */
	channel->loadComplete = FALSE;
	channel->errorHappened = FALSE;

	/* write the message to the queue */
	xos_message_queue_write( & channel->requestQueue, request );
	
	/* wait for load to complete if synchronous */
	if ( channel->synchronous ) 
		{
		if ( xos_semaphore_wait( & channel->loadSemaphore, 0 ) != XOS_SUCCESS )
			{
			xos_error_exit("Error waiting for load complete semaphore");
			}
		}
	
	return TCL_OK;
	}


DECLARE_TCL_COMMAND(image_channel_delete)
	{
	/* local variables */
	const char * channelName = argv[1];
	image_channel_t * channel;	

	if ( argc != 2 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_delete channelName\"",TCL_STATIC);
		puts("error in image_channel_delete: wrong # args\n");
		return TCL_ERROR;
		}
   
	/* lookup image channel */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName, 
								 (xos_hash_data_t *) & channel ) != XOS_SUCCESS )
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("error in image_channel_delete: Image channel not found\n");
		return TCL_ERROR;
		}
	
	//reject this request if the connection is bad
	if ( channel->channelReady == 0 )
		{
		Tcl_SetResult(interp,"Image server offline.",TCL_STATIC);
		puts("Image server offline.");
		return TCL_ERROR;
      }
   
	/* set the load complete flag */
	channel->loadComplete = FALSE;
	channel->errorHappened = FALSE;

	/* write the message to the queue */
	xos_message_queue_write( & channel->requestQueue, "image_channel_delete" );
	
	/* wait for delete to complete*/
	if ( xos_semaphore_wait( & channel->loadSemaphore, 0 ) != XOS_SUCCESS )
		{
		xos_error_exit("Error waiting for load complete semaphore");
		}
	
	return TCL_OK;
	}



DECLARE_TCL_COMMAND(image_channel_load_complete)
	{
 	/* local variables */
	const char * channelName = argv[1];
	char tmpResult[20];
	image_channel_t * channel;	
		
	if ( argc != 2 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_load_complete channelName\"",TCL_STATIC);
		puts("error in image_channel_load_complete: wrong # args\n");
		return TCL_ERROR;
		}

	/* lookup image channel */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName, 
								 (xos_hash_data_t *) & channel ) != XOS_SUCCESS )
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("Failed in image_channel_load_complete: Image channel not found\n");
		return TCL_ERROR;
		}       
	
	/* return the value of the load-complete flag */
	sprintf( tmpResult, "%d", channel->loadComplete );
	Tcl_SetResult(interp, tmpResult, TCL_VOLATILE);
	
	         
	return TCL_OK;
	}


DECLARE_TCL_COMMAND(image_channel_error_happened)
	{
 	/* local variables */
	const char * channelName = argv[1];
	image_channel_t * channel;	
	char tmpResult[20];

	if ( argc != 2 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_error_happened channelName\"",TCL_STATIC);
		puts("Failed in image_channel_error_happened: wrong # args\n");
		return TCL_ERROR;
		}
	
	/* lookup image channel */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName, 
								 (xos_hash_data_t *) & channel ) != XOS_SUCCESS )
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("Failed in image_channel_error_happened: Image channel not found\n");
		return TCL_ERROR;
		}       
	
	/* return the value of the error flag */
	sprintf( tmpResult, "%d", channel->errorHappened );
	Tcl_SetResult(interp, tmpResult, TCL_VOLATILE);

	return TCL_OK;
	}


DECLARE_TCL_COMMAND(image_channel_resize)
	{
	/* local data */

	char * channelName;
	int width;
	int height;
	image_channel_t * channel;
	

	if ( argc !=4 ) 
		{
		Tcl_SetResult(interp,"wrong # args: should be \"image_channel_resize channelName width height\"",TCL_STATIC);
		puts("error in image_channel_resize: wrong # args\n");
		return TCL_ERROR;
		}

	channelName = argv[1];
	width = atoi( argv[2] );
	height = atoi( argv[3] );
	
	/* lookup diffraction image */
	if ( xos_hash_lookup( &mImageChannelTable,
								 channelName,
								 (xos_hash_data_t *) & channel )  != XOS_SUCCESS )
		{
		Tcl_SetResult(interp,"Image channel not found.",TCL_STATIC);
		puts("error in image_channel_resize: Image channel not found\n");
		return TCL_ERROR;
		}       

	/* set the channel parameters */
	channel->width = width;
	channel->height = height;
	
	/* set Tk photo parameters */
	channel->photoImageBlock.width 	= width;
	channel->photoImageBlock.height 	= height;
	channel->photoImageBlock.pitch 	= width * 3;
		

	return TCL_OK;
	}

