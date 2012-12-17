#include "logging.h"
#include "loglib_quick.h"

// Global variables
logger_t* gpXosLogger = NULL;
logger_t* gpXosCppLogger = NULL;
logger_t* gpHttpCppLogger = NULL;
logger_t* gpAuthClientLogger = NULL;
logger_t* gpDiffImageLogger = NULL;
logger_t* gpDcsConfigLogger = NULL;
logger_t* gpTclClibsLogger = NULL;

// Turn on/off the gpDefaultLogger for all libraries
void log_include_all_modules(int flags)
{

	gpXosLogger = gpDefaultLogger;
	gpXosCppLogger = gpDefaultLogger;
	gpHttpCppLogger = gpDefaultLogger;
	gpAuthClientLogger = gpDefaultLogger;
	gpDiffImageLogger = gpDefaultLogger;
	gpDcsConfigLogger = gpDefaultLogger;
	gpTclClibsLogger = gpDefaultLogger;
}


// Turn on/off the gpDefaultLogger for each library
void log_include_modules(int flags)
{
		
	if (flags & LOG_XOS_LIB)
		gpXosLogger = gpDefaultLogger;
	else
		gpXosLogger = NULL;

	if (flags & LOG_XOS_CPP_LIB)
		gpXosCppLogger = gpDefaultLogger;
	else
		gpXosCppLogger = NULL;


	if (flags & LOG_HTTP_CPP_LIB)
		gpHttpCppLogger = gpDefaultLogger;
	else
		gpHttpCppLogger = NULL;

	if (flags & LOG_AUTH_CLIENT_LIB)
		gpAuthClientLogger = gpDefaultLogger;
	else
		gpAuthClientLogger = NULL;

	if (flags & LOG_DIFFIMAGE_LIB)
		gpDiffImageLogger = gpDefaultLogger;
	else
		gpDiffImageLogger = NULL;

	if (flags & LOG_DCSCONFIG_LIB)
		gpDcsConfigLogger = gpDefaultLogger;
	else
		gpDcsConfigLogger = NULL;

	if (flags & LOG_TCL_CLIBS_LIB)
		gpTclClibsLogger = gpDefaultLogger;
	else
		gpTclClibsLogger = NULL;


}

