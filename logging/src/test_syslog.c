#include <stdio.h>
#include <stdlib.h>
#include "xos.h"
#include "logging.h"

static xos_semaphore_t threadEnded;

/*********************************************************
 *
 *
 *
 *********************************************************/
static XOS_THREAD_ROUTINE thread_function( void* data )
{
	logger_t* pLogger = (logger_t*)data;

	int i = 0;

	while (i < 2000) {

		SEVERE1(pLogger, "THREAD This message level %s\n", 
				log_level_get_name(LOG_SEVERE));

		WARNING(pLogger, "THREAD This message level\n"); 

		INFO2(pLogger, "THREAD This message level %s i = %d\n", 
			log_level_get_name(LOG_INFO), i); 

		CONFIG1(pLogger, "THREAD This message level %s\n", 
				log_level_get_name(LOG_CONFIG)); 

		FINE1(pLogger, "THREAD This message level %s\n", 
				log_level_get_name(LOG_FINE)); 

		FINER1(pLogger, "THREAD This message level %s\n", 
			log_level_get_name(LOG_FINER)); 

		FINEST1(pLogger, "THREAD This message level %s\n", 
				log_level_get_name(LOG_FINEST)); 

		++i;
		xos_thread_sleep(500);
	}
	INFO(pLogger, "THREAD EXIT" );
    xos_semaphore_post( &threadEnded );
	XOS_THREAD_ROUTINE_RETURN;
}

int syslog_main(int argc, char** argv)
{
	int forever = 1;
	int i = 0;

	log_manager_t* log_manager = NULL;
	logger_t* log_aa = NULL;
	log_handler_t* stdout_handler = NULL;
	log_handler_t* syslog_handler = NULL;
	log_formatter_t* simple_formatter = NULL;
	log_formatter_t* trace_formatter = NULL;
	
	//threading
	xos_thread_t anotherThread;
		
	/************************************************************
	 *
	 * Initialize the logging
	 *
	 ************************************************************/
	g_log_init();

	/************************************************************
	 *
	 * Create a log manager from a config file
	 *
	 ************************************************************/
	log_manager = g_log_manager_new(NULL);

	/************************************************************
	 *
	 * Get a logger from the manager. 
	 *
	 ************************************************************/
	log_aa = g_get_logger(log_manager, "aa", NULL, LOG_ALL);

	/************************************************************
	 *
	 * Create Formatters
	 *
	 ************************************************************/

	// Simple formatter
	simple_formatter = log_simple_formatter_new();

	if (!simple_formatter) {
		printf("Error: failed to create simple formatter");
		return 1;
	}


	// trace formatter
	trace_formatter = log_trace_formatter_new( );

	if (!trace_formatter) {
		printf("Error: failed to create trace formatter");
		return 1;
	}



	/************************************************************
	 *
	 * Create Handlers
	 *
	 ************************************************************/

	// stdout handler
	stdout_handler = g_create_log_stdout_handler();
	if (!stdout_handler) {
		printf("Error: g_create_log_stdout_handler returns NULL");
		exit(1);
	}


	// udp handler
	syslog_handler = g_create_log_syslog_handler("LoggerTestApp", SYSLOG_LOCAL1);

	if (!syslog_handler) {
		printf("Error: log_syslog_handler_new returns NULL");
		exit(1);
	}

	/************************************************************
	 *
	 * Change log level of each handler
	 *
	 ************************************************************/
	// Default is LOG_INFO. 
	log_handler_set_level(stdout_handler, LOG_ALL);
	// Default is LOG_ALL
	log_handler_set_level(syslog_handler, LOG_ALL);

	/************************************************************
	 *
	 * Assign a formatter to the handler
	 *
	 ************************************************************/
	log_handler_set_formatter(stdout_handler, trace_formatter);
	log_handler_set_formatter(syslog_handler, trace_formatter);


	/************************************************************
	 *
	 * Add handlers to the logger
	 *
	 ************************************************************/
	logger_add_handler(log_aa, stdout_handler);
	logger_add_handler(log_aa, syslog_handler);


	/************************************************************
	 *
	 * Set Level
	 *
	 ************************************************************/
	logger_set_level(log_aa, LOG_ALL);
	

	/************************************************************
	 *
	 * Generate log messages
	 *
	 ************************************************************/
	
	xos_semaphore_create( &threadEnded, 0 );

	//thread

	if (xos_thread_create( &anotherThread, thread_function, log_aa ) != XOS_SUCCESS)
	{
		printf("thread creation failed\n");
		exit(1);
	}

	while (forever) {
	
		++i;

		SEVERE1(log_aa, "This message level %s\n", 
				log_level_get_name(LOG_SEVERE));

		WARNING(log_aa, "This message level\n"); 

		INFO2(log_aa, "This message level %s i = %d\n", 
			log_level_get_name(LOG_INFO), i); 

		CONFIG1(log_aa, "This message level %s\n", 
				log_level_get_name(LOG_CONFIG)); 

		FINE1(log_aa, "This message level %s\n", 
				log_level_get_name(LOG_FINE)); 

		FINER1(log_aa, "This message level %s\n", 
			log_level_get_name(LOG_FINER)); 

		FINEST1(log_aa, "This message level %s\n", 
				log_level_get_name(LOG_FINEST)); 

		if (i > 10000)
			i = 0;

		xos_thread_sleep(500);
	}


	INFO( log_aa, "before waiting thread to exit" );
    if (xos_semaphore_wait( &threadEnded, 0) != XOS_SUCCESS)
	{
		WARNING(log_aa, "wait thread exit failed");
        printf("wait thread faile\n");
	}
	INFO( log_aa, "end of waiting thread to exit" );

    xos_semaphore_close( &threadEnded );

    printf("before thread close\n");
	xos_thread_close( &anotherThread );


	/************************************************************
	 *
	 * Free memory in the correct order
	 *
	 ************************************************************/
	g_logger_free(log_manager, log_aa);

	log_handler_free(stdout_handler);
	log_handler_free(syslog_handler);

	log_formatter_free(simple_formatter);
	log_formatter_free(trace_formatter);

	/************************************************************
	 *
	 * Uninitialize the logging system
	 *
	 ************************************************************/
	g_log_manager_free( log_manager );
	g_log_clean_up();

	return 0;
}

