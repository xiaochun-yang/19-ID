#ifndef __log_native_handler_h__
#define __log_native_handler_h__
#include "log_common.h"
#include "log_level.h"
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */

/*********************************************************
NATIVE LOG:

For Windows:    EventLog
For Linux:      sysLog
*********************************************************/
//void log_native_handler_init( log_handler_t* self, const char* logName );
log_handler_t* log_native_handler_new( const char* logName );

#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_native_handler_h__ */

