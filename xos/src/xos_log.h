#ifndef __Include_XosLog_h__
#define __Include_XosLog_h__

/**
 * @file xos_log.h
 * Include file for logging utility functions. This is a simple version of a logging utility
 * which is more or less identical to the xos_error* functions. It is initialized with an 
 * opened file stream in xos_log_init(). xos_log() takes a variable number of arguments
 * like printf. Unlike xos_error* functions, xos_log() has no default output stream. 
 * If xos_log_init() is not called with a valid stream, the subsequent calls to xos_log()
 * will not generate any output.
 */

#include "xos.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @fn void xos_log_init(FILE* stream)
 * @brief Initialize logging resources including opening file streams.
 *
 * Called by an application to initialize logging.
 * There is only on log stream per application.
 * @param stream Log stream
 */
void xos_log_init(FILE* stream);

/**
 * @fn void xos_log_destroy()
 * @brief Clean up the logging resources
 *
 * Called an application before exiting to clean up the logging resources.
 */
void xos_log_destroy();

/**
 * @fn void xos_log(const char *fmt, ...)
 * @brief log information to the log stream. The function arguments are like printf.
 */
void xos_log(const char *fmt, ...);

/**
 * @fn FILE* xos_log_get_fd()
 * @brief Returns file pointer of logging output stream.
 * @return File pointer to the logging output stream.
 */
FILE* xos_log_get_fd();

#ifdef __cplusplus
}
#endif


#endif // __Include_XosLog_h__


