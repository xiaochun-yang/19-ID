#ifndef __log_level_h__
#define __log_level_h__

#include "log_common.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * The Level class defines a set of standard logging levels that
 * can be used to control logging output. The logging Level objects
 * are ordered and are specified by ordered integers. Enabling logging
 * at a given level also enables logging at all higher levels.
 *
 * Clients should normally use the predefined Level constants
 * such as Level.SEVERE.
 *
 * The levels in descending order are:
 *
 * SEVERE (highest value)
 * WARNING
 * INFO
 * CONFIG
 * FINE
 * FINER
 * FINEST (lowest value)
 * In addition there is a level OFF that can be used to turn off
 * logging, and a level ALL that can be used to enable logging
 * of all messages.
 * It is possible for third parties to define additional logging
 * levels by subclassing Level. In such cases subclasses should
 * take care to chose unique integer level values and to ensure
 * that they maintain the Object uniqueness property across
 * serialization by defining a suitable readResolve method.
 *
 *
 *********************************************************/



/*********************************************************
 *
 * Class methods
 *
 *********************************************************/
void log_level_init();
void log_level_clean_up();
log_level_t* log_level_parse(const char* str);

/*********************************************************
 *
 * Object methods (requires a log_level_t pointer).
 *
 *********************************************************/
const char* log_level_get_name(log_level_t* self);
BOOL log_level_equals(log_level_t* self, log_level_t* obj);
const char* log_level_get_localized_name(log_level_t* self);
const char* log_level_get_resource_name(log_level_t* self);
int log_level_hash_code(log_level_t* self);
const char* log_level_to_string(log_level_t* self);
int log_level_get_int_value(log_level_t* self);

/*********************************************************
 *
 * Creates a log level
 * SEVERE (highest value)
 * WARNING
 * INFO
 * CONFIG
 * FINE
 * FINER
 * FINEST (lowest value)
 *********************************************************/

/* OFF is a special level that can be used to turn off logging. */
extern log_level_t* LOG_OFF;
/* SEVERE is a message level indicating a serious failure. */
extern log_level_t* LOG_SEVERE;
/* WARNING is a message level indicating a potential problem. */
extern log_level_t* LOG_WARNING;
/* CONFIG is a message level for static configuration messages.*/
extern log_level_t* LOG_CONFIG;
/* INFO is a message level for informational messages. */
extern log_level_t* LOG_INFO;
/* FINE is a message level providing tracing information. */
extern log_level_t* LOG_FINE;
/* FINER indicates a fairly detailed tracing message. */
extern log_level_t* LOG_FINER;
/* FINEST indicates a highly detailed tracing message. */
extern log_level_t* LOG_FINEST;
/* ALL indicates that all messages should be logged. */
extern log_level_t* LOG_ALL;




#ifdef __cplusplus
}
#endif /* _cplusplus */



#endif /* __log_level_h__*/
