#ifndef __log_handler_h__
#define __log_handler_h__

#include "log_filter.h"
#include "log_level.h"
#include "log_formatter.h"

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

struct __log_handler
{
	/* protected members */
	void* 				data_;
	log_filter_t* 		filter;
	log_formatter_t* 	formatter;
	log_level_t* 		level;

	void (*close)(log_handler_t* self);
	void (*flush)(log_handler_t* self);
	void (*publish)(log_handler_t* self, log_record_t* record);
	void (*destroy)(log_handler_t* self);
};


/*********************************************************
 *
 * new, init, destroy, free methods
 * new and init are defined in the subclass. An application
 * should call init or new defined in the subclass to create
 * a log_handler_object. The object are deallocated by
 * log_handler_destroy() or log_handler_free() method
 * defined here. For example,
 *
 * log_handler_t handler;
 * log_xxx_handler_init(&handler, ...);
 * ...
 * log_handler_destroy(&handler);
 *
 * or
 *
 * log_handler_t* handler_ptr = log_xxx_handler_new(...);
 * ...
 * log_handler_free(handler_ptr);
 *
 *********************************************************/
void log_handler_destroy(log_handler_t* self);
void log_handler_free(log_handler_t* self);

/*********************************************************
 *
 * Object methods (requires a log_handler_t pointer).
 *
 *********************************************************/
void log_handler_close(log_handler_t* self);
void log_handler_flush(log_handler_t* self);
const char* log_handler_get_encoding(const log_handler_t* self);
log_filter_t* log_handler_get_filter(const log_handler_t* self);
log_formatter_t* log_handler_get_formatter(const log_handler_t* self);
log_level_t* log_handler_get_level(const log_handler_t* self);
BOOL log_handler_is_loggable(const log_handler_t* self, log_record_t* record);
void log_handler_publish(log_handler_t* self, log_record_t* record);
void log_handler_report_error(log_handler_t* self, const char* msg, int code);
void log_handler_set_encoding(log_handler_t* self, const char* encoding);
void log_handler_set_filter(log_handler_t* self, log_filter_t* filter);
void log_handler_set_formatter(log_handler_t* self, log_formatter_t* formatter);
void log_handler_set_level(log_handler_t* self, log_level_t* level);




#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_handler_h__ */

