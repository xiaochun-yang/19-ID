#ifndef __log_trace_formatter_h__
#define __log_trace_formatter_h__

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */

////copied and made some change from log_token_formatter.h

/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 line.
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_formatter_t from the log_trace_formatter_new() or
 * log_trace_formatter_init() methods here is deleted by
 * the log_formatter_destroy() or log_formatter_free() method.
 *
 *********************************************************/
log_formatter_t* log_trace_formatter_new( void );
void log_trace_formatter_init(log_formatter_t* self );

#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_trace_formatter_h__ */

