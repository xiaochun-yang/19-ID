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

int test_logger_main(int argc, char** argv)
{
	int forever = 1;
	int i = 0;

	log_manager_t* log_manager = NULL;
	logger_t* log_aa = NULL;
	log_handler_t* stdout_handler = NULL;
	log_handler_t* file_handler = NULL;
	log_handler_t* udp_handler = NULL;
	log_handler_t* another_udp_handler = NULL;
	log_formatter_t* simple_formatter = NULL;
	log_formatter_t* trace_formatter = NULL;
	
	char file_pattern[500];
	const char* output_dir;
	int max_size;
	int num_files;
#ifdef WIN32
	char* SLASH = "\\";
#else
	char* SLASH = "/";
#endif

	//threading
	xos_thread_t anotherThread;
	
	if (argc < 4) {
	
		printf("Usage: test <output_dir> <max_file_size> <num_files>\n");
		printf("\n");
		printf("Loops forever and sends log messages to stdout, udp and files.\n");
		printf("\n");
		printf("The program will send log output to files in the designated dir.\n");
		printf("Each file will not grow bigger than max_file_size in bytes.\n");
		printf("When the current log file reaches the max size, a new file,\n");
		printf("the subsequent log output will be put in a new file.\n");
		printf("Each file name has got a number appended to it.\n");
		printf("When the number of output files created has reached num_files\n");
		printf("the oldest file will be replaced\n");
		printf("\n");
		exit(0);
	
	}
	
	output_dir = argv[1];
	max_size = atoi(argv[2]);
	num_files = atoi(argv[3]);
	
	printf("max size = %d, num files = %d\n", max_size, num_files);
	

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

	// file handler
	sprintf(file_pattern, "%s%stest_file_%s.log.%s", output_dir, SLASH, "%g", "%u");
	printf("file pattern = %s\n", file_pattern);
	file_handler = g_create_log_file_handler(file_pattern, FALSE, max_size, num_files);

	if (!file_handler) {
		printf("Error: g_create_log_file_handler returns NULL");
		exit(1);
	}


	// udp handler
	udp_handler = log_udp_handler_new("blctlxx.slac.stanford.edu", 5002);

	if (!udp_handler) {
		printf("Error: log_udp_handler_new returns NULL");
		exit(1);
	}

	another_udp_handler = log_udp_handler_new("blctlxx.slac.stanford.edu", 5002);

	if (!another_udp_handler) {
		printf("Error: log_udp_handler_new returns NULL");
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
	log_handler_set_level(file_handler, LOG_ALL);
	log_handler_set_level(udp_handler, LOG_ALL);
	log_handler_set_level(another_udp_handler, LOG_SEVERE);

	/************************************************************
	 *
	 * Assign a formatter to the handler
	 *
	 ************************************************************/
	log_handler_set_formatter(stdout_handler, trace_formatter);
	log_handler_set_formatter(file_handler, trace_formatter);
	log_handler_set_formatter(udp_handler, trace_formatter);


	/************************************************************
	 *
	 * Add handlers to the logger
	 *
	 ************************************************************/
	logger_add_handler(log_aa, stdout_handler);
	logger_add_handler(log_aa, file_handler);
	logger_add_handler(log_aa, udp_handler);
	logger_add_handler(log_aa, another_udp_handler);


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
	log_handler_free(file_handler);
	log_handler_free(udp_handler);
	log_handler_free(another_udp_handler);

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

