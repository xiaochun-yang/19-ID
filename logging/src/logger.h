#ifndef __logger_h__
#define __logger_h__

#ifdef LOG_OPTIMIZED

#define SEVERE(s, f) severe(s, f)
#define WARNING(s, f) warning(s, f)
#define INFO(s, f) info(s, f)
#define CONFIG(s, f) config(s, f)
#define FINE(s, f) fine(s, f)
#define FINER(s, f) finer(s, f)
#define FINEST(s, f) finest(s, f)

#define SEVERE1(s, f, a1) severe(s, f, a1)
#define WARNING1(s, f, a1) warning(s, f, a1)
#define INFO1(s, f, a1) info(s, f, a1)
#define CONFIG1(s, f, a1) config(s, f, a1)
#define FINE1(s, f, a1) fine(s, f, a1)
#define FINER1(s, f, a1) finer(s, f, a1)
#define FINEST1(s, f, a1) finest(s, f, a1)

#define SEVERE2(s, f, a1, a2) severe(s, f, a1, a2)
#define WARNING2(s, f, a1, a2) warning(s, f, a1, a2)
#define INFO2(s, f, a1, a2) info(s, f, a1, a2)
#define CONFIG2(s, f, a1, a2) config(s, f, a1, a2)
#define FINE2(s, f, a1, a2) fine(s, f, a1, a2)
#define FINER2(s, f, a1, a2) finer(s, f, a1, a2)
#define FINEST2(s, f, a1, a2) finest(s, f, a1, a2)

#define SEVERE3(s, f, a1, a2, a3) severe(s, f, a1, a2, a3)
#define WARNING3(s, f, a1, a2, a3) warning(s, f, a1, a2, a3)
#define INFO3(s, f, a1, a2, a3) info(s, f, a1, a2, a3)
#define CONFIG3(s, f, a1, a2, a3) config(s, f, a1, a2, a3)
#define FINE3(s, f, a1, a2, a3) fine(s, f, a1, a2, a3)
#define FINER3(s, f, a1, a2, a3) finer(s, f, a1, a2, a3)
#define FINEST3(s, f, a1, a2, a3) finest(s, f, a1, a2, a3)

#define SEVERE4(s, f, a1, a2, a3, a4) severe(s, f, a1, a2, a3, a4)
#define WARNING4(s, f, a1, a2, a3, a4) warning(s, f, a1, a2, a3, a4)
#define INFO4(s, f, a1, a2, a3, a4) info(s, f, a1, a2, a3, a4)
#define CONFIG4(s, f, a1, a2, a3, a4) config(s, f, a1, a2, a3, a4)
#define FINE4(s, f, a1, a2, a3, a4) fine(s, f, a1, a2, a3, a4)
#define FINER4(s, f, a1, a2, a3, a4) finer(s, f, a1, a2, a3, a4)
#define FINEST4(s, f, a1, a2, a3, a4) finest(s, f, a1, a2, a3, a4)

#define SEVERE5(s, f, a1, a2, a3, a4, a5) severe(s, f, a1, a2, a3, a4, a5)
#define WARNING5(s, f, a1, a2, a3, a4, a5) warning(s, f, a1, a2, a3, a4, a5)
#define INFO5(s, f, a1, a2, a3, a4, a5) info(s, f, a1, a2, a3, a4, a5)
#define CONFIG5(s, f, a1, a2, a3, a4, a5) config(s, f, a1, a2, a3, a4, a5)
#define FINE5(s, f, a1, a2, a3, a4, a5) fine(s, f, a1, a2, a3, a4, a5)
#define FINER5(s, f, a1, a2, a3, a4, a5) finer(s, f, a1, a2, a3, a4, a5)
#define FINEST5(s, f, a1, a2, a3, a4, a5) finest(s, f, a1, a2, a3, a4, a5)

#else

#define SEVERE(s, f) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)
#define WARNING(s, f) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)
#define INFO(s, f) info_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)
#define CONFIG(s, f) config_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)
#define FINE(s, f) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)
#define FINER(s, f) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)
#define FINEST(s, f) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f)

#define SEVERE1(s, f, a1) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)
#define WARNING1(s, f, a1) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)
#define INFO1(s, f, a1) info_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)
#define CONFIG1(s, f, a1) config_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)
#define FINE1(s, f, a1) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)
#define FINER1(s, f, a1) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)
#define FINEST1(s, f, a1) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1)

#define SEVERE2(s, f, a1, a2) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)
#define WARNING2(s, f, a1, a2) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)
#define INFO2(s, f, a1, a2) info_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)
#define CONFIG2(s, f, a1, a2) config_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)
#define FINE2(s, f, a1, a2) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)
#define FINER2(s, f, a1, a2) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)
#define FINEST2(s, f, a1, a2) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2)

