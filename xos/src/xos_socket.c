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
								xos_socket.c
								
	This is the source code file associated with xos_socket.h.
	Together, these two files define an abstract data type,
	xos_socket, which is used to encapsulate the data and
	functions required for TCP sockets under UNIX and
	VMS/Multinet.
	
	
	Author:				Timothy M. McPhillips, SSRL.
	Last Revision:		March 4, 1998, by TMM.
	
****************************************************************/


/* xos_socket_t include file */
#include "xos_socket.h"

/* an indicator whether startup already called */
static int startupCalled = 0;
static xos_result_t previousStartupResult;
static int print_error_flag = 1;

void xos_socket_set_print_error_flag(int print_or_not)
{
	print_error_flag = print_or_not;
}

/**
 * Bad idea to print out error messages to stderr
 * especially for the impersonation server
 * where stderr and stdout are redirected to socket
 * stream sent to client. For example,
 * the error might be printed out before
 * HTTP response line or header has been streamed out.
 */
static void xos_socket_print_error(const char* str)
{
	if (print_error_flag != 0)
		SOCKET_PERROR(str);
}

xos_result_t socket_read_no_mutex( xos_socket_t*	socket,
											  char* 			buffer,
											  int 				numBytes );

xos_result_t socket_send_no_mutex( xos_socket_t * socket,
											  const char * buffer,
											  int numBytes );

xos_socket_port_t xos_socket_get_local_port
	(
	xos_socket_t* socket
	)
	
	{

	/* local variables */
	xos_socket_port_t localPort;
		
	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );

	/* get the port of appropriate (local) address */
	if ( socket->process == SP_SERVER )
		localPort = xos_socket_address_get_port( &socket->serverAddress );
	else
		localPort = xos_socket_address_get_port( &socket->clientAddress );
		
	/* return the result */
	return localPort;
	}


/****************************************************************
 	xos_socket_create_server:  Initializes a xos_socket_t 
 	structure for using a socket in a server process, creates the
	actual socket, and binds the socket to the specified port.
	Returns -1 if a socket system call fails.  If successful,
	returns 0.
****************************************************************/ 

