#ifndef __log_handler_factory_h__
#define __log_handler_factory_h__

//#include "log_handler.h"


#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */

typedef enum __log_handler_type
{
	LOG_CONSOLE_HANDLER,
	LOG_FILE_HANDLER,
	LOG_SOCKET_HANDLER,
	LOG_MEMORYMAP_HANDLER,
	LOG_UDP_HANDLER,
	LOG_HTTP_HANDLER,
	LOG_SYSLOG_HANDLER
} log_handler_type_t;

/*********************************************************
 *
 * Class methods
 *
 *********************************************************/
log_handler_t* g_create_log_stdout_handler();
log_handler_t* g_create_log_stderr_handler();

log_handler_t* g_create_log_file_handler(
                        const char*  pattern,
                        BOOL is_append,
                        int file_size_limit,
                        int num_rotating_files);


log_handler_t* g_create_log_syslog_handler(
			const char* appName,
			int syslog_facility);
#ifdef __cplusplus
}
#endif /* _cplusplus */

#endif /* __log_handler_factory_h__*/