#define SEVERE3(s, f, a1, a2, a3) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)
#define WARNING3(s, f, a1, a2, a3) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)
#define INFO3(s, f, a1, a2, a3) info_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)
#define CONFIG3(s, f, a1, a2, a3) config_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)
#define FINE3(s, f, a1, a2, a3) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)
#define FINER3(s, f, a1, a2, a3) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)
#define FINEST3(s, f, a1, a2, a3) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3)

#define SEVERE4(s, f, a1, a2, a3, a4) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)
#define WARNING4(s, f, a1, a2, a3, a4) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)
#define INFO4(s, f, a1, a2, a3, a4) info_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)
#define CONFIG4(s, f, a1, a2, a3, a4) config_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)
#define FINE4(s, f, a1, a2, a3, a4) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)
#define FINER4(s, f, a1, a2, a3, a4) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)
#define FINEST4(s, f, a1, a2, a3, a4) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4)

#define SEVERE5(s, f, a1, a2, a3, a4, a5) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)
#define WARNING5(s, f, a1, a2, a3, a4, a5) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)
#define INFO5(s, f, a1, a2, a3, a4, a5) info_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)
#define CONFIG5(s, f, a1, a2, a3, a4, a5) config_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)
#define FINE5(s, f, a1, a2, a3, a4, a5) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)
#define FINER5(s, f, a1, a2, a3, a4, a5) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)
#define FINEST5(s, f, a1, a2, a3, a4, a5) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, s, f, a1, a2, a3, a4, a5)

#endif

#include "xos.h"
//#include "log_common.h"
//#include "log_level.h"
//#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * A Logger object is used to log messages for a specific system or
 * application component. Loggers are normally named, using a hierarchical
 * dot-separated namespace. Logger names can be arbitrary strings, but they
 * should normally be based on the package name or class name of the logged
 * component, such as java.net or javax.swing. In additon it is possible to
 * create "anonymous" Loggers that are not stored in the Logger namespace.
 *
 * Logger objects may be obtained by calls on one of the getLogger factory
 * methods. These will either create a new Logger or return a suitable
 * existing Logger.
 *
 * Logging messages will be forwarded to registered Handler objects,
 * which can forward the messages to a variety of destinations, including
 * consoles, files, OS logs, etc.
 *
 * Each Logger keeps track of a "parent" Logger, which is its nearest existing
 * ancestor in the Logger namespace.
 *
 * Each Logger has a "Level" associated with it. This reflects a minimum Level
 * that this logger cares about. If a Logger's level is set to null, then its
 * effective level is inherited from its parent, which may in turn obtain it
 * recursively from its parent, and so on up the tree.
 *
 * The log level can be configured based on the properties from the logging
 * configuration file, as described in the description of the LogManager class.
 * However it may also be dynamically changed by calls on the Logger.setLevel
 * method. If a logger's level is changed the change may also affect child
 * loggers, since any child logger that has null as its level will inherit
 * its effective level from its parent.
 *
 * On each logging call the Logger initially performs a cheap check of the
 * request level (e.g. SEVERE or FINE) against the effective log level of the
 * logger. If the request level is lower than the log level, the logging call
 * returns immediately.
 *
 * After passing this initial (cheap) test, the Logger will allocate a LogRecord
 * to describe the logging message. It will then call a Filter (if present) to do
 * a more detailed check on whether the record should be published. If that passes
 * it will then publish the LogRecord to its output Handlers. By default, loggers
 * also publish to their parent's Handlers, recursively up the tree.
 *
 * Each Logger may have a ResourceBundle name associated with it. The named bundle
 * will be used for localizing logging messages. If a Logger does not have its own
 * ResourceBundle name, then it will inherit the ResourceBundle name from its
 * parent, recursively up the tree.
 *
 * Most of the logger output methods take a "msg" argument. This msg argument
 * may be either a raw value or a localization key. During formatting, if the
 * logger has (or inherits) a localization ResourceBundle and if the
 * ResourceBundle has a mapping for the msg string, then the msg string is
 * replaced by the localized value. Otherwise the original msg string is used.
 * Typically, formatters use java.text.MessageFormat style formatting to format
 * parameters, so for example a format string "{0} {1}" would format two
 * parameters as strings.
 *
 * When mapping ResourceBundle names to ResourceBundles, the Logger will
 * first try to use the Thread's ContextClassLoader. If that is null it will
 * try the SystemClassLoader instead. As a temporary transition feature in
 * the initial implementation, if the Logger is unable to locate a ResourceBundle
 * from the ContextClassLoader or SystemClassLoader the Logger will also
 * search up the class stack and use successive calling ClassLoaders to try
 * to locate a ResourceBundle. (This call stack search is to allow containers
 * to transition to using ContextClassLoaders and is likely to be removed in
 * future versions.)
 *
 * Formatting (including localization) is the responsibility of the output
 * Handler, which will typically call a Formatter.
 *
 * Note that formatting need not occur synchronously. It may be delayed until
 * a LogRecord is actually written to an external sink.
 *
 * The logging methods are grouped in five main categories:
 *
 * There are a set of "log" methods that take a log level, a message string,
 * and optionally some parameters to the message string.
 *
 * There are a set of "logp" methods (for "log precise") that are like the
 * "log" methods, but also take an explicit source class name and method name.
 *
 * There are a set of "logrb" method (for "log with resource bundle") that
 * are like the "logp" method, but also take an explicit resource bundle name
 * for use in localizing the log message.
 *
 * There are convenience methods for tracing method entries (the "entering"
 * methods), method returns (the "exiting" methods) and throwing exceptions
 * (the "throwing" methods).
 *
 * Finally, there are a set of convenience methods for use in the very
 * simplest cases, when a developer simply wants to log a simple string
 * at a given log level. These methods are named after the standard Level
 * names ("severe", "warning", "info", etc.) and take a single argument,
 * a message string.
 *
 * For the methods that do not take an explicit source name and method name,
 * the Logging framework will make a "best effort" to determine which class
 * and method called into the logging method. However, it is important to
 * realize that this automatically inferred information may only be approximate
 * (or may even be quite wrong!). Virtual machines are allowed to do extensive
 * optimizations when JITing and may entirely remove stack frames, making it
 * impossible to reliably locate the calling class and method.
 *
 * All methods on Logger are multi-thread safe.
 *
 * Subclassing Information: Note that a LogManager class may provide its own
 * implementation of named Loggers for any point in the namespace. Therefore,
 * any subclasses of Logger (unless they are implemented in conjunction with
 * a new LogManager class) should take care to obtain a Logger instance from
 * the LogManager class and should delegate operations such as "isLoggable"
 * and "log(LogRecord)" to that instance. Note that in order to intercept
 * all logging output, subclasses need only override the log(LogRecord)
 * method. All the other logging methods are implemented as calls on this
 * log(LogRecord) method.
 *
 *********************************************************/

