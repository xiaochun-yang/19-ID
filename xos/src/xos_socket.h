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
								xos_socket.h
								
	This is the include file associated with xos_socket.c.
	Together, these two files define an abstract data type,
	xos_socket, which is used to encapsulate the data and
	functions required for TCP sockets under all operating
	systems supported by XOS.
	
	
	Author:				Timothy M. McPhillips, SSRL.
	Last Revision:		January 16, 1997, by TMM.
	
****************************************************************/


#ifndef XOS_SOCKET_H
#define XOS_SOCKET_H


/* local include files */
#include "xos.h"

#ifdef __cplusplus
extern "C" {
#endif

/****************************************************************
	Socket calls have different names under different operating 
	systems.  The following definitions map the various system
	dependent function names (lower case) to the function names 
	used in this code (upper case).
****************************************************************/ 

#if defined VMS
#define SOCKET_CREATE			socket
#define SOCKET_BIND				bind
#define SOCKET_LISTEN			listen
#define SOCKET_ACCEPT			accept
#define SOCKET_CONNECT			connect
#define SOCKET_RECV 				recv
#define SOCKET_SEND				send
#define SOCKET_RECVFROM			recvfrom
#define SOCKET_SENDTO			sendto
#define SOCKET_CLOSE 			socket_close
#define SOCKET_PERROR 			socket_perror
#define SOCKET_GETSOCKNAME		getsockname
#define SOCKET_GETDTABLESIZE	getdtablesize
#define SOCKET_SHUTDOWN			shutdown
/*void bzero( char *,int );*/
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
#define SOCKET_CREATE			socket
#define SOCKET_BIND				bind
#define SOCKET_LISTEN			listen
#define SOCKET_ACCEPT			accept
#define SOCKET_CONNECT			connect
#define SOCKET_RECV				recv
#define SOCKET_SEND	 			send
#define SOCKET_RECVFROM			recvfrom
#define SOCKET_SENDTO			sendto
#define SOCKET_CLOSE 			close
#define SOCKET_PERROR 			perror
#define SOCKET_GETSOCKNAME		getsockname
#define SOCKET_GETDTABLESIZE	getdtablesize
#define SOCKET_SHUTDOWN			shutdown
#endif

#if defined WIN32
#define SOCKET_CREATE			socket
#define SOCKET_BIND				bind
#define SOCKET_LISTEN			listen
#define SOCKET_ACCEPT			accept
#define SOCKET_CONNECT			connect
#define SOCKET_RECV 				recv
#define SOCKET_SEND	 			send
#define SOCKET_RECVFROM			recvfrom
#define SOCKET_SENDTO			sendto
#define SOCKET_CLOSE 			closesocket
#define SOCKET_PERROR(s)  		WSAPerror( WSAGetLastError(), s )
#define SOCKET_GETSOCKNAME		getsockname
#define SOCKET_GETDTABLESIZE() -1
#define SOCKET_SHUTDOWN			shutdown
#endif
  

/****************************************************************
	Socket calls return different values indicating failure on
	different platforms.  The following definitions map the various 
	system dependent error values (2nd column) to the error values  
	used in this code (1st column).
****************************************************************/ 

#if defined VMS
#define SOCKET_CREATE_ERROR	-1
#define SOCKET_BIND_ERROR		-1
#define SOCKET_LISTEN_ERROR	-1
#define SOCKET_ACCEPT_ERROR	-1
#define SOCKET_CONNECT_ERROR	-1
#define SOCKET_RECV_ERROR		-1
#define SOCKET_SEND_ERROR		-1
#define SOCKET_RECVFROM_ERROR	-1
#define SOCKET_SENDTO_ERROR	-1
#define SOCKET_CLOSE_ERROR		-1
#define SOCKET_SELECT_ERROR	-1
#define SOCKET_SELECT_TIMEOUT	 0
#define SOCKET_SHUTDOWN_ERROR	-1
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
#define SOCKET_CREATE_ERROR	-1
#define SOCKET_BIND_ERROR		-1
#define SOCKET_LISTEN_ERROR	-1
#define SOCKET_ACCEPT_ERROR	-1
#define SOCKET_CONNECT_ERROR	-1
#define SOCKET_RECV_ERROR		-1
#define SOCKET_SEND_ERROR		-1
#define SOCKET_RECVFROM_ERROR	-1
#define SOCKET_SENDTO_ERROR	-1
#define SOCKET_CLOSE_ERROR		-1
#define SOCKET_SELECT_ERROR	-1
#define SOCKET_SELECT_TIMEOUT	0
#define SOCKET_SHUTDOWN_ERROR	-1
#define SOCKET_SHUTDOWN_READ	SHUT_RD
#define SOCKET_SHUTDOWN_WRITE	SHUT_WR
#define SOCKET_SHUTDOWN_BOTH	SHUT_RDWR
#endif

#if defined WIN32
#define SOCKET_CREATE_ERROR	INVALID_SOCKET
#define SOCKET_BIND_ERROR		SOCKET_ERROR
#define SOCKET_LISTEN_ERROR	SOCKET_ERROR
#define SOCKET_ACCEPT_ERROR	SOCKET_ERROR
#define SOCKET_CONNECT_ERROR	SOCKET_ERROR
#define SOCKET_RECV_ERROR		SOCKET_ERROR
#define SOCKET_SEND_ERROR		SOCKET_ERROR
#define SOCKET_RECVFROM_ERROR	SOCKET_ERROR
#define SOCKET_SENDTO_ERROR	SOCKET_ERROR
#define SOCKET_CLOSE_ERROR		SOCKET_ERROR
#define SOCKET_SELECT_ERROR	SOCKET_ERROR
#define SOCKET_SHUTDOWN_ERROR	SOCKET_ERROR
#define SOCKET_SELECT_TIMEOUT	0
#ifndef SD_RECEIVE
#define SD_RECEIVE      0x00
#define SD_SEND         0x01
#define SD_BOTH         0x02
#endif
#define SOCKET_SHUTDOWN_READ	SD_RECEIVE
#define SOCKET_SHUTDOWN_WRITE	SD_SEND
#define SOCKET_SHUTDOWN_BOTH	SD_BOTH
#endif


/* socket data types for various platforms */

#if defined VMS	
typedef int 					xos_socket_descriptor_t;
typedef unsigned short		xos_socket_port_t;
typedef int						xos_socket_address_size_t;
#endif

#if defined DEC_UNIX
typedef int		xos_socket_descriptor_t;
typedef unsigned short		xos_socket_port_t;	
typedef int					xos_socket_address_size_t;	
#endif

#if defined IRIX || defined LINUX
typedef int						xos_socket_descriptor_t;
typedef unsigned short		xos_socket_port_t;	
typedef int						xos_socket_address_size_t;	
#endif

#if defined WIN32
typedef SOCKET					xos_socket_descriptor_t;
typedef unsigned short		xos_socket_port_t;
typedef int						xos_socket_address_size_t;
#endif

/****************************************************************
	The following constants are used in the socket code.
****************************************************************/ 


#define SOCKET_DEFAULT_QUEUE_LENGTH 5


/****************************************************************
	The following enumeration constant is used to distinguish
	client and server processes.
****************************************************************/ 

typedef enum  		
	{ 
	SP_CLIENT, 
	SP_SERVER 
	} xos_socket_process_t;


/****************************************************************
	The following typdef defines the xos_socket_address_t abstract 
	data type.  The routines in socket_address.c operate on an 
	instance of this data type, passed by reference.  Since the
	data type is simply a renaming of the sockaddr_in structure,
	instances of this type may be safely cast to sockaddr_in or
	sockaddr as necesseary.
****************************************************************/ 

typedef struct sockaddr_in			xos_socket_address_t;


/****************************************************************
	The following typdef defines the tcp_socket_t abstract data type.
	The socket routines in tcp_socket.c operate on an instance of 
	this data type, passed by reference.
****************************************************************/ 

typedef struct
	{
	/* general information */
	xos_socket_process_t	process;
	size_t					queueLength;
	xos_boolean_t			socketStructValid;
	xos_boolean_t			serverListening;
	xos_boolean_t			connectionActive;
	xos_boolean_t			connectionGood;
	
	xos_boolean_t        blockOnRead;
	struct timeval       readTimeout;	
	
	/* server information */
	xos_socket_descriptor_t		serverDescriptor;
	xos_socket_address_t			serverAddress;
	xos_socket_address_size_t	serverAddressSize;		
	xos_boolean_t					serverAddressValid;
	
	/* client information */
	xos_socket_descriptor_t		clientDescriptor;
	xos_socket_address_t			clientAddress;
	xos_socket_address_size_t	clientAddressSize;
	xos_boolean_t					clientAddressValid;
	
	/* mutex information */
	xos_mutex_t		readMutex;
	xos_mutex_t		writeMutex;

	} xos_socket_t;


/****************************************************************
	The following prototypes declare the socket functions defined 
	in xos_socket.c.
****************************************************************/ 

void xos_socket_set_print_error_flag(int print_or_not);

xos_result_t xos_socket_create_server
	( 
	xos_socket_t*		socket, 
	xos_socket_port_t socketPort 
	);
	
xos_result_t xos_socket_create_client		
	( 
	xos_socket_t* 	socket 
	);
	
xos_result_t xos_socket_start_listening
	( 
	xos_socket_t* 	socket 
	);
	
xos_result_t xos_socket_accept_connection( xos_socket_t* serverSocket,
														 xos_socket_t* newClientSocket );

	
xos_result_t xos_socket_make_connection
	( 
	xos_socket_t*						socket, 
	const xos_socket_address_t*	address
	);

xos_result_t xos_socket_read
	( 
	xos_socket_t*	socket, 
	char* 			buffer, 
	int 				numBytes
	);
	
xos_result_t xos_socket_read_any_length
	( xos_socket_t*    socket,
	 char*          buffer,
	 int            numBytes,
	 int*           numBytesReceived
	 );

xos_result_t xos_socket_read_line
	( xos_socket_t*    socket,
	 char*          buffer,
	 int            numBytes,
	 int*           numBytesReceived
	 );

xos_result_t xos_socket_write
	( 
	xos_socket_t* 	socket, 
	const char* 	buffer,
	int 				numBytes
	);

xos_result_t xos_udp_create_client
	( 
	xos_socket_t*		socket, 
	const char* server,
	xos_socket_port_t socketPort 
	);

xos_result_t xos_udp_write
	( 
	xos_socket_t* 	socket, 
	const char* 	buffer,
	int 				numBytes
	);

xos_result_t xos_socket_disconnect
	( 
	xos_socket_t* 	socket
	);
	
xos_result_t xos_socket_destroy
	( 
	xos_socket_t* 	socket 
	);
	
xos_result_t xos_socket_print
	( 
	const xos_socket_t* socket
	);

xos_socket_port_t xos_socket_get_local_port
	(
	xos_socket_t* socket
	);

xos_result_t xos_socket_readable
	(
	xos_socket_t*	socket,
	xos_boolean_t			*readable
	);
	
xos_wait_result_t xos_socket_wait_until_readable
	(
	xos_socket_t*	socket,
	xos_time_t				timeoutMilliseconds
	);

xos_result_t xos_socket_address_init
	(
	xos_socket_address_t* address
	);
	
xos_result_t xos_socket_address_set_port
	( 
	xos_socket_address_t* address,
	xos_socket_port_t 		port
	);
	
xos_socket_port_t xos_socket_address_get_port
	( 
	const xos_socket_address_t* address 
	);

xos_result_t xos_socket_address_get_ip
	( 
	const xos_socket_address_t*	address,	 
	byte*									ipArray			
	);
	
xos_result_t xos_socket_address_set_ip
	( 
	xos_socket_address_t*	address,	 
	const byte*					ipArray
	);
	
xos_result_t xos_socket_address_set_ip_by_name
	( 
	xos_socket_address_t*	address, 
	const char*					hostname 
	);

xos_result_t xos_socket_get_peer_name( xos_socket_t * socket, xos_socket_address_t *peerAddress );

xos_result_t xos_socket_compare_address	( const xos_socket_address_t*	address1,
														  const xos_socket_address_t*	address2 );
	
xos_result_t xos_socket_address_print
	( 
	const xos_socket_address_t* socket 
	);

xos_result_t xos_socket_set_block_on_write( xos_socket_t * socket ,
														  xos_boolean_t blockOnWrite );

xos_result_t xos_socket_set_read_timeout	( xos_socket_t*	socket,
														  xos_time_t		timeoutMilliseconds );

xos_result_t xos_initialize_dcs_message ( dcs_message_t *dcsMessage,
														xos_size_t initialTextSize,
														xos_size_t initialBinarySize );

xos_result_t xos_destroy_dcs_message( dcs_message_t * dcsMessage );
xos_result_t xos_adjust_dcs_message( dcs_message_t * dcsMessage, int textSize, int binarySize );

xos_result_t xos_receive_dcs_message( xos_socket_t * socket,
												  dcs_message_t *dcsMessage );

xos_result_t xos_send_dcs_text_message ( xos_socket_t  * socket, 
													  const char *   textMessage );

xos_result_t xos_send_dcs_message ( xos_socket_t  * socket, 
												const char * textMessage,
												const char * binaryMessage,
												long         binarySize );

xos_result_t xos_socket_library_startup ( void );
xos_result_t xos_socket_library_cleanup ( void );

xos_result_t xos_socket_set_send_buffer_size (xos_socket_t *socket,
															 int * bufferSize);

#if defined WIN32	/* declare WIN32 specific functions */

typedef struct
	{
	int   WSAErrorCode;
	char* WSAErrorString;
	}
	WSAErrorTableEntry;



/****************************************************************
	The WSAErrorTableEntry structure is used in building a table 
	of error codes and strings for Win32 socket error handling.  
	The WSAPerror function is used to simulate the UNIX perror()
	function for Win32 platforms.
****************************************************************/ 

void WSAPerror
	( 
	int			errorValue, 
	const char*	commentString 
	);

#endif

#ifdef __cplusplus
}
#endif

		
#endif
