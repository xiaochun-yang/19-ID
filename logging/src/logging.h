#ifndef __logging_h__
#define __logging_h__

/*********************************************************
 *
 *
 *
 *********************************************************/
#include "log_common.h"
#include "log_level.h"
#include "log_record.h"

#include "log_handler.h"
#include "log_console_handler.h"
#include "log_file_handler.h"
#include "log_native_handler.h"
#include "log_socket_handler.h"
#include "log_syslog_handler.h"
#include "log_udp_handler.h"
#include "log_handler_factory.h"

#include "log_formatter.h"
#include "log_simple_formatter.h"
#include "log_token_formatter.h"
#include "log_xml_formatter.h"
#include "log_trace_formatter.h"

#include "log_filter.h"

#include "logger.h"
#include "log_manager.h"

void set_save_logger_error(int flag);
void save_logger_error( const char *message );
#endif /* __logging_h__*/
