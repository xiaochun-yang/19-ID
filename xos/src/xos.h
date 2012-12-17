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

/**
 * @file xos.h
 *                 
 * This header file is included by xos.c and any source files
 * that use xos services.  It contains preprocessor directives
 * necessary for compiling with these header files.
 *  
 * @author           Timothy M. McPhillips, SSRL.
 * @date    		February 25, 1998 by TMM.
 */

#ifndef XOS_H
#define XOS_H

#ifdef __cplusplus
extern "C" {
#endif

/****************************************************************
   The following directives include the appropriate system 
   dependent include files needed for the xos library.
****************************************************************/

#ifdef VMS  /* include files for DEC VMS platforms */
#include <unistd.h>
#include "multinet_root:[multinet.include.sys]types.h"
#include "multinet_root:[multinet.include.sys]socket.h"
#include "multinet_root:[multinet.include.sys]time.h"
#include "multinet_root:[multinet.include.netinet]in.h"
#include "multinet_root:[multinet.include]netdb.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <cma.h>
#include "SYS$COMMON:[000000.DECC$LIB.REFERENCE.SYS$STARLET_C]PTHREAD.H"
#include <starlet.h>
#include <descrip.h>
#include <ssdef.h>
#include <lib$routines.h>
#include <fcntl.h>
#include <psldef.h>
#include <secdef.h>
#include <fab.h>
#include <xabprodef.h>
#include <iodef.h>
#endif

#if defined DEC_UNIX   /* include files for Digital UNIX */
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/param.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
/*extern int  getdtablesize __((void));*/
#include <netdb.h>
#include <fcntl.h>
#include <strings.h>
#include <pthread.h>
#include <stdarg.h>
#include <sys/mman.h>
#include <mqueue.h>
#endif

#if defined IRIX  /* include files for SGI IRIX */
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/param.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
/*extern int  getdtablesize __((void));*/
#include <netdb.h>
#include <fcntl.h>
#include <strings.h>
#include <pthread.h>
#include <stdarg.h>
#include <sys/mman.h>
#include <mqueue.h>
#include <netinet/in.h>
#endif

#if defined LINUX /* include files for LINUX */
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/param.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <netdb.h>
#include <fcntl.h>
#include <string.h>
#include <strings.h>
#include <pthread.h>
#include <stdarg.h>
#include <sys/mman.h>
#include <netinet/in.h>
#include <signal.h>
#include <values.h>
#endif

#if defined WIN32      /* include files for WIN32 platforms */
#include <windows.h>
#include <windowsx.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <winsock.h>
#include <process.h>
#include <time.h>
#include <io.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#endif

#if defined DEC_UNIX || defined IRIX || defined LINUX
#define PTHREAD
#endif

#ifndef XOS_PRODUCTION_CODE
#	include <assert.h>
#else
#	define assert(EX) (void)0
#endif


/****************************************************************
   The data types for the arguments and return values of xos
   routines vary with operating system. The following type 
   definitions map the various system dependent types to the 
   types required for each system.
****************************************************************/ 

#ifdef VMS
typedef unsigned char		byte;
typedef unsigned int       xos_index_t;
typedef unsigned int			xos_size_t;
typedef int                xos_boolean_t;
typedef unsigned char      xos_byte_t;
typedef int                xos_iterator_t;	
typedef unsigned int 		xos_time_t;
#define XOS_ITERATOR_BEGIN -1
#define XOS_ITERATOR_END   -2
#define ERRNO              0
#define strerror(e)        ""
#define XOS_MESSAGE_BASE   1024
#define PTHREAD_NULL_ATTR	cma_c_null
#endif

#if defined DEC_UNIX
typedef unsigned char		byte;
typedef unsigned int       xos_index_t;
typedef unsigned int			xos_size_t;
typedef int                xos_boolean_t;
typedef unsigned char      xos_byte_t;
typedef unsigned int       xos_size_t;
typedef int                xos_iterator_t;	
typedef unsigned int 		xos_time_t;
#define XOS_ITERATOR_BEGIN -1
#define XOS_ITERATOR_END   -2
#define ERRNO              errno;
#define XOS_MESSAGE_BASE   1024
#define PTHREAD_NULL_ATTR	NULL
#endif

#if defined IRIX || defined LINUX
typedef unsigned char		byte;
typedef unsigned int       xos_index_t;
typedef unsigned int			xos_size_t;
typedef int                xos_boolean_t;
typedef unsigned char      xos_byte_t;
typedef int                xos_iterator_t;	
typedef long			 		xos_time_t;
#define XOS_ITERATOR_BEGIN -1
#define XOS_ITERATOR_END   -2
#define ERRNO              errno;
#define XOS_MESSAGE_BASE   1024
#define PTHREAD_NULL_ATTR	NULL
#define MAP_FILE				0
#endif

#if defined WIN32
typedef unsigned int       xos_index_t;
typedef unsigned int			xos_size_t;
typedef int                xos_boolean_t;
typedef unsigned char      xos_byte_t;
typedef unsigned int       xos_size_t;
typedef int                xos_iterator_t;
typedef DWORD 					xos_time_t;
#define XOS_ITERATOR_BEGIN -1
#define XOS_ITERATOR_END   -2
#define ERRNO              GetLastError();
#define strerror(e)        "Last error = "
#define XOS_MESSAGE_BASE   WM_USER + 1024
#endif

#define TRUE   1
#define FALSE  0

#define PRINT_ERROR( s )   fprintf( stderr, s"\n" );



/* type definition return value from most xos functions */
typedef enum {
   XOS_SUCCESS = 0,
   XOS_FAILURE = 1
   } xos_result_t;

/* type definition return value from wait functions */
typedef enum {
   XOS_WAIT_SUCCESS  = 0,
   XOS_WAIT_FAILURE  = 1,
   XOS_WAIT_TIMEOUT  = 2
   } xos_wait_result_t;

typedef enum {
   XOS_ACCESS_READ      = 0,
   XOS_ACCESS_READWRITE = 1
   } xos_access_t;

typedef enum {
   XOS_OPEN_EXISTING = 0,
   XOS_OPEN_NEW      = 1
   } xos_open_mode_t;


/****************************************************************
                        mutexes
  
****************************************************************/

/* type definitions for mutexes on each platform */

#ifdef WIN32

	/* the mutex data type */
	typedef struct
  		{  
   	HANDLE                  handle;
   	xos_boolean_t           isValid;
   	} xos_mutex_t;

#elif defined PTHREAD

	/* the mutex data type */
	typedef struct
   	{  
   	pthread_mutex_t			handle;
   	xos_boolean_t           isValid;
   	} xos_mutex_t;

#endif


xos_result_t xos_mutex_create
   ( 
   xos_mutex_t    *mutex
   );

xos_result_t xos_mutex_lock
   (
   xos_mutex_t    *mutex
   );

xos_result_t xos_mutex_trylock
   (
   xos_mutex_t    *mutex
   );

xos_result_t xos_mutex_unlock
   (
   xos_mutex_t    *mutex
   );

xos_result_t xos_mutex_close
   (
   xos_mutex_t    *mutex
   );


/****************************************************************
                        semaphores
  
****************************************************************/

/* type definitions for semaphores on each platform */

#ifdef WIN32

	/* maximum value for semaphores under Win32 */
#	define XOS_SEMAPHORE_MAX_VALUE 32768

	/* type for storing semaphore values */
	typedef unsigned int xos_semaphore_value_t;

	/* the semaphore data type */
	typedef struct
  		{  
   	HANDLE                  handle;
   	xos_boolean_t           isValid;
   	} xos_semaphore_t;

#elif defined PTHREAD

	/* type for storing semaphore values */
	typedef unsigned int xos_semaphore_value_t;

	/* the semaphore data type */
	typedef struct
   	{  
   	xos_semaphore_value_t	value;
		xos_mutex_t					mutex;
		pthread_cond_t				condition;
   	xos_boolean_t           isValid;
   	} xos_semaphore_t;

#endif


xos_result_t xos_semaphore_create
   ( 
   xos_semaphore_t         *semaphore,
   xos_semaphore_value_t   initialValue
   );

xos_wait_result_t xos_semaphore_wait
   (
   xos_semaphore_t   *semaphore,
   xos_time_t        timeout
   );

xos_result_t xos_semaphore_post
   (
   xos_semaphore_t   *semaphore
   );

xos_result_t xos_semaphore_close
   (
   xos_semaphore_t   *semaphore
   );


/****************************************************************
                        events
  For manual reset event, it is almost like semaphore,
  the value is 0 or 1. Value is only change by Set/Reset.

  For automatic event, it is like a condition variable.
****************************************************************/

/* type definitions for events on each platform */

/* type for storing event values */
#ifdef WIN32

	/* the event data type */
	typedef struct
	{  
	   	HANDLE                  handle;
   		xos_boolean_t           isValid;
   	} xos_event_t;

#elif defined PTHREAD

	/* the event data type */
	typedef struct
   	{  
	   	xos_boolean_t volatile      value;
		xos_mutex_t					mutex;
		pthread_cond_t				condition;
   		xos_boolean_t               isValid;
        xos_boolean_t               isManualReset;
   	} xos_event_t;

#endif


xos_result_t xos_event_create
   ( 
   xos_event_t         *event,
   xos_boolean_t       manualReset,
   xos_boolean_t       initialstate
   );

xos_wait_result_t xos_event_wait
   (
   xos_event_t   *event,
   xos_time_t    timeout
   );

xos_result_t xos_event_set
   (
   xos_event_t   *event
   );

xos_result_t xos_event_reset
   (
   xos_event_t   *event
   );


xos_result_t xos_event_close
   (
   xos_event_t   *event
   );





/****************************************************************
                        thread messages
  
****************************************************************/
/* type definitions for thread messages on each platform */

#ifdef WIN32

	/* type for the message id */
	typedef unsigned int xos_message_id_t;

#elif defined PTHREAD

	/* type for the message id */
	typedef unsigned int xos_message_id_t;

	typedef struct xos_thread_message_tag	
		{
		xos_message_id_t						messageId;
   	xos_semaphore_t   					*semaphore;
   	void              					*parameters;	
		struct xos_thread_message_tag		*nextMessage;	
		} xos_thread_message_t;

#endif

/****************************************************************
                        threads
  
****************************************************************/

/* type definitions for threads on each platform */

#ifdef WIN32
#pragma warning (disable : 4786)

	/* return type for thread routines */
#	define XOS_THREAD_ROUTINE 			DWORD WINAPI
#	define XOS_THREAD_ROUTINE_RETURN	return 0

	/* type for passing thread routine addresses */
	typedef unsigned long (__stdcall xos_thread_routine_t)(void*);

	/* the thread data type */
	typedef struct
  	 	{  
  	 	HANDLE         handle;
   	DWORD          id;
   	xos_boolean_t  isValid;
   	} xos_thread_t;

#elif defined PTHREAD

	/* return type for thread routines */
#	define XOS_THREAD_ROUTINE				void *
#	define XOS_THREAD_ROUTINE_RETURN	return NULL

	/* type for passing thread routine addresses */
	typedef void * (xos_thread_routine_t)(void*);

	/* the thread data type */
	typedef struct
 	  	{  
  	 	pthread_t      			handle;
   	xos_thread_message_t		*headMessage;
		xos_thread_message_t		*tailMessage;
		xos_semaphore_t			messageCount;
		xos_mutex_t					messageMutex;
   	xos_boolean_t  			isValid;
   	} xos_thread_t;

#endif


xos_result_t xos_thread_create
   ( 
   xos_thread_t         *thread,
   xos_thread_routine_t *thread_routine,
   void                 *thread_param 
   );

xos_wait_result_t xos_thread_wait
   (
   xos_thread_t   *thread,
   xos_time_t     timeout
   );

xos_result_t xos_thread_sleep
   (
   xos_time_t  sleepTime
   );

xos_result_t xos_thread_exit
   ( 
   void
   );

xos_result_t xos_thread_close
   (
   xos_thread_t   *thread
   );

unsigned int xos_thread_current_id( );

/****************************************************************
                        memory-mapped files
  
****************************************************************/

#ifdef WIN32

	/* the mapped file data type */
	typedef struct
  	 	{
  	 	void *         address;
  	 	xos_size_t		mappingSize;
  	 	xos_boolean_t  isValid;
  	 	} xos_mapped_file_t;

#elif defined DEC_UNIX || defined IRIX || defined LINUX

	/* the mapped file data type */
	typedef struct
  	 	{
  	 	void *         address;
  	 	xos_size_t		mappingSize;
   	xos_boolean_t  isValid;
   	} xos_mapped_file_t;

#elif defined VMS

	/* the vms memory range data type */
	typedef struct
		{
		unsigned long	start;
		unsigned long	end;
		} vms_memory_range_t;

	/* the mapped file data type */
	typedef struct
   	{
		vms_memory_range_t		mapRange;
		xos_size_t					mappingSize;
   	xos_boolean_t  			isValid;
   	} xos_mapped_file_t;

#endif


xos_result_t xos_mapped_file_open
   (
   xos_mapped_file_t *mappedFile,
   const char        *fileName,
   void              **mapAddress,
   xos_open_mode_t   openMode,
   xos_size_t        mappingSize
   );

xos_result_t xos_mapped_file_flush
   (
   xos_mapped_file_t *mappedFile
   );

xos_result_t xos_mapped_file_close
   (
   xos_mapped_file_t *mappedFile
   );

/****************************************************************
                        dcs message structure
****************************************************************/
#define DCS_HEADER_SIZE 26

typedef struct dcs_message
	{
	char header[DCS_HEADER_SIZE+1];

	//	char *textOutBuffer;
	//char *binaryOutBuffer;
	//long textOutSize;
	//long binaryOutSize;

	char *textInBuffer;
	char *binaryInBuffer;
	xos_size_t textInSize;
	xos_size_t binaryInSize;

	xos_size_t textBufferSize;
	xos_size_t binaryBufferSize;
	} dcs_message_t;


/****************************************************************
                        message queues
  
****************************************************************/
/* type definitions for message queues on each platform */

	typedef struct 
		{
		char *				startAddress;
		char *				endAddress;
		char *				firstMessage;
		char *				lastMessage;
		xos_semaphore_t	messageSlotsUsed;
		xos_semaphore_t	messageSlotsFree;
		xos_index_t			maxMessages;
		xos_size_t			messageSize;
		xos_mutex_t			writeMutex;
		xos_mutex_t			readMutex;
   	xos_boolean_t		isValid;
		} xos_message_queue_t;

xos_result_t xos_message_queue_create
	(
	xos_message_queue_t 	*messageQueue,
	xos_index_t				maxMessages,
	xos_size_t				messageSize
	);
	
xos_result_t xos_message_queue_write
	(
	xos_message_queue_t 	*messageQueue,
	const char *			buffer
	);
	
xos_result_t xos_message_queue_read
	(
	xos_message_queue_t 	*messageQueue,
	char *					buffer
	);
				
xos_result_t xos_message_queue_destroy
	(
	xos_message_queue_t 	*messageQueue
	);

xos_result_t xos_thread_message_send
   (
   xos_thread_t      *thread,
   xos_message_id_t  messageID,
   xos_semaphore_t   *semaphore,
   void              *parameters
   );

xos_result_t xos_thread_message_receive
   (
   xos_thread_t      *thread,
   xos_message_id_t  *messageID,
   xos_semaphore_t   **semaphore,
   void              **parameters
   );


/****************************************************************
                        clocks
****************************************************************/

#ifdef WIN32
#	define XOS_CLOCK_CONSTANT 1e3
#elif defined DEC_UNIX
#	define XOS_CLOCK_CONSTANT 1e6
#elif defined IRIX
#	define XOS_CLOCK_CONSTANT 1e6
#elif defined LINUX
#	define XOS_CLOCK_CONSTANT 1e6
#elif defined VMS
#	define XOS_CLOCK_CONSTANT 1e2
#endif

typedef struct
	{
	clock_t	startTicks;
	time_t	startSeconds;
	} xos_clock_t;

xos_result_t xos_clock_reset
	(
	xos_clock_t		* xosClock
	);

double xos_clock_get_cpu_time
	(
	xos_clock_t		* xosClock
	);

time_t xos_clock_get_real_time
	(
	xos_clock_t		* xosClock
	);

void xos_error(const char *fmt, ...);
void xos_error_exit(const char *fmt, ...);
void xos_error_thread_exit(const char *fmt, ...);
void xos_error_abort(const char *fmt, ...);

void xos_error_sys(const char *fmt, ...);
void xos_error_sys_exit(const char *fmt, ...);
void xos_error_sys_thread_exit(const char *fmt, ...);
void xos_error_sys_abort(const char *fmt, ...);


/**
 * @fn void xos_error_set_stream(FILE* s)
 * @brief A function to set error stream to a file stream.
 *
 * By default the error stream is stderr. An application can
 * to disable the error being printed out completely
 * by open a file stream to /dev/null.
 *
 * Example:
 *
 * @code

 void main(int argc, char** argv)
 {
     FILE* f = fopen("/tmp/errLog.txt", "w");

     xos_set_err_stream(f);

     xos_error("This will go to file\n");

     xos_reset_err_stream();

     xos_error_exit("This will go to stderr\n");

 }

 * @endcode
 * @param s File stream to be used as error stream.
 */
void xos_error_set_stream(FILE* s);

/**
 * @fn void xos_error_reset_stream()
 * @brief A function to reset error stream to a stderr.
 * @see xos_set_err_stream().
 */
void xos_error_reset_stream();

///////////////////////////////////////log//////////////////////
void xos_log(const char *fmt, ...);

char* my_fgets( char* buffer, int max_len, int fd );

////////////linux daemon mode//////////////////
#ifdef PTHREAD
void restart_in_daemon(int argc, char* argv[]);
void daemonize_save_output( const char* filename );
void daemonize( );
FILE* checkLockFile( const char* lockFileName );
void updateLockFile( FILE* handle ); //tell others you are ready
void releaseLockFile( FILE* handle );
#endif

#ifdef __cplusplus
}
#endif


#endif


