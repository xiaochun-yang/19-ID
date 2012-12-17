#ifndef __log_common_h__
#define __log_common_h__

/*********************************************************
 *
 *
 *
 *********************************************************/
#ifndef BOOL
typedef int BOOL;
#endif

#ifndef __cplusplus
#ifndef bool
typedef BOOL bool;
#endif
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef LOG_FALSE
#define LOG_FALSE 0
#endif

#ifndef LOG_TRUE
#define LOG_TRUE 1
#endif

#ifndef NULL
#define NULL 0
#endif

#ifndef null
#define null 0
#endif

// General
#define INT_STR_LEN 64

// logger_t
#define LOGGER_NAME_LEN 250

// log_record_t
#define LOG_RECORD_MSG_LEN 500
#define LOG_RECORD_SOURCE_LEN 250
#define LOG_RECORD_METHOD_LEN 250
#define LOG_RECORD_FILE_LEN 250
#define LOG_RECORD_DATE_LEN 15
#define LOG_RECORD_TIME_LEN 10

// log_formatter_t

// log_simple_formatter_t
#define LOG_SIMPLE_MSG_LEN 9999

// log_token_formatter_t
#define LOG_TOKEN_MSG_LEN 9999

// log_xml_formatter_t

// log_handler_t
#define STDOUT_HANDLER "stdout"
#define STDERR_HANDLER "stderr"
#define FILE_HANDLER "file"
#define SOCKET_HANDLER "socket"
#define UDP_HANDLER "udp"
#define MEMORY_HANDLER "memory"

// log_console_handler_t

// log_file_handler_t

struct __log_formatter;
typedef struct __log_formatter log_formatter_t;

struct __log_console_handler;
typedef struct __log_console_handler log_console_handler_t;

struct __log_file_handler;
typedef struct __log_file_handler log_file_handler_t;

struct __log_socket_handler;
typedef struct __log_socket_handler log_socket_handler_t;

struct __log_filter;
typedef struct __log_filter log_filter_t;

struct __log_handler;
typedef struct __log_handler log_handler_t;

struct __log_level;
typedef struct __log_level log_level_t;


struct __logger;
typedef struct __logger logger_t;


struct __log_manager;
typedef struct __log_manager log_manager_t;


#ifdef WIN32
#define SNPRINTF _snprintf
#define VSNPRINTF _vsnprintf

typedef int mode_t;

#else
#define SNPRINTF snprintf
#define VSNPRINTF vsnprintf
#endif



#endif /* __log_common_h__*/
