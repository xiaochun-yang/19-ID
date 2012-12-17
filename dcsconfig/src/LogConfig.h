#ifndef __Include_LogConfig_h__
#define __Include_LogConfig_h__

#include "log_quick.h"
#include "logger.h"
#include "DcsConfig.h"
#include <string>

class LogConfig
{

public:

	LogConfig(const std::string& module);
	
	virtual ~LogConfig();
		
	bool update(const DcsConfig& config);
	
	
	
private:

	log_manager_t* log_manager;
	log_handler_t* file_handler;
	log_handler_t* stdout_handler;
	log_handler_t* udp_handler;
	log_formatter_t* trace_formatter;
	
	std::string module;


	static bool initFlag;
};

#endif // __Include_LogConfig_h__

