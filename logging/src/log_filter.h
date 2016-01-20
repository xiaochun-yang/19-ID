#ifndef __log_filter_h__
#define __log_filter_h__
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * A Filter can be used to provide fine grain control over what is logged,
 * beyond the control provided by log levels.
 *
 * Each Logger and each Handler can have a filter associated with it.
 * The Logger or Handler will call the isLoggable method to check if a
 * given LogRecord should be published. If isLoggable returns false,
 * the LogRecord will be discarded.
 *
 *********************************************************/


/*********************************************************
 *
 * new log_filter_t data structure
 *
 *********************************************************/

struct __log_filter
{
	/* private members */
	void* data_;
	void (*data_free_)(void* d);

	/** public members */
	BOOL (*is_loggable)(log_filter_t* self, log_record_t* record);

};


#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_filter_h__ */

