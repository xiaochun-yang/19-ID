#include "logging.h"

//variables
//GLOBAL
logger_t* gpDefaultLogger = NULL;
mode_t    gLogFileMode = 0;

//static
static log_manager_t* log_manager = NULL;
static log_handler_t* file_handler = NULL;
static log_handler_t* native_handler = NULL;
static log_handler_t* stdout_handler = NULL;
static log_formatter_t* trace_formatter = NULL;
static char file_pattern[256] = "logging_%g_%u.txt";
static int max_filesize = 31457280;	//30M, set to 0 if want to be unlimited
static int num_files = 3;
static BOOL append = FALSE;

void log_quick_set_file_mode( mode_t mod ) {
    gLogFileMode = mod;
}

void log_quick_set_file_pattern( const char* pattern )
{
    memset( file_pattern, 0, sizeof(file_pattern) );
    strncpy( file_pattern, pattern, sizeof(file_pattern) - 1 );
}
void log_quick_set_number_of_file( int num ) {
    if (num > 0) {
        num_files = num;
    }
}
void log_quick_set_file_size( int size ) {
    if (size >= 0) {
        max_filesize = size;
    }
}

void log_quick_open_no_stdout( )
{
	g_log_init( );
	
	log_manager = g_log_manager_new(NULL);
	
	trace_formatter = log_trace_formatter_new( );

	file_handler = g_create_log_file_handler(file_pattern, append, max_filesize, num_files);
	log_handler_set_level(file_handler, LOG_ALL);

	log_handler_set_formatter(file_handler, trace_formatter);

	gpDefaultLogger = g_get_logger(log_manager, "userApp", NULL, LOG_ALL);
	
	logger_add_handler(gpDefaultLogger, file_handler);
}

void log_quick_open_with_name( const char* logName )
{
	g_log_init( );
	
	log_manager = g_log_manager_new(NULL);
	
	trace_formatter = log_trace_formatter_new( );

	file_handler = g_create_log_file_handler(file_pattern, append, max_filesize, num_files);
	log_handler_set_level(file_handler, LOG_ALL);
	stdout_handler = g_create_log_stdout_handler();
	log_handler_set_level(stdout_handler, LOG_ALL);

	log_handler_set_formatter(file_handler, trace_formatter);
	log_handler_set_formatter(stdout_handler, trace_formatter);

	gpDefaultLogger = g_get_logger(log_manager, logName, NULL, LOG_ALL);
	
	logger_add_handler(gpDefaultLogger, file_handler);
	logger_add_handler(gpDefaultLogger, stdout_handler);
}

/* native will use EventLog on Windows and syslog in linux */
void log_quick_open_with_name_native( const char* logName )
{
	g_log_init( );
	
	log_manager = g_log_manager_new(NULL);
	
	trace_formatter = log_trace_formatter_new( );

	file_handler = g_create_log_file_handler(file_pattern, append, max_filesize, num_files);
	log_handler_set_level(file_handler, LOG_ALL);
#ifdef WIN32
    native_handler = log_native_handler_new( logName );
	log_handler_set_level(native_handler, LOG_WARNING);
#else
    native_handler = g_create_log_syslog_handler( logName, SYSLOG_LOCAL1 );
	log_handler_set_level(native_handler, LOG_ALL);
#endif
	stdout_handler = g_create_log_stdout_handler();
	log_handler_set_level(stdout_handler, LOG_ALL);

	log_handler_set_formatter(file_handler, trace_formatter);
	log_handler_set_formatter(native_handler, trace_formatter);
	log_handler_set_formatter(stdout_handler, trace_formatter);

	gpDefaultLogger = g_get_logger(log_manager, logName, NULL, LOG_ALL);
	
	logger_add_handler(gpDefaultLogger, file_handler);
	logger_add_handler(gpDefaultLogger, stdout_handler);
	logger_add_handler(gpDefaultLogger, native_handler);
}
void log_quick_open_stdout()
{
	g_log_init( );
	
	log_manager = g_log_manager_new(NULL);
	
	trace_formatter = log_trace_formatter_new( );

	stdout_handler = g_create_log_stdout_handler();
	log_handler_set_level(stdout_handler, LOG_ALL);
	log_handler_set_formatter(stdout_handler, trace_formatter);

	gpDefaultLogger = g_get_logger(log_manager, "UserApp", NULL, LOG_ALL);
	
	logger_add_handler(gpDefaultLogger, stdout_handler);
}


void log_quick_open( void )
{
    log_quick_open_with_name( "UserApp" );
}

void log_quick_close( void )
{
	//logger_remove_handler( gpDefaultLogger, file_handler ); it is OK not removing it.
	g_logger_free(log_manager, gpDefaultLogger);

    if (native_handler) {
	    log_handler_free(native_handler);
    }
    if (file_handler) {
	    log_handler_free(file_handler);
    }
    if (stdout_handler) {
	    log_handler_free(stdout_handler);
    }

	log_formatter_free(trace_formatter);

	g_log_manager_free( log_manager );

	g_log_clean_up();
}

/*************************************************
 *
 * Initialize syslog logger
 *
 *************************************************/
void log_quick_open_syslog()
{
	// Global variables are defined in log_quick.h
		
	// Initialize the logging
	g_log_init();

	log_manager = g_log_manager_new(NULL);

	// Get a logger from the manager. 
	gpDefaultLogger = g_get_logger(log_manager, "imperson", NULL, LOG_ALL);

	// trace formatter
	trace_formatter = log_trace_formatter_new( );

	// syslog handler
	// Log to LOG_LOCAL1 facility
	native_handler = g_create_log_syslog_handler("imperson", SYSLOG_LOCAL1);
	
	// Mask log level for this logHandler
	log_handler_set_level(native_handler, LOG_ALL);
	
	// Assign formatter for this handler
	log_handler_set_formatter(native_handler, trace_formatter);
	
	// Add handler to this logger
	logger_add_handler(gpDefaultLogger, native_handler);
	
	// Mask log level for the whole logger
	logger_set_level(gpDefaultLogger, LOG_ALL);
	
}

/*************************************************
 *
 * Cleanup logger
 * DO NOT add stdout handler to this func.
 * It is used by the impersonation server
 * where its stdout is redirected to socket
 * for sending HTTP response to client.
 *
 *************************************************/
void log_quick_close_syslog()
{
	// Global variables are defined in log_quick.h
	
	// Free memory in the correct order
	g_logger_free(log_manager, gpDefaultLogger);

	log_handler_free(native_handler);
	log_formatter_free(trace_formatter);

	// Uninitialize the logging system
	g_log_manager_free(log_manager);
	g_log_clean_up();
	
}

