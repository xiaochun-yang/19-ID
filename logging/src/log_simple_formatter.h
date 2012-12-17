#ifndef __log_simple_formatter_h__
#define __log_simple_formatter_h__

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 or 2 lines.
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_formatter_t from the log_simple_formatter_new() or
 * log_simple_formatter_init() methods here is deleted by
 * the log_formatter_destroy() or log_formatter_free() method.
 *
 *********************************************************/
log_formatter_t* log_simple_formatter_new();
void log_simple_formatter_init(log_formatter_t* self);

#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_simple_formatter_h__ */

