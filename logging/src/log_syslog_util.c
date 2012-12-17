#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#ifndef WIN32
#include <fcntl.h>
#include <syslog.h>
#endif

/*********************************************************
 *
 * Need syslog calls to be in this file so that we don't
 * need syslog header files in log_syslog_handler because
 * of naming conflicts, e.g. LOG_INFO in this logging
 * library refers to log_level_t data structure whereas
 * LOG_INFO is an int for syslog.
 *
 *********************************************************/
 
/*********************************************************
 *
 * Converts log level to syslog level
 *
 *********************************************************/
int get_syslog_level(const char* level)
{
#ifndef WIN32
/*	printf("level = %s, LOG_ERR = %d, LOG_WARNING = %d, LOG_INFO = %d, LOG_DEBUG = %d\n",
		level, LOG_ERR, LOG_WARNING, LOG_INFO, LOG_DEBUG);*/
	if (level == NULL) {
		return LOG_DEBUG;
	} else if (strcmp(level, "OFF") == 0) {
		return LOG_DEBUG;
	} else if (strcmp(level, "SEVERE") == 0) {
		return LOG_ERR;
	} else if (strcmp(level, "WARNING") == 0) {
		return LOG_WARNING;
	} else if (strcmp(level, "CONFIG") == 0) {
		return LOG_INFO;
	} else if (strcmp(level, "INFO") == 0) {
		return LOG_INFO;
	} else if (strcmp(level, "FINE") == 0) {
		return LOG_DEBUG;
	} else if (strcmp(level, "FINER") == 0) {
		return LOG_DEBUG;
	} else if (strcmp(level, "FINEST") == 0) {
		return LOG_DEBUG;
	}
	
	return LOG_INFO;
#else
	return 0;
#endif
}

/*********************************************************
 *
 * Calls syslog()
 *
 *********************************************************/
void call_syslog(int priority, const char *message)
{
#ifndef WIN32
	syslog(priority, message);
#endif
}

/*********************************************************
 *
 * Convert SYSLOG_* to LOG_*
 *
 *********************************************************/
int get_syslog_facility_from_int(int f)
{
#ifndef WIN32
	switch (f) {
		case 0:
			return LOG_LOCAL0;
		case 1:
			return LOG_LOCAL1;
		case 2:
			return LOG_LOCAL2;
		case 3:
			return LOG_LOCAL3;
		case 4:
			return LOG_LOCAL4;
		case 5:
			return LOG_LOCAL5;
		case 6:
			return LOG_LOCAL6;
		case 7:
			return LOG_LOCAL7;
	}
	
	return LOG_USER;
#else
	return 0;
#endif
}

/*********************************************************
 *
 * Convert SYSLOG_* to LOG_*
 *
 *********************************************************/
int get_syslog_facility_from_string(const char* f)
{
#ifndef WIN32
	if (strcmp(f, "LOG_LOCAL0") == 0)
		return LOG_LOCAL0;
	else if (strcmp(f, "LOG_LOCAL1") == 0)
		return LOG_LOCAL1;
	else if (strcmp(f, "LOG_LOCAL2") == 0)
		return LOG_LOCAL2;
	else if (strcmp(f, "LOG_LOCAL3") == 0)
		return LOG_LOCAL3;
	else if (strcmp(f, "LOG_LOCAL4") == 0)
		return LOG_LOCAL4;
	else if (strcmp(f, "LOG_LOCAL5") == 0)
		return LOG_LOCAL5;
	else if (strcmp(f, "LOG_LOCAL6") == 0)
		return LOG_LOCAL6;
	else if (strcmp(f, "LOG_LOCAL7") == 0)
		return LOG_LOCAL7;
	
	return LOG_USER;
#else
	return 0;
#endif
}

/*********************************************************
 *
 * Calls openlog()
 *
 *********************************************************/
void call_openlog(const char* ident, int logopt, int f)
{
	int facility = 0;
#ifndef WIN32
	if (logopt == 0)
		logopt = LOG_ODELAY | LOG_PID;
	facility = get_syslog_facility_from_int(f);
/*	printf("calling openlog: ident = %s, logopt = %d, facility = %d, LOG_LOCAL1 = %d\n", 
		ident, logopt, facility, LOG_LOCAL1); */
	fflush(stdout);
 	openlog(ident, logopt, LOG_LOCAL1);
#endif
}


/*********************************************************
 *
 * Calls closelog()
 *
 *********************************************************/
void call_closelog()
{
#ifndef WIN32
	closelog();
#endif
}

