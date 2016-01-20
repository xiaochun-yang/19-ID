#include <stdio.h>
#include "logging.h"


/*********************************************************
 *
 * Convenient method for creating a log handler from a type
 *
 *********************************************************/
log_handler_t* g_create_log_handler(const char* type)
{
	if (!type)
		return NULL;

	if (strcmp(type, STDOUT_HANDLER) == 0)
		return log_console_handler_new(stdout);
	else if (strcmp(type, STDOUT_HANDLER) == 0)
		return log_console_handler_new(stderr);
	else if (strcmp(type, FILE_HANDLER) == 0)
		;
//		return log_file_handler_new();

	return NULL;
}



/*********************************************************
 *
 * Convenient method for creating a log handler that will 
 * send the logs to stdout
 *
 *********************************************************/
log_handler_t* g_create_log_stdout_handler()
{

	return log_console_handler_new(stdout);

}

/*********************************************************
 *
 * Convenient method for creating a log handler that will 
 * send the logs to stderr
 *
 *********************************************************/
log_handler_t* g_create_log_stderr_handler()
{

	return log_console_handler_new(stderr);

}

/*********************************************************
 *
 * Creates a file handler
 * @param pattern File name, which may include wild cards defined above.
 * @param is_append Open the file in overwrite or append mode
 * @param file_size_limit Maximum size of the file in bytes. If using a single file
 *                        mode, the current file will be renamed to filename.bak
 *						  and a new file will be open with the same name
 *						  for the subsequent logs.
 * @param num_rotating_files If greater than 1, file names will be generated with rotating
 *						  numbers from 0 to num_rotating_files. When the
 *						  current file reaches the file_size_limit, a new file will be
 *						  opened with the rotating file number incremented by 1 until
 *						  the number reaches num_rotating_files, then it goes back to 0.
 *
 *********************************************************/
log_handler_t* g_create_log_file_handler(
                        const char*  pattern,
                        BOOL is_append,
                        int file_size_limit,
                        int num_rotating_files)
{
	return log_file_handler_new(pattern, is_append, file_size_limit, num_rotating_files);

}

log_handler_t* g_create_log_syslog_handler(
			const char* appName,
			int syslog_facility)
{
	return log_syslog_handler_new(appName, syslog_facility);
}


