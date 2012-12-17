#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "xos.h"

//#define NO_LOG
#include "log_quick.h"



static xos_semaphore_t threadEnded;

static int volatile stopFlag = 0;

static void ctrl_c_handler( int value )
{
	stopFlag = 1;
}

/*********************************************************
 *
 *
 *
 *********************************************************/
static XOS_THREAD_ROUTINE thread_function( void* data )
{
	int i = 0;

	while (!stopFlag) {

		LOG_SEVERE1("THREAD This message level %s\n", 
				log_level_get_name(LOG_SEVERE));

		LOG_WARNING("THREAD This message level\n"); 

		LOG_INFO2("THREAD This message level %s i = %d\n", 
			log_level_get_name(LOG_INFO), i); 

		LOG_CONFIG1("THREAD This message level %s\n", 
				log_level_get_name(LOG_CONFIG)); 

		LOG_FINE1("THREAD This message level %s\n", 
				log_level_get_name(LOG_FINE)); 

		LOG_FINER1("THREAD This message level %s\n", 
			log_level_get_name(LOG_FINER)); 

		LOG_FINEST1("THREAD This message level %s\n", 
				log_level_get_name(LOG_FINEST)); 

		++i;
		//xos_thread_sleep( 2 );
	}
	LOG_INFO("THREAD EXIT" );

	xos_semaphore_post( &threadEnded );
	XOS_THREAD_ROUTINE_RETURN;
}

int test_quick_logger_main(int argc, char** argv)
{
	int i = 0;
	
	//threading
	xos_thread_t anotherThread;
	
	signal( SIGINT, ctrl_c_handler );

    xos_semaphore_create( &threadEnded, 0 );

	/************************************************************
	 *
	 * Initialize the logging
	 *
	 ************************************************************/
	LOG_QUICK_OPEN;


	/************************************************************
	 *
	 * Generate log messages
	 *
	 ************************************************************/

	//thread
	if (xos_thread_create( &anotherThread, thread_function, NULL ) != XOS_SUCCESS)
	{
		printf("thread creation failed\n");
		exit(1);
	}

	while (!stopFlag) {

		LOG_SEVERE1("This message level %s\n", 
				log_level_get_name(LOG_SEVERE));

		LOG_WARNING("This message level\n"); 

		LOG_INFO2("This message level %s i = %d\n", 
			log_level_get_name(LOG_INFO), i); 

		LOG_CONFIG1("This message level %s\n", 
				log_level_get_name(LOG_CONFIG)); 

		LOG_FINE1("This message level %s\n", 
				log_level_get_name(LOG_FINE)); 

		LOG_FINER1("This message level %s\n", 
			log_level_get_name(LOG_FINER)); 

		LOG_FINEST1("This message level %s\n", 
				log_level_get_name(LOG_FINEST)); 

		++i;
		//xos_thread_sleep( 2 );
	}


	LOG_INFO( "waiting the other thread to end" );
    if (xos_semaphore_wait( &threadEnded, 0) != XOS_SUCCESS)
	{
		LOG_WARNING("wait thread exit failed");
        printf("wait thread faile\n");
	}
	else
	{
		LOG_INFO( "end of waiting of the other thread" );
	}

    xos_semaphore_close( &threadEnded );


	xos_thread_close( &anotherThread );

	LOG_QUICK_CLOSE;

	return 0;
}

