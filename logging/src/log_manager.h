#ifndef __log_manager_h__
#define __log_manager_h__

#include "xos.h"
#include "log_common.h"
#include "log_level.h"
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */

struct __log_manager {
	xos_hash_t loggers;
};


/*********************************************************
 *
 * Initializes the logging system. 
 *
 *********************************************************/
void g_log_init();

/*********************************************************
 *
 * Releases memory and resources. log objects and functions
 * should not be called thereafter.
 *
 *********************************************************/
void g_log_clean_up();

/*********************************************************
 *
 * Creates a log manager. Reads the config file.
 * If there are loggers defined in the log file, they
 * will be created automatically with the attributes found
 * in the config file.
 *
 *********************************************************/
log_manager_t* g_log_manager_new(const char* config_name);

/*********************************************************
 *
 * Free the log_manager_t
 *
 *********************************************************/
void g_log_manager_free(log_manager_t* self);


/*********************************************************
 *
 * Creates a logger with the given name. Use the settings
 * defined in the config file, if exists, for this logger.
 *********************************************************/
logger_t* g_get_logger(log_manager_t* self, const char* name,
					   logger_t* parent, log_level_t* level);

/*********************************************************
 *
 * Deallocate memory for the logger_t
 *
 *********************************************************/
void g_logger_free(log_manager_t* self, logger_t* logger);


#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_manager_h__ */