/*********************************************************
 *
 * log_handler_t data structure
 *
 *********************************************************/
struct __logger
{
	logger_t* 		parent;
	log_level_t* 	level;
	char 			name[LOGGER_NAME_LEN];
	xos_hash_t 		children;
	xos_hash_t 		handlers;
	BOOL			is_use_parent_handlers;
	log_filter_t*	filter;
	xos_mutex_t*	loggerLock;	//if not NULL, it will be locked before publish
    int             numHandlers;

};


/*********************************************************
 *
 * new, init, destroy, free methods
 *
 *********************************************************/
logger_t* logger_new(
					const char* name,
					logger_t* parent,
					log_level_t* level);
void logger_init(
					logger_t* self,
					const char* name,
					logger_t* parent,
					log_level_t* level);
void logger_destroy(logger_t* self);
void logger_free(logger_t* self);

// Log source and method
void log_p(logger_t* self,
			log_level_t* level,
			const char* source_class,
			const char* source_method,
			const char* msg);
void entering(logger_t* self,
			const char* source_class,
			const char* source_method);
void exiting(logger_t* self,
			const char* source_class,
			const char* source_method);

// Log a record
void log_r(logger_t* self, log_record_t* record);

// Variable argument list
//void log(logger_t* self, log_level_t* level, const char* format, ...);
void loglog(logger_t* self, log_level_t* level, const char* format, ...);
void severe(logger_t* self, const char* format, ...);
void warning(logger_t* self, const char* format, ...);
void info(logger_t* self, const char* format, ...);
void config(logger_t* self, const char* format, ...);
void fine(logger_t* self, const char* format, ...);
void finer(logger_t* self, const char* format, ...);
void finest(logger_t* self, const char* format, ...);

void log_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			log_level_t* level,
			const char* format, ...);
			
void severe_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);
void warning_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);
void info_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);
void config_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);
void fine_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);
void finer_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);
void finest_details(const char* file,
			int line,
			const char* date,
			const char* time,
			logger_t* self, 
			const char* format, ...);


// Set and get methods
void logger_set_filter(logger_t* self, log_filter_t* filter);
log_filter_t* logger_get_filter(logger_t* self);
log_level_t* logger_get_level(logger_t* self);
void logger_set_level(logger_t* self, log_level_t* level);
BOOL logger_is_loggable(logger_t* self, log_level_t* level);
const char* logger_get_name(logger_t* self);
void logger_add_handler(logger_t* self, log_handler_t* handler);
void logger_remove_handler(logger_t* self, log_handler_t* handler);
xos_hash_t* logger_get_handlers(logger_t* self);
void logger_set_use_parent_handlers(logger_t* self,
			BOOL use_parent_handlers);
BOOL logger_get_use_parent_handlers(logger_t* self);
void logger_set_parent(logger_t* self, logger_t* parent);
logger_t* logger_get_parent(logger_t* self);
xos_mutex_t* logger_get_lock(logger_t* self);


// Utility func. Get hex string from address of the pointer.
void get_hex(void* pointer, char* ret);

#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __logger_h__ */



