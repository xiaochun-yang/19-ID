#include "XosStringUtil.h"
#include "log_quick.h"
#include "LogConfig.h"
#include <string>

// class variable
bool LogConfig::initFlag = false;

/*******************************************************************
 * 
 * Constructor
 *
 *******************************************************************/
LogConfig::LogConfig(const std::string& module)
{
	// Initialize the log API
	// Should be done once per application 
	// before any log API calls.
	if (!initFlag)
		g_log_init();
		
	initFlag = true;
	
	// Set the module name
	this->module = module;

	// Create log manager
	log_manager = g_log_manager_new(NULL);
	
	// There is only one logger object per application
	// when we use log_quick.
	gpDefaultLogger = g_get_logger(log_manager, module.c_str(), NULL, LOG_ALL);
	
	// Create a trace style formatter
	trace_formatter = log_trace_formatter_new( );

	// Set stdout as default log handler.
	stdout_handler = g_create_log_stdout_handler();
	if (stdout_handler != NULL) {
		log_handler_set_level(stdout_handler, LOG_ALL);
		log_handler_set_formatter(stdout_handler, trace_formatter);
		logger_add_handler(gpDefaultLogger, stdout_handler);
	}
}

/*******************************************************************
 * 
 * Destructor
 *
 *******************************************************************/
LogConfig::~LogConfig()
{
	if (initFlag)
		g_log_clean_up();
		
	initFlag = false;

}

/*******************************************************************
 * 
 * Update
 *
 *******************************************************************/
bool LogConfig::update(const DcsConfig& config)
{
	std::string level;
	bool isStdout = true;
	std::string udpHost;
	int udpPort = 0;
	std::string filePattern;
	int fileSize = 31457280;
	int numFiles = 3;
	bool append = false;
	
	
	std::string tmp;
	if (!config.get(module + ".logStdout", tmp)) {
		LOG_WARNING1("Could not find %s.logStdout in config file\n", module.c_str());
		return false;
	}
		
	if (tmp == "false")
		isStdout = false;
		
	
	if (!config.get(module + ".logUdpHost", tmp)) {
		LOG_WARNING1("Could not find  %s.logUdpHost in config file\n", module.c_str());
		return false;
	}
		
	if (!config.get(module + ".logUdpPort", tmp)) {
		LOG_WARNING1("Could not find  %s.logUdpPort in config file\n", module.c_str());
		return false;
	}
		
	if (!tmp.empty())
		udpPort = XosStringUtil::toInt(tmp, udpPort);
		
	
	if (!config.get(module + ".logFilePattern", filePattern)) {
		LOG_WARNING1("Could not find  %s.filePattern in config file\n", module.c_str());
		return false;
	}
	
	if (!config.get(module + ".logFileSize", tmp)) {
		LOG_WARNING1("Could not find  %s.logFileSize in config file\n", module.c_str());
		return false;
	}
	
	if (!tmp.empty())
		fileSize = XosStringUtil::toInt(tmp, fileSize);

	if (!config.get(module + ".logFileMax", tmp)) {
		LOG_WARNING1("Could not find  %s.logFileMax in config file\n", module.c_str());
		return false;
	}
	
	if (!tmp.empty())
		numFiles = XosStringUtil::toInt(tmp, numFiles);

	if (!config.get(module + ".logLevel", level)) {
		LOG_WARNING1("Could not find  %s.logLevel in config file\n", module.c_str());
		return false;
	}
	

	log_level_t* logLevel = log_level_parse(level.c_str());
	
	if (logLevel == NULL)
		logLevel = LOG_ALL;

	logger_set_level(gpDefaultLogger, logLevel);
	
	// Turn off stdout log
	if (!isStdout && stdout_handler) {
		logger_remove_handler(gpDefaultLogger, stdout_handler);
	}
		
	if (!udpHost.empty() && (udpPort > 0)) {
		udp_handler = log_udp_handler_new(udpHost.c_str(), udpPort);
		if (udp_handler != NULL) {
			log_handler_set_level(udp_handler, logLevel);
			log_handler_set_formatter(udp_handler, trace_formatter);
			logger_add_handler(gpDefaultLogger, udp_handler);
		}
	}
		
	if (!filePattern.empty()) {
		file_handler = g_create_log_file_handler(filePattern.c_str(), append, fileSize, numFiles);
		if (file_handler != NULL) {
			log_handler_set_level(file_handler, logLevel);
			log_handler_set_formatter(file_handler, trace_formatter);
			logger_add_handler(gpDefaultLogger, file_handler);
		}
	}

//		log_include_modules(LOG_AUTH_CLIENT_LIB | LOG_HTTP_CPP_LIB);
//		log_include_modules(LOG_AUTH_CLIENT_LIB);

	return true;
}


