#ifndef __log_record_h__
#define __log_record_h__


#include "xos.h"
#include "log_common.h"
#include "xos_hash.h"
#include "log_level.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


#define THREADID_FIELD "threadId"
#define SEQUENCE_FIELD "sequence"
#define CLASS_FIELD "class"
#define METHOD_FIELD "method"
#define MESSAGE_FIELD "message"
#define MILLIS_FIELD "millis"
#define LOGGER_FIELD "logger"
#define LEVEL_FIELD "level"

#define DATE_FIELD "date"
#define TIME_FIELD "time"
#define LINE_FIELD "line"
#define FILE_FIELD "file"
#define PROCESSID_FIELD "processId"


/*********************************************************
 *
 * LogRecord objects are used to pass logging requests between the
 * logging framework and individual log Handlers.
 *
 * When a LogRecord is passed into the logging framework it logically
 * belongs to the framework and should no longer be used or updated
 * by the client application.
 *
 * Note that if the client application has not specified an explicit
 * source method name and source class name, then the LogRecord class
 * will infer them automatically when they are first accessed (due to
 * a call on getSourceMethodName or getSourceClassName) by analyzing
 * the call stack. Therefore, if a logging Handler wants to pass off
 * a LogRecord to another thread, or to transmit it over RMI, and if
 * it wishes to subsequently obtain method name or class name information
 * it should call one of getSourceClassName or getSourceMethodName to force
 * the values to be filled in.
 *
 * Serialization notes:
 *
 * The LogRecord class is serializable.
 * Because objects in the parameters array may not be serializable, during
 * serialization all objects in the parameters array are written as the
 * corresponding Strings (using Object.toString).
 * The ResourceBundle is not transmitted as part of the serialized form,
 * but the resource bundle name is, and the recipient object's readObject
 * method will attempt to locate a suitable resource bundle.
 *
 *********************************************************/
struct __log_record;
typedef struct __log_record log_record_t;

/*********************************************************
 *
 * new and free
 *
 *********************************************************/
log_record_t* log_record_new(log_level_t* level, const char* msg);
log_record_t* log_record_new_va(log_level_t* level, const char* format, va_list ap);
void log_record_free(log_record_t* self);

/*********************************************************
 *
 * init and destroy
 *
 *********************************************************/
void log_record_init(log_record_t* record, log_level_t* level, const char* msg);
void log_record_init_va(log_record_t* record, log_level_t* level, const char* format, va_list ap);
void log_record_destroy(log_record_t* record);

/*********************************************************
 *
 * Object methods (requires a log_record_t pointer).
 *
 *********************************************************/


const char* log_record_get_logger_name(const log_record_t* self);
void log_record_set_logger_name(log_record_t* self,
                            const char* name);

log_level_t* log_record_get_level(const log_record_t* self);
void log_record_set_level(log_record_t* self,
                            log_level_t* level);
void log_record_set_level_str(log_record_t* self,
                            const char* level);

long log_record_get_sequence_number(const log_record_t* self);
void log_record_set_sequence_number(log_record_t* self,
                            long sequence_number);

const char* log_record_get_source_class_name(const log_record_t* self);
void log_record_set_source_class_name(log_record_t* self,
                            const char* name);

const char* log_record_get_source_method_name(const log_record_t* self);
void log_record_set_source_method_name(log_record_t* self,
                            const char* name);
int log_record_get_message_size(const log_record_t* self);

const char* log_record_get_message(const log_record_t* self);
void log_record_set_message(log_record_t* self,
                            const char* msg);

const xos_hash_t* log_record_get_parameters(const log_record_t* self);
void log_record_add_patameter(log_record_t* self,
                            const char* name, const char* value);

int log_record_get_thread_id(const log_record_t* self);
void log_record_set_thread_id(log_record_t* self, int id);

int log_record_get_process_id(const log_record_t* self);
void log_record_set_process_id(log_record_t* self, int id);

time_t log_record_get_millis(const log_record_t* self);
void log_record_set_millis(log_record_t* self, time_t millis);


const char* log_record_get_file(const log_record_t* self);
void log_record_set_file(log_record_t* self, const char* file);

int log_record_get_line(const log_record_t* self);
void log_record_set_line(log_record_t* self, int line);

const char* log_record_get_date(const log_record_t* self);
void log_record_set_date(log_record_t* self, const char* date);

const char* log_record_get_time(const log_record_t* self);
void log_record_set_time(log_record_t* self, const char* time);


#ifdef __cplusplus
}
#endif /* _cplusplus */

#endif /* __log_record_h__*/

