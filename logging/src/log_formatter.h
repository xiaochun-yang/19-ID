#ifndef __log_formatter_h__
#define __log_formatter_h__
#include "log_common.h"
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * A Formatter provides support for formatting LogRecords.
 *
 * Typically each logging Handler will have a Formatter associated with it.
 * The Formatter takes a LogRecord and converts it to a string.
 *
 * Some formatters (such as the XMLFormatter) need to wrap head and tail
 * strings around a set of formatted records. The getHeader and getTail
 * methods can be used to obtain these strings.
 *
 *********************************************************/
/*********************************************************
 *
 * new log_handler_t data structure
 *
 *********************************************************/
struct __log_formatter
{
	/* private members */
	void* data_;
	void (*data_free_)(void* d);

	/** public members */

	/* converst a log_record_t into a  simple format string. parse() can reconstruct the log_record_t from the returned string */
	const char* (*format)(log_formatter_t* self, log_record_t* record);
	const char* (*format_message)(log_formatter_t* self, log_record_t* record);
	const char* (*get_head)(log_formatter_t* self, log_handler_t* handler);
	const char* (*get_tail)(log_formatter_t* self, log_handler_t* handler);

	/* converts a string into a log_record_t. The string must conform to the simple format */
	xos_result_t (*parse)(log_formatter_t* self, const char* ret, log_record_t* record);
};




/*********************************************************
 *
 * new, free, init, destroy methods
 * There is no new or init methods for this base class.
 * An application that wishes to create an object of this 
 * class must use new() or init() of the subclass, although 
 * the object must be destroyed by calling log_formatter_destroy()
 * for the object on stack or log_formatter_free() on heap.
 * For example,
 * 
 * log_formatter_t formatter;
 * log_xxx_formatter_init(&formatter, ....);
 * log_formatter_destroy(&formatter);
 * 
 * or
 * 
 * log_formatter_t* formatter_ptr = log_xxx_formatter_new(...);
 * ...
 * log_formatter_free(formatter_ptr);
 *
 *********************************************************/
void log_formatter_destroy(log_formatter_t* self);
void log_formatter_free(log_formatter_t* self);

/*********************************************************
 *
 * Member functions
 *
 *********************************************************/
const char* log_formatter_format(log_formatter_t* self, log_record_t* record);
const char* log_formatter_format_message(log_formatter_t* self, log_record_t* record);
const char* log_formatter_get_head(log_formatter_t* self, log_handler_t* handler);
const char* log_formatter_get_tail(log_formatter_t* self, log_handler_t* handler);
xos_result_t log_formatter_parse(log_formatter_t* self, const char* ret,
						log_record_t* record);


#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_formatter_h__ */

