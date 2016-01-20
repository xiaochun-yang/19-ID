#ifdef __cplusplus
extern "C" {
#endif

#ifndef __LOGLIB_QUICK_H__
#define __LOGLIB_QUICK_H__


#include "logging.h"
#include "log_level.h"
#include "log_quick.h"

// Global variables
extern logger_t* gpXosLogger;
extern logger_t* gpXosCppLogger;
extern logger_t* gpHttpCppLogger;
extern logger_t* gpAuthClientLogger;
extern logger_t* gpDiffImageLogger;
extern logger_t* gpDcsConfigLogger;
extern logger_t* gpTclClibsLogger;

#define LOG_XOS_LIB 0x0001
#define LOG_XOS_CPP_LIB 0x0002
#define LOG_HTTP_CPP_LIB 0x0004
#define LOG_AUTH_CLIENT_LIB 0x0008
#define LOG_DIFFIMAGE_LIB 0x0010
#define LOG_DCSCONFIG_LIB 0x0020
#define LOG_TCL_CLIBS_LIB 0x0040


#ifdef NO_LOG

#define TRACE(l, f)
#define TRACE1(l, f, a1)
#define TRACE2(l, f, a1, a2)
#define TRACE3(l, f, a1, a2, a3)

#define LOG_XOS(f)
#define LOG_XOS_CPP(f)
#define LOG_HTTP_CPP(f)
#define LOG_AUTH_CLIENT(f)
#define LOG_DIFFIMAGE(f)
#define LOG_DCSCONFIG(f)
#define LOG_TCL_CLIBS(f)

#define LOG_XOS1(f, a1)
#define LOG_XOS_CPP1(f, a1)
#define LOG_HTTP_CPP1(f, a1)
#define LOG_AUTH_CLIENT1(f, a1)
#define LOG_DIFFIMAGE1(f, a1)
#define LOG_DCSCONFIG1(f, a1)
#define LOG_TCL_CLIBS1(f, a1)

#define LOG_XOS2(f, a1, a2)
#define LOG_XOS_CPP2(f, a1, a2)
#define LOG_HTTP_CPP2(f, a1, a2)
#define LOG_AUTH_CLIENT2(f, a1, a2)
#define LOG_DIFFIMAGE2(f, a1, a2)
#define LOG_DCSCONFIG2(f, a1, a2)
#define LOG_TCL_CLIBS2(f, a1, a2)

#define LOG_XOS3(f, a1, a2, a3)
#define LOG_XOS_CPP3(f, a1, a2, a3)
#define LOG_HTTP_CPP3(f, a1, a2, a3)
#define LOG_AUTH_CLIENT3(f, a1, a2, a3)
#define LOG_DIFFIMAGE3(f, a1, a2, a3)
#define LOG_DCSCONFIG3(f, a1, a2, a3)
#define LOG_TCL_CLIBS3(f, a1, a2, a3)


#else // if NO_LOG


#ifdef LOG_OPTIMIZED

#define LOG_XOS(level, level, f) loglog(gpXosLogger, level, f)
#define LOG_XOS_CPP(level, f) loglog(gpXosCppLogger, level, f)
#define LOG_HTTP_CPP(level, f) loglog(gpHttpCppLogger, level, f)
#define LOG_AUTH_CLIENT(level, f) loglog(gpAuthClientLogger, level, f)
#define LOG_DIFFIMAGE(level, f) loglog(gpDiffImageLogger, level, f)
#define LOG_DCSCONFIG(level, f) loglog(gpDcsConfigLogger, level, f)
#define LOG_TCL_CLIBS(level, f) loglog(gpTclClibsLogger, level, f)

#define LOG_XOS1(level, f, a1) loglog(gpXosLogger, level, f, a1)
#define LOG_XOS_CPP1(level, f, a1) loglog(gpXosCppLogger, level, f, a1)
#define LOG_HTTP_CPP1(level, f, a1) loglog(gpHttpCppLogger, level, f, a1)
#define LOG_AUTH_CLIENT1(level, f, a1) loglog(gpAuthClientLogger, level, f, a1)
#define LOG_DIFFIMAGE1(level, f, a1) loglog(gpDiffImageLogger, level, f, a1)
#define LOG_DCSCONFIG1(level, f, a1) loglog(gpDcsConfigLogger, level, f, a1)
#define LOG_TCL_CLIBS1(level, f, a1) loglog(gpTclClibsLogger, level, f, a1)

#define LOG_XOS2(level, f, a1, a2) loglog(gpXosLogger, level, f, a1, a2)
#define LOG_XOS_CPP2(level, f, a1, a2) loglog(gpXosCppLogger, level, f, a1, a2)
#define LOG_HTTP_CPP2(level, f, a1, a2) loglog(gpHttpCppLogger, level, f, a1, a2)
#define LOG_AUTH_CLIENT2(level, f, a1, a2) loglog(gpAuthClientLogger, level, f, a1, a2)
#define LOG_DIFFIMAGE2(level, f, a1, a2) loglog(gpDiffImageLogger, level, f, a1, a2)
#define LOG_DCSCONFIG2(level, f, a1, a2) loglog(gpDcsConfigLogger, level, f, a1, a2)
#define LOG_TCL_CLIBS2(level, f, a1, a2) loglog(gpTclClibsLogger, level, f, a1, a2)

#define LOG_XOS3(level, f, a1, a2, a3) loglog(gpXosLogger, level, f, a1, a2, a3)
#define LOG_XOS_CPP3(level, f, a1, a2, a3) loglog(gpXosCppLogger, level, f, a1, a2, a3)
#define LOG_HTTP_CPP3(level, f, a1, a2, a3) loglog(gpHttpCppLogger, level, f, a1, a2, a3)
#define LOG_AUTH_CLIENT3(level, f, a1, a2, a3) loglog(gpAuthClientLogger, level, f, a1, a2, a3)
#define LOG_DIFFIMAGE3(level, f, a1, a2, a3) loglog(gpDiffImageLogger, level, f, a1, a2, a3)
#define LOG_DCSCONFIG3(level, f, a1, a2, a3) loglog(gpDcsConfigLogger, level, f, a1, a2, a3)
#define LOG_TCL_CLIBS3(level, f, a1, a2, a3) loglog(gpTclClibsLogger, level, f, a1, a2, a3)

#else


#define LOG_XOS(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosLogger, level, f)
#define LOG_XOS_CPP(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosCppLogger, level, f)
#define LOG_HTTP_CPP(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpHttpCppLogger, level, f)
#define LOG_AUTH_CLIENT(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpAuthClientLogger, level, f)
#define LOG_DIFFIMAGE(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDiffImageLogger, level, f)
#define LOG_DCSCONFIG(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDcsConfigLogger, level, f)
#define LOG_TCL_CLIBS(level, f) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpTclClibsLogger, level, f)

#define LOG_XOS1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosLogger, level, f, a1)
#define LOG_XOS_CPP1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosCppLogger, level, f, a1)
#define LOG_HTTP_CPP1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpHttpCppLogger, level, f, a1)
#define LOG_AUTH_CLIENT1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpAuthClientLogger, level, f, a1)
#define LOG_DIFFIMAGE1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDiffImageLogger, level, f, a1)
#define LOG_DCSCONFIG1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDcsConfigLogger, level, f, a1)
#define LOG_TCL_CLIBS1(level, f, a1) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpTclClibsLogger, level, f, a1)

#define LOG_XOS2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosLogger, level, f, a1, a2)
#define LOG_XOS_CPP2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosCppLogger, level, f, a1, a2)
#define LOG_HTTP_CPP2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpHttpCppLogger, level, f, a1, a2)
#define LOG_AUTH_CLIENT2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpAuthClientLogger, level, f, a1, a2)
#define LOG_DIFFIMAGE2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDiffImageLogger, level, f, a1, a2)
#define LOG_DCSCONFIG2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDcsConfigLogger, level, f, a1, a2)
#define LOG_TCL_CLIBS2(level, f, a1, a2) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpTclClibsLogger, level, f, a1, a2)

#define LOG_XOS3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosLogger, level, f, a1, a2, a3)
#define LOG_XOS_CPP3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpXosCppLogger, level, f, a1, a2, a3)
#define LOG_HTTP_CPP3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpHttpCppLogger, level, f, a1, a2, a3)
#define LOG_AUTH_CLIENT3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpAuthClientLogger, level, f, a1, a2, a3)
#define LOG_DIFFIMAGE3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDiffImageLogger, level, f, a1, a2, a3)
#define LOG_DCSCONFIG3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDcsConfigLogger, level, f, a1, a2, a3)
#define LOG_TCL_CLIBS3(level, f, a1, a2, a3) log_details(__FILE__, __LINE__, __DATE__, __TIME__, gpTclClibsLogger, level, f, a1, a2, a3)

#endif // if LOG_OPTIMIZED


#endif // if NO_LOG


// Turn on/off the logger for each library
void log_include_all_modules(int flags);
void log_include_modules(int flags);

#endif // __LOGLIB_QUICK_H__


#ifdef __cplusplus
}
#endif

