#ifdef __cplusplus
extern "C" {
#endif

#ifndef __LOG_QUICK_H__
#define __LOG_QUICK_H__

#include "logging.h"

/*******************************************
Usage:

	//uncomment following line if you want to get rid of logging
	//#define NO_LOG

	#include "log_quick.h"


		LOG_QUICK_OPEN;

		LOG_SEVERE( message ); //or other log method

		LOG_QUICK_CLOSE;

		//they do not need to be in the same file.
		//as long as you call LOG_QUICK_OPEN before other.
********************************************************/
extern logger_t* gpDefaultLogger;
extern mode_t    gLogFileMode;

#ifndef NO_LOG

#define LOG_QUICK_OPEN_STDOUT  log_quick_open_stdout( )
#define LOG_QUICK_OPEN  log_quick_open( )
#define LOG_QUICK_OPEN_NO_STDOUT  log_quick_open_no_stdout( )
#define LOG_QUICK_OPEN_WITH_NAME(a)  log_quick_open_with_name( a )
#define LOG_QUICK_CLOSE log_quick_close( )
#define LOG_QUICK_OPEN_SYSLOG  log_quick_open_syslog()
#define LOG_QUICK_CLOSE_SYSLOG log_quick_close_syslog( )

#ifdef LOG_OPTIMIZED

#define LOG_SEVERE(f) severe(gpDefaultLogger, f)
#define LOG_WARNING(f) warning(gpDefaultLogger, f)
#define LOG_INFO(f) info(gpDefaultLogger, f)
#define LOG_CONFIG(f) config(gpDefaultLogger, f)
#define LOG_FINE(f) fine(gpDefaultLogger, f)
#define LOG_FINER(f) finer(gpDefaultLogger, f)
#define LOG_FINEST(f) finest(gpDefaultLogger, f)

#define LOG_SEVERE1(f, a1) severe(gpDefaultLogger, f, a1)
#define LOG_WARNING1(f, a1) warning(gpDefaultLogger, f, a1)
#define LOG_INFO1(f, a1) info(gpDefaultLogger, f, a1)
#define LOG_CONFIG1(f, a1) config(gpDefaultLogger, f, a1)
#define LOG_FINE1(f, a1) fine(gpDefaultLogger, f, a1)
#define LOG_FINER1(f, a1) finer(gpDefaultLogger, f, a1)
#define LOG_FINEST1(f, a1) finest(gpDefaultLogger, f, a1)

#define LOG_SEVERE2(f, a1, a2) severe(gpDefaultLogger, f, a1, a2)
#define LOG_WARNING2(f, a1, a2) warning(gpDefaultLogger, f, a1, a2)
#define LOG_INFO2(f, a1, a2) info(gpDefaultLogger, f, a1, a2)
#define LOG_CONFIG2(f, a1, a2) config(gpDefaultLogger, f, a1, a2)
#define LOG_FINE2(f, a1, a2) fine(gpDefaultLogger, f, a1, a2)
#define LOG_FINER2(f, a1, a2) finer(gpDefaultLogger, f, a1, a2)
#define LOG_FINEST2(f, a1, a2) finest(gpDefaultLogger, f, a1, a2)

#define LOG_SEVERE3(f, a1, a2, a3) severe(gpDefaultLogger, f, a1, a2, a3)
#define LOG_WARNING3(f, a1, a2, a3) warning(gpDefaultLogger, f, a1, a2, a3)
#define LOG_INFO3(f, a1, a2, a3) info(gpDefaultLogger, f, a1, a2, a3)
#define LOG_CONFIG3(f, a1, a2, a3) config(gpDefaultLogger, f, a1, a2, a3)
#define LOG_FINE3(f, a1, a2, a3) fine(gpDefaultLogger, f, a1, a2, a3)
#define LOG_FINER3(f, a1, a2, a3) finer(gpDefaultLogger, f, a1, a2, a3)
#define LOG_FINEST3(f, a1, a2, a3) finest(gpDefaultLogger, f, a1, a2, a3)

#define LOG_SEVERE4(f, a1, a2, a3, a4) severe(gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_WARNING4(f, a1, a2, a3, a4) warning(gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_INFO4(f, a1, a2, a3, a4) info(gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_CONFIG4(f, a1, a2, a3, a4) config(gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_FINE4(f, a1, a2, a3, a4) fine(gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_FINER4(f, a1, a2, a3, a4) finer(gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_FINEST4(f, a1, a2, a3, a4) finest(gpDefaultLogger, f, a1, a2, a3, a4)

#define LOG_SEVERE5(f, a1, a2, a3, a4, a5) severe(gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_WARNING5(f, a1, a2, a3, a4, a5) warning(gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_INFO5(f, a1, a2, a3, a4, a5) info(gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_CONFIG5(f, a1, a2, a3, a4, a5) config(gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_FINE5(f, a1, a2, a3, a4, a5) fine(gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_FINER5(f, a1, a2, a3, a4, a5) finer(gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_FINEST5(f, a1, a2, a3, a4, a5) finest(gpDefaultLogger, f, a1, a2, a3, a4, a5)

#else

#define LOG_SEVERE(f) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)
#define LOG_WARNING(f) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)
#define LOG_INFO(f) info_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)
#define LOG_CONFIG(f) config_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)
#define LOG_FINE(f) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)
#define LOG_FINER(f) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)
#define LOG_FINEST(f) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f)

#define LOG_SEVERE1(f, a1) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)
#define LOG_WARNING1(f, a1) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)
#define LOG_INFO1(f, a1) info_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)
#define LOG_CONFIG1(f, a1) config_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)
#define LOG_FINE1(f, a1) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)
#define LOG_FINER1(f, a1) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)
#define LOG_FINEST1(f, a1) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1)

#define LOG_SEVERE2(f, a1, a2) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)
#define LOG_WARNING2(f, a1, a2) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)
#define LOG_INFO2(f, a1, a2) info_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)
#define LOG_CONFIG2(f, a1, a2) config_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)
#define LOG_FINE2(f, a1, a2) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)
#define LOG_FINER2(f, a1, a2) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)
#define LOG_FINEST2(f, a1, a2) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2)

#define LOG_SEVERE3(f, a1, a2, a3) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)
#define LOG_WARNING3(f, a1, a2, a3) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)
#define LOG_INFO3(f, a1, a2, a3) info_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)
#define LOG_CONFIG3(f, a1, a2, a3) config_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)
#define LOG_FINE3(f, a1, a2, a3) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)
#define LOG_FINER3(f, a1, a2, a3) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)
#define LOG_FINEST3(f, a1, a2, a3) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3)

#define LOG_SEVERE4(f, a1, a2, a3, a4) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_WARNING4(f, a1, a2, a3, a4) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_INFO4(f, a1, a2, a3, a4) info_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_CONFIG4(f, a1, a2, a3, a4) config_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_FINE4(f, a1, a2, a3, a4) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_FINER4(f, a1, a2, a3, a4) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)
#define LOG_FINEST4(f, a1, a2, a3, a4) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4)

#define LOG_SEVERE5(f, a1, a2, a3, a4, a5) severe_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_WARNING5(f, a1, a2, a3, a4, a5) warning_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_INFO5(f, a1, a2, a3, a4, a5) info_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_CONFIG5(f, a1, a2, a3, a4, a5) config_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_FINE5(f, a1, a2, a3, a4, a5) fine_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_FINER5(f, a1, a2, a3, a4, a5) finer_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)
#define LOG_FINEST5(f, a1, a2, a3, a4, a5) finest_details(__FILE__, __LINE__, __DATE__, __TIME__, gpDefaultLogger, f, a1, a2, a3, a4, a5)

#endif

#else

#define LOG_QUICK_OPEN_STDOUT
#define LOG_QUICK_OPEN 
#define LOG_QUICK_OPEN_NO_STDOUT
#define LOG_QUICK_CLOSE

#define LOG_SEVERE(f)
#define LOG_WARNING(f)
#define LOG_INFO(f)
#define LOG_CONFIG(f)
#define LOG_FINE(f)
#define LOG_FINER(f)
#define LOG_FINEST(f)

#define LOG_SEVERE1(f, a1)
#define LOG_WARNING1(f, a1)
#define LOG_INFO1(f, a1)
#define LOG_CONFIG1(f, a1)
#define LOG_FINE1(f, a1)
#define LOG_FINER1(f, a1)
#define LOG_FINEST1(f, a1)

#define LOG_SEVERE2(f, a1, a2)
#define LOG_WARNING2(f, a1, a2)
#define LOG_INFO2(f, a1, a2)
#define LOG_CONFIG2(f, a1, a2)
#define LOG_FINE2(f, a1, a2)
#define LOG_FINER2(f, a1, a2)
#define LOG_FINEST2(f, a1, a2)

#define LOG_SEVERE3(f, a1, a2, a3)
#define LOG_WARNING3(f, a1, a2, a3)
#define LOG_INFO3(f, a1, a2, a3)
#define LOG_CONFIG3(f, a1, a2, a3)
#define LOG_FINE3(f, a1, a2, a3)
#define LOG_FINER3(f, a1, a2, a3)
#define LOG_FINEST3(f, a1, a2, a3)

#endif

void log_quick_set_file_mode( mode_t mod );
void log_quick_set_number_of_file( int num );
void log_quick_set_file_size( int size );
void log_quick_set_file_pattern( const char* pattern );
void log_quick_open_stdout( void );
void log_quick_open_no_stdout( void );
void log_quick_open( void );
void log_quick_open_with_name( const char* logName );
void log_quick_close( void );
void log_quick_open_syslog();
void log_quick_close_syslog( void );

#endif

#ifdef __cplusplus
}
#endif

