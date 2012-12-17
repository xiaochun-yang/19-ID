#ifndef __log_syslog_handler_h__
#define __log_syslog_handler_h__
#include "log_common.h"
#include "log_level.h"
#include "log_record.h"

#define SYSLOG_LOCAL0 0
#define SYSLOG_LOCAL1 1
#define SYSLOG_LOCAL2 2
#define SYSLOG_LOCAL3 3
#define SYSLOG_LOCAL4 4
#define SYSLOG_LOCAL5 5
#define SYSLOG_LOCAL6 6
#define SYSLOG_LOCAL7 7
#define SYSLOG_USER 8


#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * syslog logging Handler.
 *
 * Writes message to the system message logger.  The
 * message is then written to the system console, log files, logged-in
 * users, or forwarded to other machines as appropriate.
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_handler_t from the log_console_handler_new() or
 * log_syslog_handler_init() methods here is deleted by
 * the log_handler_destroy() or log_handler_free() method.
 *
 *********************************************************/
void log_syslog_handler_init(log_handler_t* self, 
				const char* prefix_, 
				int opt_, 
				int facility_);

log_handler_t* log_syslog_handler_new(const char* appName,
				int syslog_facility);

#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_syslog_handler_h__ */