xos_result_t xos_socket_create_server
	( 
	xos_socket_t*		newSocket,
	xos_socket_port_t	socketPort
	)
	
	{
	/* local variables */
	xos_socket_address_t			localAddress;
	xos_socket_address_size_t	addressSize = sizeof(localAddress);
	int reuseAddress = 1;
	
	/* make sure passed xos_socket pointer is valid */
	assert( newSocket != NULL );
	
	/* declare socket structure and both addresses invalid */
	newSocket->socketStructValid	= FALSE;
	newSocket->serverAddressValid	= FALSE;
	newSocket->clientAddressValid	= FALSE;
	newSocket->serverListening		= FALSE;
	newSocket->connectionActive	= FALSE;
	newSocket->connectionGood	 	= FALSE;
		
	/* initialize read mutex */
	if ( xos_mutex_create( &newSocket->readMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_create_server--create read mutex failed" );
  		return XOS_FAILURE;
  		} 		

	/* initialize write mutex */
	if ( xos_mutex_create( &newSocket->writeMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_create_server--create write mutex failed" );
  		return XOS_FAILURE;
  		} 		

	/* initialize members of xos_socket_t structure */
	newSocket->process 		= SP_SERVER;
	newSocket->queueLength 	= SOCKET_DEFAULT_QUEUE_LENGTH;
	
	/* create the socket */
	if ( ( newSocket->serverDescriptor = 
		SOCKET_CREATE( AF_INET, SOCK_STREAM, 0 ) ) == SOCKET_CREATE_ERROR ) 
  		{
  		xos_socket_print_error( "xos_socket_create_server--socket" );
  		return XOS_FAILURE;
  		}

	/* initialize the address structure */
	xos_socket_address_init( &newSocket->serverAddress );
  	xos_socket_address_set_port( &newSocket->serverAddress, socketPort );
  
#ifndef WIN32
	/* set REUSEADDR socket option */
	setsockopt( newSocket->serverDescriptor, SOL_SOCKET, SO_REUSEADDR,
		(char *) &reuseAddress, sizeof( reuseAddress ) );
#endif

  	/* bind address to socket */
  	if ( SOCKET_BIND( newSocket->serverDescriptor, 
  		(struct sockaddr*) &(newSocket->serverAddress), 
  		sizeof( newSocket->serverAddress ) ) == SOCKET_BIND_ERROR ) 
  		{
  		xos_socket_print_error( "xos_socket_create_server--bind" );
  		return XOS_FAILURE;
  		}
 
 	/* retrieve actual port number used if 0 was passed */
 	if ( socketPort == 0 ) 
 		{
 		/* get socket address of server */
 		if ( SOCKET_GETSOCKNAME( newSocket->serverDescriptor,
 			(struct sockaddr*) &localAddress, &addressSize ) == -1 ) 
  			{
  			xos_socket_print_error( "xos_socket_create_server--getsockname" );
  			return XOS_FAILURE;
  			}
  		
  		/* copy socket port value to socket structure */
  		xos_socket_address_set_port( &newSocket->serverAddress,
  		xos_socket_address_get_port( &localAddress ) );
  		}
 
 	/* declare socket structure and local address valid */
  	newSocket->socketStructValid  = TRUE;
  	newSocket->serverAddressValid = TRUE;
  
	/* report success */
  	return XOS_SUCCESS;
  	}
  
 
/****************************************************************
 	xos_socket_create_client:  Initializes a xos_socket_t 
 	structure for using a socket in a client process and creates
 	the actual socket.  Returns -1 if a socket system call fails.  
 	If successful, returns 0.
****************************************************************/ 
 	
xos_result_t xos_socket_create_client
	( 
	xos_socket_t*	newSocket
	)
	
	{
	/* make sure passed xos_socket pointer is valid */
	assert( newSocket != NULL );
	
	/* declare socket structure and both addresses invalid */			
	newSocket->socketStructValid	= FALSE;
	newSocket->serverAddressValid	= FALSE;
	newSocket->clientAddressValid	= FALSE;
	newSocket->serverListening		= FALSE;
	newSocket->connectionActive	= FALSE;
	newSocket->connectionGood	 	= FALSE;
	newSocket->blockOnRead        = TRUE;

	/* initialize read mutex */
	if ( xos_mutex_create( &newSocket->readMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_create_server--create read mutex failed" );
  		return XOS_FAILURE;
  		} 		

	/* initialize write mutex */
	if ( xos_mutex_create( &newSocket->writeMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_create_server--create write mutex failed" );
  		return XOS_FAILURE;
  		} 		
			
	/* initialize members of xos_socket_t structure */
	newSocket->process = SP_CLIENT;
	
 	/* create the socket */
	if ( ( newSocket->clientDescriptor = 
		SOCKET_CREATE( AF_INET, SOCK_STREAM, 0 ) ) == SOCKET_CREATE_ERROR )
  		{
  		xos_socket_print_error( "xos_socket_create_client--socket" );
  		return XOS_FAILURE;
  		}
	
   /* declare socket structure valid */
  	newSocket->socketStructValid = TRUE;
	
	/* report success */
	return XOS_SUCCESS;
	}


/****************************************************************
 	xos_socket_start_listening:  Informs kernel to listen for 
 	incoming connections from client sockets.  Does not block.
 	Returns -1 if a socket system call fails.  If successful,
	returns 0.
****************************************************************/ 

xos_result_t xos_socket_start_listening
	( 
	xos_socket_t* socket 
	)
	
	{
	/* local variables */
	int syscallResult;
	
	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* check that passed socket is really a server */
	assert( socket->process == SP_SERVER );

	/* check validity of queue length */
	assert( socket->queueLength > 0 );
	
	/* make sure socket is valid */
	assert( socket->socketStructValid == TRUE );

	/* make sure server socket address is valid */
	assert( socket->serverAddressValid == TRUE );
	
	/* start listening for incoming connections */
  	syscallResult = 
  		SOCKET_LISTEN( socket->serverDescriptor, socket->queueLength );

	/* check for error in listen call */
  	if ( syscallResult == SOCKET_LISTEN_ERROR ) 
  		{
  		xos_socket_print_error( "xos_socket_start_listening--listen" );
		socket->connectionGood = FALSE;
  		return XOS_FAILURE;
  		}
  		
  	/* update server state */
 	socket->serverListening = TRUE;
 	
 	/* report success */
 	return XOS_SUCCESS;
 	}
 

/****************************************************************
 	xos_socket_accept_connection:  Waits for a connection from a 
 	client.  When a connection is established, stores remote address 
 	information for later use.  Returns 0 on success, -1 on failure.
****************************************************************/ 

xos_result_t xos_socket_accept_connection( xos_socket_t* serverSocket,
														 xos_socket_t* newClientSocket )
	{
	/* local variables */
	int syscallResult;
	
	/* make sure passed xos_socket pointer is valid */
	assert( serverSocket != NULL );
	
	/* check that passed socket is really a server */
	assert( serverSocket->process == SP_SERVER );
	
	/* make sure socket is valid */
	assert( serverSocket->socketStructValid == TRUE );
	
	/* make sure server address is valid */
	assert( serverSocket->serverAddressValid == TRUE );
	
	/* make sure server is listening */
	assert( serverSocket->serverListening == TRUE );
		  
  	/* set the remote address size */
  	newClientSocket->clientAddressSize = sizeof( serverSocket->clientAddress );
  
 	/* wait for connection */
 	syscallResult = newClientSocket->clientDescriptor = 
		 SOCKET_ACCEPT( serverSocket->serverDescriptor, 
							 (struct sockaddr*) &(newClientSocket->clientAddress), 
							 &(newClientSocket->clientAddressSize) );
 	
 	/* check for error in accept call */	 
	if ( syscallResult == SOCKET_ACCEPT_ERROR ) 
  		{
  		xos_socket_print_error ("xos_socket_accept_connection--accept" );
		newClientSocket->connectionGood = FALSE;
  		return XOS_FAILURE;
  		}
 
	/* initialize read mutex */
	if ( xos_mutex_create( &newClientSocket->readMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_create_server--create read mutex failed" );
  		return XOS_FAILURE;
  		} 		

	/* initialize write mutex */
	if ( xos_mutex_create( &newClientSocket->writeMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_create_server--create write mutex failed" );
  		return XOS_FAILURE;
  		} 		

 	/* declare client address valid and connection active */
 	newClientSocket->process = SP_CLIENT;
 	newClientSocket->clientAddressValid = TRUE;
 	newClientSocket->connectionActive 	= TRUE;
	newClientSocket->connectionGood		= TRUE;
	newClientSocket->socketStructValid  = TRUE;
	newClientSocket->blockOnRead        = TRUE;

  	/* report success */
  	return XOS_SUCCESS;
  	}

xos_result_t xos_socket_get_peer_name( xos_socket_t * socket,
													xos_socket_address_t *peerAddress )
	{
	int len;
	struct hostent *host;

	len = sizeof( *peerAddress);
	if (getpeername( socket->clientDescriptor,
						  (struct sockaddr *) peerAddress,
						  &len) < 0)
		{
		perror("xos_socket_get_peer_name: getpeername");
		return XOS_FAILURE;
		}

	xos_socket_address_print( peerAddress );
	
	
	if ((host = gethostbyaddr((char *) &peerAddress->sin_addr,
									  sizeof peerAddress->sin_addr,
									  AF_INET)) == NULL)
		perror("gethostbyaddr");
	else
		printf("remote host is '%s'\n", host->h_name);
 
	return XOS_SUCCESS;
	}

										  

xos_result_t xos_socket_set_send_buffer_size (xos_socket_t *socket,
															 int * bufferSize)
	{
	
	int currentBufferSize;

	int size;

	size = sizeof(int);

	if ( getsockopt( socket->clientDescriptor,
						  SOL_SOCKET,
						  SO_SNDBUF,
						  &currentBufferSize,
						  &size ) == -1)
		{
		xos_socket_print_error( "xos_socket_set_send_buffer_size:");
		xos_error_exit("");
		}
		
//		printf("current buffer size %d\n", currentBufferSize );
	  


	if ( setsockopt( socket->clientDescriptor,
						  SOL_SOCKET,
						  SO_SNDBUF,
						  bufferSize,
						  sizeof(int) ) == -1)
		{
		xos_socket_print_error( "xos_socket_set_send_buffer_size:");
		xos_error_exit("");
		}


	if ( getsockopt( socket->clientDescriptor,
						  SOL_SOCKET,
						  SO_SNDBUF,
						  &currentBufferSize,
						  &size ) == -1)
		{
		xos_socket_print_error( "xos_socket_set_send_buffer_size:");
		xos_error_exit("");
		}
	else
		{
//		printf("Buffer size is now %d\n", currentBufferSize );
		return XOS_SUCCESS;
		}

	return XOS_SUCCESS;
	}


/****************************************************************
 	xos_socket_make_connection:  Makes connection with a server
 	specified by the passed socket address structure. Returns 0 on 
 	success, -1 on failure.
****************************************************************/ 

xos_result_t xos_socket_make_connection
	(
	xos_socket_t*						socket,
	const xos_socket_address_t*	address
	)
	
	{
	/* local variables */
	int syscallResult;
	
	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* make sure passed socket_addres pointer is valid */
	assert( address != NULL );	
		
	/* check that passed socket is really a client */
	assert( socket->process == SP_CLIENT );
	
	/* make sure socket is valid */
	assert( socket->socketStructValid == TRUE);
	
	/* save the passed address in the server address structure */
  	socket->serverAddress = *address;

	/* connect to server */
  	syscallResult = SOCKET_CONNECT( socket->clientDescriptor, 
  		(struct sockaddr*) &(socket->serverAddress), 
  		sizeof( socket->serverAddress ) );
  	
	/* check for error in connect */
  	if ( syscallResult == SOCKET_CONNECT_ERROR ) 
  		{
  		xos_socket_print_error( "xos_socket_make_connection--connect" );
		socket->connectionGood = FALSE;
		//some platforms have a file handle open at this point
		syscallResult = SOCKET_CLOSE( socket->clientDescriptor );
  		return XOS_FAILURE;
  		}

 	/* declare server address valid and connection active */
 	socket->serverAddressValid = TRUE;
	socket->clientAddressValid = TRUE;
 	socket->connectionActive 	= TRUE;
	socket->connectionGood		= TRUE;
 
  	/* report success */
  	return XOS_SUCCESS;
	}

// When a socket's output buffer is full, a write to the socket
// can either block indefinetly or error.  This function will set the 
// desired behaviour on the socket.
xos_result_t xos_socket_set_block_on_write( xos_socket_t * socket ,
														  xos_boolean_t blockOnWrite )
	{
#if defined WIN32
	//This function not implemented for Windows yet
#else
	int flags;

	if ( blockOnWrite )
		{
		//set the socket to blocking
		if ( (flags = fcntl( socket->clientDescriptor, F_GETFL, 0)) < 0)
			{
			xos_error("xos_socket_set_block_on_write: Could not set the socket to blocking.");
			return XOS_FAILURE;
			}
		
		flags &= ~O_NONBLOCK;
		
		if ( fcntl( socket->clientDescriptor, F_SETFL, flags ) < 0)
			{
			xos_error("xos_socket_set_block_on_write: Could not set the socket to blocking.");
			return XOS_FAILURE;
			}
		}
	else
		{
		//set the socket to non-blocking
		if ( (flags = fcntl( socket->clientDescriptor, F_GETFL, 0)) < 0)
			{
			xos_error("xos_socket_set_block_on_write: Could not set the socket to non_blocking.");
			return XOS_FAILURE;
			}
		
		flags |= O_NONBLOCK;
		
		if ( fcntl( socket->clientDescriptor, F_SETFL, flags ) < 0)
			{
			xos_error("xos_socket_set_block_on_write: Could not set the socket to non_blocking.");
			return XOS_FAILURE;
			}
		}	
#endif
	return XOS_SUCCESS;
	}

xos_result_t xos_socket_set_read_timeout	( xos_socket_t*	socket,
														  xos_time_t		timeoutMilliseconds )
	{
	// set timeout if timeout parameter is non-zero set
	if ( timeoutMilliseconds != 0 )
		{
		socket->blockOnRead = FALSE;
		socket->readTimeout.tv_sec		= timeoutMilliseconds / 1000;
		socket->readTimeout.tv_usec	= (timeoutMilliseconds % 1000) * 1000;
		}
	else
		{
		socket->blockOnRead = TRUE;
		}
	return XOS_SUCCESS;
	}

xos_wait_result_t xos_socket_wait_until_readable
	(
	xos_socket_t*	socket,
	xos_time_t		timeoutMilliseconds
	)
	
	{
	/* local variables */
	struct timeval		timeout;
	struct timeval		*timeoutPtr;
	fd_set				readMask;
	int					descriptorTableSize;
	int					selectResult;
	
	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		xos_error("xos_socket_wait_until_readable: connection not good");
		socket->connectionGood = FALSE;
		return XOS_WAIT_FAILURE;
		}
		
	/* set timeout if timeout parameter is non-zero set */
	if ( timeoutMilliseconds != 0 )
		{
		timeout.tv_sec		= timeoutMilliseconds / 1000;
		timeout.tv_usec	= (timeoutMilliseconds % 1000) * 1000;
		timeoutPtr = & timeout;
		}
	/* otherwise set timeout to indicate indefinite wait */
	else
		{
		timeoutPtr = NULL;
		}

	/* get total number of file descriptors to check */
	descriptorTableSize = SOCKET_GETDTABLESIZE();
 
	/* initialize descriptor mask for select */
	FD_ZERO( &readMask );
	FD_SET( socket->clientDescriptor, &readMask );

	/* wait indefinitely until socket becomes readable */
	selectResult = select ( descriptorTableSize, &readMask,
		NULL, NULL, timeoutPtr );

	/* report result */
	switch ( selectResult )
		{
		case SOCKET_SELECT_TIMEOUT:
			return XOS_WAIT_TIMEOUT;

		case SOCKET_SELECT_ERROR:		
		  	xos_socket_print_error( "xos_socket_wait_until_readable--select");
			socket->connectionGood = FALSE;
			return XOS_WAIT_FAILURE;

		default:
			return XOS_WAIT_SUCCESS;
		}
	}


xos_result_t xos_socket_readable
	(
	xos_socket_t	*socket,
	xos_boolean_t	*readable
	)
	
	{
	fd_set			readMask;
	struct timeval	timeout;
	int				descriptorTableSize;
	int				selectResult;
	
	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_socket_readable: connection not good");
		return XOS_FAILURE;
		}

	/* set socket timeout value to zero */
	timeout.tv_sec = 0;
	timeout.tv_usec = 0; 
		
	/* get total number of file descriptors to check */
	descriptorTableSize = SOCKET_GETDTABLESIZE();
	
	/* initialize descriptor mask for select */
	FD_ZERO( &readMask );
	FD_SET( socket->clientDescriptor, &readMask );
	
	selectResult = select( descriptorTableSize, &readMask, 
		(fd_set*) NULL, (fd_set*) NULL, &timeout );

	/* return error if error returned from select */
	if ( selectResult == SOCKET_SELECT_ERROR )
		{
  		xos_socket_print_error( "xos_socket_readable--select" );
		socket->connectionGood = FALSE;
		*readable = FALSE;
		return XOS_FAILURE;
		}
	/* otherwise report success */
	else
		{
		*readable = selectResult;
		return XOS_SUCCESS;
		}
	}


/****************************************************************
 	xos_socket_read:  Reads 'numBytes' bytes from 'socket' 
 	into 'buffer'.  Returns number of bytes actually read, or -1 
 	on error in read system call or with timeout. 
	NOTE: The timeout value is not the total time to read the numBytes.
         TimeoutMilliseconds is the time between socket readable events.
****************************************************************/ 

xos_result_t xos_socket_read ( xos_socket_t*	socket, 
										 char* 			buffer, 
										 int 			numBytes )
	{
	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* make sure passed byte pointer is valid */
	assert( buffer != NULL );
		
	/* make sure socket is valid */
	assert( socket->socketStructValid == TRUE );

	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_socket_read: connection not good");
		return XOS_FAILURE;
		}

	/* lock the socket read mutex */
	if ( xos_mutex_lock( &socket->readMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_socket_read: wait for mutex failed" );
		return XOS_FAILURE;
		}

	// call appropriate read function based on blocking mode.
	if ( socket_read_no_mutex( socket, buffer, numBytes ) != XOS_SUCCESS)
		{
		socket->connectionGood = FALSE;
		xos_error("xos_socket_read: connection not good");
        xos_mutex_unlock( & socket->readMutex );
		return XOS_FAILURE;
		}
	
	/* unlock the socket read mutex */
	if ( xos_mutex_unlock( & socket->readMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_socket_read: unlock mutex failed" );
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
	}



// ****************************************************************************
// xos_initialize_dcs_message:
//          Initializes the dcs_message_t type by allocating text and binary
//          input buffers. The size of the input buffers are passed to this
//          function.  The function returns an XOS_FAILURE if it could not
//          allocate the memory.
// ****************************************************************************
xos_result_t xos_initialize_dcs_message ( dcs_message_t *dcsMessage,
														xos_size_t initialTextSize,
														xos_size_t initialBinarySize )
	{
	if ( ( dcsMessage->textInBuffer = (char *)(malloc(initialTextSize + 1))) ==NULL ) 
		{
		xos_error("initializeDcsMessage: could not allocate memory for textMessage");
		return XOS_FAILURE;
		} 
	//terminate the input buffer with a null to be safe.
	dcsMessage->textInBuffer[initialTextSize] = 0x00;
	dcsMessage->textBufferSize = initialTextSize;
	dcsMessage->textInSize = 0;
	dcsMessage->binaryInSize = 0;

	
	if ( ( dcsMessage->binaryInBuffer = (char *)(malloc(initialBinarySize))) ==NULL ) 
		{
		xos_error("initializeDcsMessage: could not allocate memory for textMessage");
		return XOS_FAILURE;
		}
	dcsMessage->binaryBufferSize = initialBinarySize;


	return XOS_SUCCESS;
	}


xos_result_t xos_destroy_dcs_message( dcs_message_t * dcsMessage )
	{
	free(dcsMessage->textInBuffer);
	free(dcsMessage->binaryInBuffer);
	return XOS_SUCCESS;
	}

xos_result_t xos_adjust_dcs_message( dcs_message_t * dcsMessage,
int textSize, int binarySize ) {
    if (textSize > dcsMessage->textBufferSize) {
        if (dcsMessage->textBufferSize > 0) {
	        free(dcsMessage->textInBuffer);
            dcsMessage->textBufferSize = 0;
        }
        dcsMessage->textInBuffer = calloc( textSize, 1 );
        if (dcsMessage->textInBuffer == NULL) {
		    xos_error( "xos_adjust_dcs_message: text buffer calloc failed" );
            return XOS_FAILURE;
        }
        dcsMessage->textBufferSize = textSize;
    }
    if (binarySize > dcsMessage->binaryBufferSize) {
        if (dcsMessage->binaryBufferSize > 0) {
	        free(dcsMessage->binaryInBuffer);
            dcsMessage->binaryBufferSize = 0;
        }
        dcsMessage->binaryInBuffer = calloc( binarySize, 1 );
        if (dcsMessage->binaryInBuffer == NULL) {
		    xos_error( "xos_adjust_dcs_message: binary buffer calloc failed" );
            return XOS_FAILURE;
        }
        dcsMessage->binaryBufferSize = binarySize;
    }
    return XOS_SUCCESS;
}
// ****************************************************************************
// xos_receive_dcs_message:
//          .This function handles the receiving end of the dcs message protocol
//          for a valid xos_socket_t.  It will dynamically size the dcs_message_t
//          object's input buffers to accomodate the size of the message.
// 
//          The steps involved in reading the dcs message protocol are:
//             1)read the header and parse the header for the text and binary size
//             2)reallocate the text input buffer if it is insufficient to hold the
//               text message that is expected.
//             3)reallocate the binary input buffer if it is insufficient to hold
//               the binary portion of the message that is expected over the socket.
//             4)Read the text message and put it into the text input buffer.
//             5)Read the binary message and put it into the binary input buffer.
//
//           Note: The socket is mutexed during the whole receive process.
// ****************************************************************************
xos_result_t xos_receive_dcs_message( xos_socket_t * socket,
												  dcs_message_t *dcsMessage )
	{
	char header[30];
	header[26]=0;

	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* make sure socket is valid */
	assert( socket->socketStructValid == TRUE );

	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_receive_dcs_message: connection not good");
		return XOS_FAILURE;
		}

	/* lock the socket read mutex */
	if ( xos_mutex_lock( &socket->readMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_receive_dcs_message: wait for mutex failed" );
		return XOS_FAILURE;
		}	
	
	if  ( socket_read_no_mutex( socket, header, 26 ) != XOS_SUCCESS)
		{
		socket->connectionGood = FALSE;
		xos_error("xos_receive_dcs_message: error reading dcs message header");
		xos_mutex_unlock( & socket->readMutex );
		return XOS_FAILURE;
		}
	
	sscanf(header,"%d %d", &(dcsMessage->textInSize), &(dcsMessage->binaryInSize));
	
	//printf("textInSize: %d %d\n", dcsMessage->textInSize, dcsMessage->binaryInSize );

	if ( (dcsMessage->textInSize > 0 ) &&
		  (dcsMessage->textInSize > dcsMessage->textBufferSize) ) 
		{
		//reallocate text message pointer if the coming message is too big.
		free(dcsMessage->textInBuffer);
			
		if ( (dcsMessage->textInBuffer = (char *)(malloc( (dcsMessage->textInSize)+1) )) == NULL )
			{
			socket->connectionGood = FALSE;
			xos_mutex_unlock( & socket->readMutex );
			xos_error("xos_receive_dcs_message: could not allocate memory for text input buffer");
			return XOS_FAILURE;
			};
		
		dcsMessage->textBufferSize = dcsMessage->textInSize;
		}
	
	//terminate the string before it comes in.
	dcsMessage->textInBuffer[dcsMessage->textInSize] = 0x00;
	
	//read the text message
	if ( socket_read_no_mutex( socket,
										dcsMessage->textInBuffer,
										dcsMessage->textInSize ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_receive_dcs_message: socket error reading text message");
		xos_mutex_unlock( & socket->readMutex );
		return XOS_FAILURE;
		}

	if ( dcsMessage->binaryInSize > 0) 
		{
		//reallocate binary message pointer if the coming message is too big.
		if ( dcsMessage->binaryInSize > dcsMessage->binaryBufferSize ) 
			{
			free( dcsMessage->binaryInBuffer );
			if ( (dcsMessage->binaryInBuffer = malloc( sizeof(char) * dcsMessage->binaryInSize)) == NULL )
				{
				socket->connectionGood = FALSE;
				xos_error("xos_receive_dcs_message: could not allocate memory for binary input buffer");
				xos_mutex_unlock( & socket->readMutex );
				return XOS_FAILURE;
				};
			dcsMessage->binaryBufferSize = dcsMessage->binaryInSize;
			}
		
		//read the binary message
		if ( socket_read_no_mutex( socket,
											dcsMessage->binaryInBuffer,
											dcsMessage->binaryInSize) != XOS_SUCCESS )
			{
			socket->connectionGood = FALSE;
			xos_error("socket error reading binary message");
			xos_mutex_unlock( & socket->readMutex );
			return XOS_FAILURE;
			}
		}

	/* unlock the socket read mutex */
	if ( xos_mutex_unlock( & socket->readMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_socket_read -- unlock mutex failed" );
		return XOS_FAILURE;
		}

	//puts("got message");
	/* report success */
	return XOS_SUCCESS;
	}

xos_result_t socket_read_no_mutex( xos_socket_t*	socket, 
											  char* 			buffer, 
											  int 				numBytes )
	{
	/* local variables */
	fd_set				readMask;
	int					descriptorTableSize;
	int					selectResult;
	int bytesLeft 		= numBytes;
	char * bufferPtr	= buffer;
	int bytesRead 		= 0;	
	
	if ( ! socket->blockOnRead )
		{
		/* get total number of file descriptors to check */
		descriptorTableSize = SOCKET_GETDTABLESIZE();
		
		/* initialize descriptor mask for select */
		FD_ZERO( &readMask );
		FD_SET( socket->clientDescriptor, &readMask );
		}

	/* call read() iteratively to get all the bytes */
	while ( bytesLeft > 0 )
		{
		if ( !socket->blockOnRead )
			{
			/* wait until socket becomes readable */
			selectResult = select ( descriptorTableSize, &readMask,
											NULL, NULL, &socket->readTimeout );
			
			/* report result */
			switch ( selectResult )
				{
				case SOCKET_SELECT_TIMEOUT:
					socket->connectionGood = FALSE;
					return XOS_FAILURE;
					
				case SOCKET_SELECT_ERROR:		
					xos_socket_print_error( "xos_socket_wait_until_readable--select");
					socket->connectionGood = FALSE;
					/* unlock the socket read mutex */
					return XOS_FAILURE;
				default:
					//data ready to read
					break;
				}
			}
		// try to read the remaining bytes desired
		if ( ( bytesRead = 
				 SOCKET_RECV( socket->clientDescriptor, 
								  bufferPtr, bytesLeft, 0 ) ) <= 0 )
			{
			xos_socket_print_error( "xos_socket_read--read" );
			socket->connectionGood = FALSE;
			return XOS_FAILURE;
			}
		
		/* prepare for next iteration of read loop */
		bytesLeft -= bytesRead;
		bufferPtr += bytesRead;
		}
	return XOS_SUCCESS;
	}

/****************************************************************
 	xos_socket_write:  Writes 'numBytes' bytes from 'buffer'
 	into 'socket'.  Returns number of bytes actually written, or 
 	-1 on error in write system call.
****************************************************************/  
xos_result_t xos_socket_write
	( 
	xos_socket_t*	socket, 
	const char*	 	buffer, 
	int 				numBytes
	)

	{
	/* local variables */
	int bytesLeft 				= numBytes;
	const char* bufferPtr 	= buffer;
 	int bytesWritten			= 0;

	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_socket_write: connection not good");
		return XOS_FAILURE;
		}

	/* lock the socket mutex */
	if ( xos_mutex_lock( &socket->writeMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_socket_write--wait for mutex failed" );
		return XOS_FAILURE;
		}

	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* make sure passed byte pointer is valid */
	assert( buffer != NULL );
	
	/* make sure socket is valid */
	assert( socket->socketStructValid == TRUE );

 	/* call write() iteratively to send all the bytes */
	while ( bytesLeft > 0 )
		{
		/* try to write the remaining bytes */
		if ( ( bytesWritten = 
			SOCKET_SEND( socket->clientDescriptor, (char*) bufferPtr, 
				bytesLeft, 0 ) ) == SOCKET_SEND_ERROR || bytesWritten == 0 )
			{
			xos_socket_print_error( "xos_socket_write--write" );
			socket->connectionGood = FALSE;
			xos_mutex_unlock( & socket->writeMutex );
			return XOS_FAILURE;
			}
		
		/* prepare for next iteration of write loop */
		bytesLeft -= bytesWritten;
		bufferPtr += bytesWritten;
		}

#ifndef XOS_PRODUCTION_CODE
	//puts(buffer);
#endif
	
	/* unlock the socket write mutex */
	if ( xos_mutex_unlock( & socket->writeMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_socket_write -- unlock mutex failed" );
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
	} 




// ***************************************************************
// xos_send_dcs_message:  Generates a header for the dcs message
//                        and sends the complete message while
//                        locking the socket mutex.
// ************************************************************** 
 
xos_result_t xos_send_dcs_message ( xos_socket_t  * socket, 
												const char * textMessage,
												const char * binaryMessage,
												long         binarySize )
	{
	char header[30];
	size_t textOutSize = strlen(textMessage) + 1;

	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_send_dcs_message: connection not good");
		return XOS_FAILURE;
		}

	/* lock the socket mutex */
	if ( xos_mutex_lock( &socket->writeMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_send_dcs_message--wait for mutex failed" );
		return XOS_FAILURE;
		}

	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* make sure passed byte pointer is valid */
	//assert( dcsMessage != NULL );
	
	/* make sure socket is valid */
	assert( socket->socketStructValid == TRUE );


 	// send the dcs message header
	sprintf( header,"%12ld %12ld ", textOutSize, binarySize);

	if (socket_send_no_mutex ( socket,
										header,
										DCS_HEADER_SIZE) != XOS_SUCCESS) 
		{
		xos_error("xos_send_dcs_text_message: could not send header.");
		socket->connectionGood = FALSE;
		xos_mutex_unlock( & socket->writeMutex );
		return XOS_FAILURE;
		}
	
	// send the dcs text message
	if (socket_send_no_mutex ( socket, textMessage, textOutSize) != XOS_SUCCESS) 
		{
		xos_error("xos_send_dcs_text_message: could not send text portion.");
		socket->connectionGood = FALSE;
		xos_mutex_unlock( & socket->writeMutex );
		return XOS_FAILURE;
		}

	// send the dcs binary message
	if (socket_send_no_mutex ( socket, binaryMessage, binarySize) != XOS_SUCCESS) 
		{
		xos_error("xos_send_dcs_text_message: could not send text portion.");
		socket->connectionGood = FALSE;
		xos_mutex_unlock( & socket->writeMutex );
		return XOS_FAILURE;
		}
	
	// unlock the socket write mutex
	if ( xos_mutex_unlock( & socket->writeMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_send_dcs_message -- unlock mutex failed" );
		return XOS_FAILURE;
		}

	/* report success */
	return XOS_SUCCESS;
	} 



xos_result_t xos_send_dcs_text_message ( xos_socket_t  * socket, 
													  const char *   textMessage )
	{
	char header[30];
	size_t textOutSize = strlen(textMessage) + 1;

	/* return failure if connection not good */
	if ( ! socket->connectionGood || ! socket->connectionActive )
		{
		socket->connectionGood = FALSE;
		xos_error("xos_send_dcs_text_message: connection not good");
		return XOS_FAILURE;
		}

	// lock the socket mutex
	if ( xos_mutex_lock( &socket->writeMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_send_dcs_text_message: --wait for mutex failed" );
		return XOS_FAILURE;
		}

	// make sure passed xos_socket pointer is valid
	assert( socket != NULL );
	
	// make sure socket is valid
	assert( socket->socketStructValid == TRUE );

 	// send the dcs message header
	sprintf( header,"%12ld %12ld ", textOutSize, 0);

	if (socket_send_no_mutex ( socket,
										header,
										DCS_HEADER_SIZE) != XOS_SUCCESS) 
		{
		xos_error("xos_send_dcs_text_message: could not send header.");
		socket->connectionGood = FALSE;
		xos_mutex_unlock( & socket->writeMutex );
		return XOS_FAILURE;
		}
	
	// send the dcs text message
	if (socket_send_no_mutex ( socket, textMessage, textOutSize) != XOS_SUCCESS) 
		{
		xos_error("xos_send_dcs_text_message: could not send text portion.");
		socket->connectionGood = FALSE;
		xos_mutex_unlock( & socket->writeMutex );
		return XOS_FAILURE;
		}

	// unlock the socket write mutex
	if ( xos_mutex_unlock( & socket->writeMutex ) != XOS_SUCCESS )
		{
		socket->connectionGood = FALSE;
		xos_error( "xos_socket_write -- unlock mutex failed" );
		return XOS_FAILURE;
		}

	// report success
	return XOS_SUCCESS;
	} 





xos_result_t socket_send_no_mutex( xos_socket_t * socket,
											  const char * buffer,
											  int numBytes )
	{
	/* local variables */
	int bytesLeft 				= numBytes;
	const char* bufferPtr 	= buffer;
 	int bytesWritten			= 0;	

	/* call write() iteratively to send all the header bytes */
	while ( bytesLeft > 0 )
		{
		/* try to write the remaining bytes */
		if ( ( bytesWritten = SOCKET_SEND( socket->clientDescriptor,
													  (char*) bufferPtr, 
													  bytesLeft, 0 )
				 ) == SOCKET_SEND_ERROR || bytesWritten == 0 )
			{
			xos_socket_print_error( "xos_socket_write--write" );
			socket->connectionGood = FALSE;
			return XOS_FAILURE;
			}
		
		/* prepare for next iteration of write loop */
		bytesLeft -= bytesWritten;
		bufferPtr += bytesWritten;
		}
	return XOS_SUCCESS;
	} 




/****************************************************************
 	xos_socket_disconnect:  Disconnects a server socket from a
 	client process without invalidating the socket structure.  
 	May not be called by a client socket.  Returns -1 if a socket 
 	system call fails.  If successful, returns 0.
****************************************************************/ 

xos_result_t xos_socket_disconnect( xos_socket_t* socket )
	{
	/* local variables */
	int syscallResult;

	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );

	/* invalidate client address and connection */

   socket->connectionActive 	= FALSE;
	socket->connectionGood	 	= FALSE;
	
	//don't shutdown the socket if it has already been done
  	if ( socket->clientAddressValid == FALSE)
		{
		xos_error("xos_socket_disconnect: socket already closed\n");
		return XOS_SUCCESS;
		}
	
	// indicate that the socket has been shutdown already
	socket->clientAddressValid = FALSE;

	
	/* make sure passed socket is for a server process */
	assert( socket->process == SP_SERVER );
	
	/* shutdown the socket */
	SOCKET_SHUTDOWN( socket->clientDescriptor, 2 );
	
	/* close the socket */
	syscallResult = SOCKET_CLOSE( socket->clientDescriptor );

	/* check for error in close */
	if ( syscallResult == SOCKET_CLOSE_ERROR )
 		{
  		xos_socket_print_error( "xos_socket_disconnect--close" );
  		return XOS_FAILURE;
  		}
  		   
  	/* report success */
  	return XOS_SUCCESS;
	}
	
	
/****************************************************************
 	xos_socket_destroy:  Disconnects socket from current peer and
 	invalidates entire socket structure.  Returns -1 if a socket 
 	system call fails.  If successful, returns 0.
****************************************************************/ 

xos_result_t xos_socket_destroy( xos_socket_t* socket )
	{
	/* local variables */
	int syscallResult;

	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );


	/* shutdown the appropriate socket descriptor */
	if ( socket->process == SP_SERVER )	
		{
		//puts("close server");
		if ( socket->serverAddressValid )
			{
			SOCKET_SHUTDOWN( socket->serverDescriptor, 2 );
			syscallResult = SOCKET_CLOSE( socket->serverDescriptor );
			}
		
		/* check for error in close */
		if ( syscallResult != 0 )
			{
			xos_socket_print_error( "xos_socket_destroy (close server) --" );
			}
		}
	
	if ( socket->clientAddressValid == TRUE )
		{
		//puts("close client"); 
		SOCKET_SHUTDOWN( socket->clientDescriptor, 2 );
		syscallResult = SOCKET_CLOSE( socket->clientDescriptor );
		/* check for error in close */
		if ( syscallResult != 0 )
			{
			xos_socket_print_error( "xos_socket_destroy (close client) --" );
			}
		}

	//puts("close readMutex");
	/* destroy read mutex */
	if ( xos_mutex_close( &socket->readMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_destroy--close read mutex failed" );
  		return XOS_FAILURE;
  		}

	//puts("close writeMutex");
	/* destroy write mutex */
	if ( xos_mutex_close( &socket->writeMutex ) != XOS_SUCCESS )
 		{
  		xos_error( "xos_socket_destroy--close write mutex failed" );
  		return XOS_FAILURE;
  		}


  	/* invalidate the entire socket */
   socket->clientAddressValid = FALSE;
  	socket->serverAddressValid = FALSE;
  	socket->socketStructValid  = FALSE;
  	socket->serverListening		= FALSE; 	
	socket->connectionActive 	= FALSE;
	socket->connectionGood	 	= FALSE;
  		
	//puts("socket destroyed");
  	/* report success */
  	return XOS_SUCCESS;
  	}	
	

/****************************************************************
	xos_socket_print:  Write contents of xos_socket_t structure to 
	standard output.  Used for debugging purposes.  Always returns 0.
****************************************************************/ 
 
xos_result_t xos_socket_print
	( 
	const xos_socket_t* socket 
	)
	
	{
	/* make sure passed xos_socket pointer is valid */
	assert( socket != NULL );
	
	/* print out process */
	switch ( socket->process )
		{
		case SP_CLIENT:	
			puts( "process = client" );
			break;
		
		case SP_SERVER:
			puts( "process = server" );
			break;
		
		default:
			puts( "process = UNKNOWN" );
			break;
		}
		
	/* print out incoming request queue length for server processes */
	if ( socket->process == SP_SERVER )
		printf( "request queue length = %ld\n", socket->queueLength );

	/* print out address structures */

	puts( "\nServer address:" );
	xos_socket_address_print( &socket->serverAddress );

	puts( "\nClient address:" );
	xos_socket_address_print( &socket->clientAddress );

	return XOS_SUCCESS;
	}


/****************************************************************
 	xos_socket_address_init:  Initializes a xos_socket_address_t for 
	use. Sets the protocol family to AF_INET (internet), the address
 	to INADDR_ANY (for servers allows any client to connect),
 	and the port to 0 (for clients requests a unique port on 
 	binding).  This function should be called before any other
 	in this file.  This function can't fail so it always returns 0.
****************************************************************/ 	

xos_result_t xos_socket_address_init
	(
	xos_socket_address_t* address
	)
	
	{
	/* make sure address pointer is valid */
	assert( address != NULL );
	
	/* initialize data members */
	address->sin_family			= AF_INET;
	address->sin_addr.s_addr	= htonl( INADDR_ANY );
  	address->sin_port 			= htons( 0 );
  	
  	/* report success */
  	return XOS_SUCCESS;
  	}
  	

/****************************************************************
 	xos_socket_address_set_port:  Sets the port associated with the
 	address to the passed value.  This function can't fail so
 	it always returns 0.
****************************************************************/ 	
  	
xos_result_t xos_socket_address_set_port
	( 
	xos_socket_address_t*	address,
	xos_socket_port_t 		port
	)
	
	{
	/* make sure address pointer is valid */
	assert( address != NULL );
	
	/* make sure address has been initialized */
	/* assert( address->sin_family == AF_INET ); */	
	
	/* simply copy the argument into the sin_port member */
  	address->sin_port = htons( port );

  	/* report success */
  	return XOS_SUCCESS;
  	}


/****************************************************************
 	xos_socket_address_get_port:  Returns the port number associated
 	with the address.
****************************************************************/ 	

xos_socket_port_t xos_socket_address_get_port
	( 
	const xos_socket_address_t* address 
	)
	
	{
	/* make sure address pointer is valid */
	assert( address != NULL );
	
	/* make sure address has been initialized */
	/*assert( address->sin_family == AF_INET );	*/
	
	/* return the sin_port member */
	return ntohs( address->sin_port );
	}


/****************************************************************
 	xos_socket_address_set_ip_by_name:  Sets the ip number associated
 	with the address by looking up the passed name using DNS.
 	Returns -1 on failure, which includes not finding the name
 	in the database.  Returns 0 on success.
****************************************************************/ 	

xos_result_t xos_socket_address_set_ip_by_name( xos_socket_address_t* address, 
																const char* 			 hostname )	
	{
	/* local variables */
	struct 	hostent* host;
	int   intIpArray[4];
	byte	ipArray[4];
	
	/* make sure address pointer is valid */
	assert( address != NULL );
	
	/* make sure char pointer is valid */
	assert( hostname != NULL );
	
	/* make sure address has been initialized */
	//assert( address->sin_family == AF_INET );	
	
	/* Check to see if the hostname is in IP format */
	if ( sscanf( hostname ,"%d.%d.%d.%d",
					 &intIpArray[0],
					 &intIpArray[1],
					 &intIpArray[2],
					 &intIpArray[3] ) != 4 )
		{
		//puts("About to do gethostbyname"); puts(hostname);

		/* get host information from host name */
		host = gethostbyname( hostname );
		
		/* check for error looking up the name */
		if ( host == NULL )
			{
			xos_socket_print_error( "socket_address_set_by_name--gethostbyname" );
			return XOS_FAILURE;
			}
		
		/* get the ip number from the hostent structure */
		xos_socket_address_set_ip( address, (byte*) (host->h_addr) );
		}
	else
		{
		//puts("ip");	
		ipArray[0] = (byte)intIpArray[0];
		ipArray[1] = (byte)intIpArray[1];
		ipArray[2] = (byte)intIpArray[2];
		ipArray[3] = (byte)intIpArray[3];

		/* set the ip address directly, avoiding thread-unsafe gethostbyname */
		xos_socket_address_set_ip( address, ipArray );
		}
	
  	/* report success */
  	return XOS_SUCCESS;
 	}


/****************************************************************
 	xos_socket_address_get_ip:  Returns the ip number associated with
 	the address in a 4-byte array passed in the second argument.
 	This function can't fail so it always returns 0.
****************************************************************/ 	

xos_result_t xos_socket_address_get_ip ( const xos_socket_address_t*	address,	 
													  byte*								ipArray )
	
	{
	/* local variables */
	byte* ip;

	/* make sure address pointer is valid */
	assert( address != NULL );

	/* make sure byte pointer is valid */
	assert( ipArray != NULL );

	/* make sure address has been initialized */
	//assert( address->sin_family == AF_INET );	
	
	/* point to IP address in sockaddr_in structure */
	ip = ((byte*) address) + 4;
	
	/* copy values from address structure into passed array */
	ipArray[0] = ip[0];
	ipArray[1] = ip[1];
	ipArray[2] = ip[2];
	ipArray[3] = ip[3];
	
	return XOS_SUCCESS;	
	}
	

xos_result_t xos_socket_compare_address ( const xos_socket_address_t*	address1,
														const xos_socket_address_t*	address2 )
	{
	/* local variables */
	byte* ip1;
	byte* ip2;

	/* make sure address pointer is valid */
	if ( address1 == NULL ) return XOS_FAILURE;
	if ( address2 == NULL ) return XOS_FAILURE;

	/* make sure address has been initialized */
	//assert( address1->sin_family == AF_INET );	
	//assert( address2->sin_family == AF_INET );

	/* point to IP address in sockaddr_in structure */
	ip1 = ((byte*) address1) + 4;
	ip2 = ((byte*) address2) + 4;
	
	/* compare the ip numbers of both addresses. */
	if ( ( ip1[0] == ip2[0] )  &&
		  ( ip1[1] == ip2[1] )  &&
		  ( ip1[2] == ip2[2] )  &&
		  ( ip1[3] == ip2[3] ) )
		{
		return XOS_SUCCESS;
		}
	else
		{
		return XOS_FAILURE;
		}

	}


/****************************************************************
 	xos_socket_address_set_ip:  Sets the ip number associated with
 	the address from a 4-byte array passed in the second argument.
 	This function can't fail so it always returns 0.
****************************************************************/ 	
	
xos_result_t xos_socket_address_set_ip
	( 
	xos_socket_address_t*	address,	 
	const byte*					ipArray
	)	
	
	{
	/* local variables */
	byte* ip;

	/* make sure address pointer is valid */
	assert( address != NULL );
	
	/* make sure byte pointer is valid */
	assert( ipArray != NULL );
	
	/* make sure address has been initialized */
	//assert( address->sin_family == AF_INET );	

	/* point to IP address in sockaddr_in structure */
	ip = ((byte*) address) + 4;
	
	/* copy passed array into address structure */
	ip[0] = ipArray[0];
	ip[1] = ipArray[1];
	ip[2] = ipArray[2];
	ip[3] = ipArray[3];
	
	return XOS_SUCCESS;
	}

/****************************************************************
 	xos_socket_address_print:  Writes contents of address structure 
 	to standard output.  Used for debugging purposes.  Always 
 	returns 0.
****************************************************************/ 	

xos_result_t xos_socket_address_print ( const xos_socket_address_t* address )	
	{
	/* local variables */
	byte* ip;

	/* make sure address pointer is valid */
	assert( address != NULL );

	/* point to IP address in sockaddr_in structure */
	ip = ((byte*) address) + 4;
	
	/* print out the structure contents */
	printf( "sin_family        = %d\n", address->sin_family );
	printf( "sin_port          = %d\n", ntohs( address->sin_port ) );
	printf( "sin_addr.s_addr   = %u  ", address->sin_addr.s_addr );
	printf( "( ip num = %u %u %u %u ) \n", ip[0], ip[1], ip[2], ip[3] );
	
	/* report success */
	return XOS_SUCCESS;
	}
	



/****************************************************************
    xos_socket_create_client:  Initializes a xos_socket_t
    structure for using a socket in a client process and creates
    the actual socket.  Returns -1 if a socket system call fails.
    If successful, returns 0.
****************************************************************/

xos_result_t xos_udp_create_client
    (
    xos_socket_t*   newSocket,
    const char* server,
    xos_socket_port_t port
    )

    {
        
    /* local variables */
    xos_socket_address_t            localAddress;
    xos_socket_address_size_t   addressSize = sizeof(localAddress);
    int reuseAddress = 1;

    /* make sure passed xos_socket pointer is valid */
    assert( newSocket != NULL );

    /* declare socket structure and both addresses invalid */
    newSocket->socketStructValid    = FALSE;
    newSocket->serverAddressValid   = FALSE;
    newSocket->clientAddressValid   = FALSE;
    newSocket->serverListening      = FALSE;
    newSocket->connectionActive = FALSE;
    newSocket->connectionGood       = FALSE;

    /* initialize read mutex */
    if ( xos_mutex_create( &newSocket->readMutex ) != XOS_SUCCESS )
        {
        xos_error( "xos_udp_create_client--create read mutex failed" );
        return XOS_FAILURE;
        }

    /* initialize write mutex */
    if ( xos_mutex_create( &newSocket->writeMutex ) != XOS_SUCCESS )
        {
        xos_error( "xos_udp_create_client--create write mutex failed" );
        return XOS_FAILURE;
        }

    /* initialize members of xos_socket_t structure */
    newSocket->process      = SP_CLIENT;
//  newSocket->queueLength  = SOCKET_DEFAULT_QUEUE_LENGTH;

    /* create the socket */
    if ( ( newSocket->clientDescriptor =
        SOCKET_CREATE( AF_INET, SOCK_DGRAM, 0 ) ) == SOCKET_CREATE_ERROR )
        {
        xos_socket_print_error( "xos_udp_create_client--socket" );
        return XOS_FAILURE;
        }

    /* initialize the local end of the socket. Bind to any port
       for this end of the socket */
    xos_socket_address_init( &newSocket->clientAddress );

    /* initialize the remote end of the socket. Will be used
       when sending a udp message with sendto(). */
    xos_socket_address_init( &newSocket->serverAddress );
    xos_socket_address_set_ip_by_name( &newSocket->serverAddress, server );
    xos_socket_address_set_port(&newSocket->serverAddress, port);
    /* set address of image server using listening port */


#ifndef WIN32
    /* set REUSEADDR socket option */
    setsockopt( newSocket->clientDescriptor, SOL_SOCKET, SO_REUSEADDR,
        (char *) &reuseAddress, sizeof( reuseAddress ) );
#endif

    /* bind address to socket */
    if ( SOCKET_BIND( newSocket->clientDescriptor,
        (struct sockaddr*) &(newSocket->clientAddress),
        sizeof( newSocket->clientAddress ) ) == SOCKET_BIND_ERROR )
        {
        xos_socket_print_error( "xos_udp_create_client--bind" );
        return XOS_FAILURE;
        }

    /* retrieve actual port number used since 0 was passed as
       local port.  */
    if ( SOCKET_GETSOCKNAME( newSocket->clientDescriptor,
        (struct sockaddr*) &localAddress, &addressSize ) == -1 )
        {
        xos_socket_print_error( "xos_udp_create_client--getsockname" );
        return XOS_FAILURE;
        }

    /* copy socket port value to socket structure */
    xos_socket_address_set_port( &newSocket->clientAddress,
                xos_socket_address_get_port( &localAddress ) );

    /* declare socket structure and local address valid */
    newSocket->socketStructValid  = TRUE;
    newSocket->clientAddressValid = TRUE;
    newSocket->serverAddressValid = TRUE;
    newSocket->connectionGood     = TRUE;
    newSocket->connectionActive   = TRUE;

    /* report success */
    return XOS_SUCCESS;
    }

/****************************************************************
    xos_socket_write:  Writes 'numBytes' bytes from 'buffer'
    into 'socket'.  Returns number of bytes actually written, or
    -1 on error in write system call.
****************************************************************/
xos_result_t xos_udp_write
    (
    xos_socket_t*   socket,
    const char*     buffer,
    int                 numBytes
    )

    {
        
    /* local variables */
    int bytesLeft               = numBytes;
    const char* bufferPtr   = buffer;
    int bytesWritten            = 0;

    /* return failure if connection not good */
    if ( ! socket->connectionGood || ! socket->connectionActive )
        {
        socket->connectionGood = FALSE;
        xos_error("xos_udp_write: connection not good");
        return XOS_FAILURE;
        }

    /* lock the socket mutex */
    if ( xos_mutex_lock( &socket->writeMutex ) != XOS_SUCCESS )
        {
        socket->connectionGood = FALSE;
        xos_error( "xos_udp_write--wait for mutex failed" );
        return XOS_FAILURE;
        }

    /* make sure passed xos_socket pointer is valid */
    assert( socket != NULL );
    
    
    /* make sure passed byte pointer is valid */
    assert( buffer != NULL );

    /* make sure socket is valid */
    assert( socket->socketStructValid == TRUE );

    /* call write() iteratively to send all the bytes */
    while ( bytesLeft > 0 )
        {
        /* try to write the remaining bytes */
        if ( ( bytesWritten =
            SOCKET_SENDTO( socket->clientDescriptor, (char*) bufferPtr,
                bytesLeft, 0,
                (struct sockaddr *)&(socket->serverAddress),
                sizeof(socket->serverAddress)) ) == SOCKET_SENDTO_ERROR || bytesWritten == 0 )
            {
            xos_socket_print_error( "xos_udp_write--write" );
            socket->connectionGood = FALSE;
            xos_mutex_unlock( & socket->writeMutex );
            return XOS_FAILURE;
            }

        /* prepare for next iteration of write loop */
        bytesLeft -= bytesWritten;
        bufferPtr += bytesWritten;
        }

#ifndef XOS_PRODUCTION_CODE
    //puts(buffer);
#endif

    /* unlock the socket write mutex */
    if ( xos_mutex_unlock( & socket->writeMutex ) != XOS_SUCCESS )
        {
        socket->connectionGood = FALSE;
        xos_error( "xos_udp_write -- unlock mutex failed" );
        return XOS_FAILURE;
        }

    /* report success */
    return XOS_SUCCESS;
    }


/****************************************************************
 * @func socket_read_any_length_no_mutex:
 * Called by socket_read_any_length()
****************************************************************/
static xos_result_t socket_read_line_no_mutex( xos_socket_t*    socket,
                                              char*             buffer,
                                              int               numBytes,
                                              int*              numRead)
    {
    /* local variables */
    fd_set              readMask;
    int                 descriptorTableSize;
    int                 selectResult;
    char* bufferPtr    = buffer;
    int bytesRead = 0;
    char localBuf[1];
    int pos = 0;
    int found = 0;

    if ( ! socket->blockOnRead )
    {
        /* get total number of file descriptors to check */
        descriptorTableSize = SOCKET_GETDTABLESIZE();

        /* initialize descriptor mask for select */
        FD_ZERO( &readMask );
        FD_SET( socket->clientDescriptor, &readMask );

        /* wait for a period of time until socket becomes readable */
        selectResult = select ( descriptorTableSize, &readMask,
                                        NULL, NULL, &socket->readTimeout );

        /* report result */
        switch ( selectResult )
        {
            case SOCKET_SELECT_TIMEOUT:
            	xos_error("socket_read_any_length_no_mutex: socket time out\n");
                socket->connectionGood = FALSE;
                return XOS_FAILURE;

            case SOCKET_SELECT_ERROR:
                xos_socket_print_error( "socket_read_any_length_no_mutex: select failed");
                xos_error("Socket select error\n");
                socket->connectionGood = FALSE;
                /* unlock the socket read mutex */
                return XOS_FAILURE;
            default:
                //data ready to read
                break;
        }

    }

    // try to read the bytes desired
    // bytesRead = 0 if the socket is closed properly.
    // < 0 if there is an error.
//    memset(bufferPtr, 0, numBytes);
    while (!found && (pos < numBytes)) {
    
		bytesRead = SOCKET_RECV( socket->clientDescriptor, localBuf, 1, 0);
				
		if (bytesRead < 0) {
			xos_socket_print_error( "socket_read_no_mutex_until: recv failed" );
			xos_error("Socket recv returns < 0\n");
			socket->connectionGood = FALSE;
			return XOS_FAILURE;
		} else if (bytesRead == 0) {
			break;
		}
				
		if (*localBuf == '\n') {
			found = 1;
		}
		
		bufferPtr[pos] = *localBuf;
		++pos;
	}
	
	bufferPtr[pos] = '\0';
	
	*numRead = strlen(bufferPtr);
	
    return XOS_SUCCESS;

}


/****************************************************************
 * @func socket_read_any_length_no_mutex:
 * Called by socket_read_any_length()
****************************************************************/
static xos_result_t socket_read_any_length_no_mutex( xos_socket_t*    socket,
                                              char*             buffer,
                                              int               numBytes,
                                              int*              numRead)
    {
    /* local variables */
    fd_set              readMask;
    int                 descriptorTableSize;
    int                 selectResult;
    int bytesLeft       = numBytes;
    char * bufferPtr    = buffer;
    int bytesRead       = 0;

    if ( ! socket->blockOnRead )
    {
        /* get total number of file descriptors to check */
        descriptorTableSize = SOCKET_GETDTABLESIZE();

        /* initialize descriptor mask for select */
        FD_ZERO( &readMask );
        FD_SET( socket->clientDescriptor, &readMask );

        /* wait for a period of time until socket becomes readable */
        selectResult = select ( descriptorTableSize, &readMask,
                                        NULL, NULL, &socket->readTimeout );

        /* report result */
        switch ( selectResult )
        {
            case SOCKET_SELECT_TIMEOUT:
            	xos_error("socket_read_any_length_no_mutex: socket time out\n");
                socket->connectionGood = FALSE;
                return XOS_FAILURE;

            case SOCKET_SELECT_ERROR:
                xos_socket_print_error( "socket_read_any_length_no_mutex: select failed");
                xos_error("Socket select error\n");
                socket->connectionGood = FALSE;
                /* unlock the socket read mutex */
                return XOS_FAILURE;
            default:
                //data ready to read
                break;
        }

    }

    // try to read the bytes desired
    // bytesRead = 0 if the socket is closed properly.
    // < 0 if there is an error.
    bytesRead =SOCKET_RECV( socket->clientDescriptor,
                              bufferPtr, bytesLeft, 0  );
    if ( bytesRead < 0 )
    {
        xos_socket_print_error( "socket_read_any_length_no_mutex: recv failed" );
        xos_error("Socket recv returns < 0\n");
        socket->connectionGood = FALSE;
        return XOS_FAILURE;
    }
    
    // Notice that we don't terminate the string with \0.
    // application must do it 
    
    *numRead = bytesRead;

    return XOS_SUCCESS;

}


/****************************************************************
    xos_socket_read_any_length:  Reads up to numBytes from the socket
    or until recv returns -1, when there is an error or end of
    stream. The calling func must check the returned number of bytes.
****************************************************************/
xos_result_t xos_socket_read_any_length ( xos_socket_t*    socket,
                                         char*          buffer,
                                         int            numBytes,
                                         int*           numBytesReceived)
    {
    /* make sure passed xos_socket pointer is valid */
    assert( socket != NULL );

    /* make sure passed byte pointer is valid */
    assert( buffer != NULL );

    /* make sure passed numBytesReceived is valid */
    assert( numBytesReceived != NULL );

    /* make sure socket is valid */
    assert( socket->socketStructValid == TRUE );

    /* return failure if connection not good */
    if ( ! socket->connectionGood || ! socket->connectionActive )
        {
        socket->connectionGood = FALSE;
        xos_log("xos_socket_read_any_length: connection not good\n");
        return XOS_FAILURE;
        }

    /* lock the socket read mutex */
    if ( xos_mutex_lock( &socket->readMutex ) != XOS_SUCCESS )
        {
        socket->connectionGood = FALSE;
        xos_error( "xos_socket_read_any_length: wait for mutex failed\n" );
        return XOS_FAILURE;
        }

    // call appropriate read function based on blocking mode.
    memset(buffer, 0, numBytes);
    if ( socket_read_any_length_no_mutex( socket, buffer, numBytes, numBytesReceived ) != XOS_SUCCESS)
        {
        xos_mutex_unlock( & socket->readMutex );
        socket->connectionGood = FALSE;
        xos_error("xos_socket_read_any_length: failed in socket_read_any_length_no_mutex\n");
        return XOS_FAILURE;
        }

    /* numBytesReceived == 0 means the socket is properly close.
       < 0 means there is an error in the socket.
       Either case, we set the connectGood to false. */
    if (*numBytesReceived <= 0) {
        socket->connectionGood = FALSE;
    }

    /* unlock the socket read mutex */
    if ( xos_mutex_unlock( & socket->readMutex ) != XOS_SUCCESS )
        {
        socket->connectionGood = FALSE;
        xos_error( "xos_socket_read_any_length: unlock mutex failed\n" );
        return XOS_FAILURE;
        }

    /* report success */
    return XOS_SUCCESS;

}


/****************************************************************
    xos_socket_read_line:  Reads up to numBytes from the socket
    or until recv returns -1, when there is an error or end of
    stream. The calling func must check the returned number of bytes.
****************************************************************/
xos_result_t xos_socket_read_line ( xos_socket_t*    socket,
                                         char*          buffer,
                                         int            numBytes,                                     
                                         int*           numBytesReceived)
    {
    /* make sure passed xos_socket pointer is valid */
    assert( socket != NULL );

    /* make sure passed byte pointer is valid */
    assert( buffer != NULL );

    /* make sure passed numBytesReceived is valid */
    assert( numBytesReceived != NULL );

    /* make sure socket is valid */
    assert( socket->socketStructValid == TRUE );
    
    /* return failure if connection not good */
    if ( ! socket->connectionGood || ! socket->connectionActive )
        {
        socket->connectionGood = FALSE;
        xos_log("xos_socket_read_any_length: connection not good\n");
        return XOS_FAILURE;
        }

    /* lock the socket read mutex */
    if ( xos_mutex_lock( &socket->readMutex ) != XOS_SUCCESS )
        {
        socket->connectionGood = FALSE;
        xos_error( "xos_socket_read_any_length: wait for mutex failed\n" );
        return XOS_FAILURE;
        }

    // call appropriate read function based on blocking mode.
    *numBytesReceived = 0;
    memset(buffer, 0, numBytes);
    if ( socket_read_line_no_mutex( socket, buffer, numBytes, numBytesReceived ) != XOS_SUCCESS)
        {
        xos_mutex_unlock( & socket->readMutex );
        socket->connectionGood = FALSE;
        xos_error("xos_socket_read_any_length: failed in socket_read_any_length_no_mutex\n");
        return XOS_FAILURE;
        }

	/* numBytesReceived == 0 means the socket is properly close.
	   < 0 means there is an error in the socket.
	   Either case, we set the connectGood to false. */
	if (*numBytesReceived <= 0) {
		socket->connectionGood = FALSE;
	} else {

		// Remove end of line characters
		if (buffer[*numBytesReceived-1] == '\n') {
			buffer[*numBytesReceived-1] = '\0';
		}
		if (buffer[*numBytesReceived-2] == '\r') {
			buffer[*numBytesReceived-2] = '\0';
		}
	}
	
	*numBytesReceived = strlen(buffer);

    /* unlock the socket read mutex */
    if ( xos_mutex_unlock( & socket->readMutex ) != XOS_SUCCESS )
        {
        socket->connectionGood = FALSE;
        xos_error( "xos_socket_read_any_length: unlock mutex failed\n" );
        return XOS_FAILURE;
        }

    /* report success */
    return XOS_SUCCESS;

}


/****************************************************************
	xos_socket_library_startup:  Initializes WinSock DLL.  Returns 0 
	if successful, -1 if WSAStartup call fails.  Prints details about
	WinSock implementation to standard output if successful.
****************************************************************/ 

xos_result_t xos_socket_library_startup( void )

{	
#if defined WIN32	/* declare WIN32 specific functions */
	/* local variables */ 
	WSADATA WSADataStructure;
	int syscallResult;
	
    /* only need to be called once */
    /* xos may be used in many packages */
    if (startupCalled) return previousStartupResult;

	/* request WinSock 1.1 */
	syscallResult = WSAStartup( 0x0101, &WSADataStructure );
	
	/* check for error in WSAStartup */
	if ( syscallResult != 0 )
		{
		PRINT_ERROR( "xos_socket_library_startup--WSAStartup: "
						 "Error starting WinSock" );
        previousStartupResult = XOS_FAILURE;
        startupCalled = 1;
		return XOS_FAILURE;
		}
	
	/* print out contents of WSADataStructure */ 
	printf( "********** WinSock API Details **********\n");
	
	printf( "Requested Version:           %d.%d\n", 
		LOBYTE(WSADataStructure.wVersion), 
		HIBYTE(WSADataStructure.wVersion) );
	
	printf( "Highest Available Version:   %d.%d\n",
		LOBYTE(WSADataStructure.wHighVersion), 
		HIBYTE(WSADataStructure.wHighVersion) );
	
	printf( "Implementation Description:  %s\n",
		WSADataStructure.szDescription );
	
	printf( "System Status:               %s\n",
		WSADataStructure.szSystemStatus );

	printf( "Maximum Sockets Per Process: %ld\n",
		WSADataStructure.iMaxSockets ); 

	printf( "Maximum Datagram Size:       %ld\n",
		WSADataStructure.iMaxUdpDg );

	printf( "*****************************************\n\n");
#endif

#if defined IRIX || defined DEC_UNIX || defined LINUX
	/*disable the SIGPIPE signal */
	signal (SIGPIPE, SIG_IGN);
#endif
    startupCalled = 1;
    previousStartupResult = XOS_SUCCESS;
	/* report success */
	return XOS_SUCCESS; 
	}


/****************************************************************
	xos_socket_library_cleanup:  Clean up WinSock DLL resources.  
	Returns 0 if successful, -1 if WSACleanup call fails.
****************************************************************/ 

xos_result_t xos_socket_library_cleanup( void )
{
#ifdef WIN32
	/* local variables */
	int syscallResult;

    if (!startupCalled) return XOS_SUCCESS;

	/* request cleanup of WinSock system */
	syscallResult = WSACleanup();

	/* check for error in WSACleanup */	 
	if ( syscallResult == SOCKET_ERROR ) 
    {
  		xos_socket_print_error ("xos_socket_library_cleanup--WSACleanup" );
        startupCalled = 0;
  		return XOS_FAILURE;
  	}
#endif

	/* report success */
    startupCalled = 0;
	return XOS_SUCCESS;
	}


#ifdef WIN32		/* only need these things on Win32 platforms */

/****************************************************************
 	WSAErrorTable[]:  This is an array of WSAErrorTableEntry 
	structures.  Each entry consists of an error value and an
	explanation string.  The last error value is WSABASEERR--
	a search of the table should end when it finds this value.
****************************************************************/ 

static WSAErrorTableEntry WSAErrorTable[] = 
	{
		{	
		WSAHOST_NOT_FOUND,  
		"Host not found"
		},
		{ 
		WSATRY_AGAIN,       
		"Non-Authoritative Host not found"
		},
		{ 
		WSANO_RECOVERY,     
		"Non-Recoverable errors: FORMERR, REFUSED, NOTIMP"}
		,
		{ 
		WSANO_DATA,         
		"Valid name, no data record of requested type"
		},
		{ 
		WSASYSNOTREADY,     
		"Network SubSystem is unavailable"
		},
		{ 
		WSAVERNOTSUPPORTED, 
		"WINSOCK DLL Version out of range"
		},
		{ 
		WSANOTINITIALISED,  
		"Successful WSASTARTUP not yet performed"
		},
		{ 
		WSAEHOSTDOWN,       
		"Host is down"
		},
		{ 
		WSAEHOSTUNREACH,    
		"No Route to Host"
		},
		{ 
		WSAENOTEMPTY,       
		"Directory not empty"
		},
		{ 
		WSAEPROCLIM,        
		"Too many processes"
		},
		{ 
		WSAEUSERS,          
		"Too many users"
		},
		{
		WSAEDQUOT,          
		"Disk Quota Exceeded"
		},
		{ 
		WSAESTALE,          
		"Stale NFS file handle"
		},
		{ 
		WSAEREMOTE,         
		"Too many levels of remote in path"
		},
		{ 
		WSAEADDRINUSE,      
		"Address already in use"
		},
		{ 
		WSAEADDRNOTAVAIL,   
		"Can't assign requested address"
		},
		{ 
		WSAENETDOWN,        
		"Network is down"
		},
		{ 
		WSAENETUNREACH,     
		"Network is unreachable"
		},
		{ 
		WSAENETRESET,       
		"Net dropped connection or reset"
		},
		{ 
		WSAECONNABORTED,    
		"Software caused connection abort"
		},
		{ 
		WSAECONNRESET,      
		"Connection reset by peer"
		},
		{ 
		WSAENOBUFS,         
		"No buffer space available"
		},
		{ 
		WSAEISCONN,         
		"Socket is already connected"
		},
		{ 
		WSAENOTCONN,        
		"Socket is not connected"
		},
		{ 
		WSAESHUTDOWN,       
		"Can't send after socket shutdown"
		},
		{ 
		WSAETOOMANYREFS,    
		"Too many references, can't splice"
		},
		{ 
		WSAETIMEDOUT,       
		"Connection timed out"
		},
		{ 
		WSAECONNREFUSED,    
		"Connection refused"
		},
		{ 
		WSAELOOP,           
		"Too many levels of symbolic links"
		},
		{ 
		WSAENAMETOOLONG,    
		"File name too long"
		},
		{ 
		WSAEWOULDBLOCK,     
		"Operation would block"
		},
		{ 
		WSAEINPROGRESS,     
		"Operation now in progress"
		},
		{ 
		WSAEALREADY,        
		"Operation already in progress"
		},
		{ 
		WSAENOTSOCK,        
		"Socket operation on non-socket"
		},
		{ 
		WSAEDESTADDRREQ,    
		"Destination address required"
		},
		{ 
		WSAEMSGSIZE,        
		"Message too long"
		},
		{ 
		WSAEPROTOTYPE,      
		"Protocol wrong type for socket"
		},
		{ 
		WSAENOPROTOOPT,     
		"Bad protocol option"
		},
		{ 
		WSAEPROTONOSUPPORT, 
		"Protocol not supported"
		},
		{ 
		WSAESOCKTNOSUPPORT, 
		"Socket type not supported"
		},
		{ 
		WSAEOPNOTSUPP,      
		"Operation not supported on socket"
		},
		{ 
		WSAEPFNOSUPPORT,    
		"Protocol family not supported"
		},
		{ 
		WSAEAFNOSUPPORT,    
		"Address family not supported by protocol family"
		},
		{ 
		WSAEINVAL,          
		"Invalid argument"
		},
		{ 
		WSAEMFILE,          
		"Too many open files"
		},
		{ 
		WSAEINTR,           
		"Interrupted system call"
		},
		{ 
		WSAEBADF,           
		"Bad file number"
		},
		{ 
		WSAEACCES,          
		"Permission denied"
		},
		{ 
		WSAEFAULT,          
		"Bad address"
		},
		{ 
		WSABASEERR,         
		"No Error"
		}
  };

/****************************************************************
 	WSAPerror:  This function is used to simulate the UNIX perror()
	function on the Win32 platform for socket functions.  It looks
	up the passed error value in the table defined above, and prints
	out the explanation string for the error after the passed
	comment string.
****************************************************************/ 

void WSAPerror
	( 
	int			errorValue, 
	const char*	commentString 
	)

	{
	/* local variables */
	int errorIndex = 0;

	/* find passed error value in table	*/
	while ( WSAErrorTable[ errorIndex ].WSAErrorCode != errorValue &&
			  WSAErrorTable[ errorIndex ].WSAErrorCode != WSABASEERR )
		{
		errorIndex ++;
		}
			
	/* if a match was found, print out the error string */
	if ( WSAErrorTable[ errorIndex ].WSAErrorCode == errorValue )
		{
		fprintf( stderr, "%s: %s\n", commentString,
			WSAErrorTable[ errorIndex ].WSAErrorString );
		}
	/* ...otherwise, report an unknown error */
	else
  		{
		fprintf( stderr, "%s: Unknown error value--%d\n", 
			commentString, errorValue );
		}

	return;
	}



#endif 
