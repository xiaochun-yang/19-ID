#ifndef __log_console_handler_h__
#define __log_console_handler_h__
#include "log_common.h"
#include "log_level.h"
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * A Handler object takes log messages from a Logger and exports them.
 * It might for example, write them to a console or write them to a file,
 * or send them to a network logging service, or forward them to an OS log,
 * or whatever.
 *
 * A Handler can be disabled by doing a setLevel(Level.OFF) and can be
 * re-enabled by doing a setLevel with an appropriate level.
 *
 * Handler classes typically use LogManager properties to set default
 * values for the Handler's Filter, Formatter, and Level. See the specific
 * documentation for each concrete Handler class.
 *
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_handler_t from the log_console_handler_new() or
 * log_console_handler_init() methods here is deleted by
 * the log_handler_destroy() or log_handler_free() method.
 *
 *********************************************************/
void log_console_handler_init(log_handler_t* self, FILE* stream);
log_handler_t* log_console_handler_new(FILE* stream);


/*********************************************************
 *
 * Object methods (requires a log_handler_t pointer).
 *
 *********************************************************/


#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_console_handler_h__ */

