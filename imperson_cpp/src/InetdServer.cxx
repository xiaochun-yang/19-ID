#include "xos.h"
#include "log_quick.h"
#include <dirent.h>
#include <sys/stat.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include "log_quick.h"
#include "loglib_quick.h"
#include "XosStringUtil.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "ImpServer.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpCommandFactory.h"
#include "HttpServerFactory.h"
#include "AuthClient.h"
#include "HttpClientSSLImp.h"
#include "ImpServer.h"

static log_manager_t* log_manager = NULL;
static log_handler_t* native_handler = NULL;
static log_formatter_t* trace_formatter = NULL;

/*************************************************
 *
 * Initialize syslog logger
 *
 *************************************************/
void open_syslog()
{
	// Global variables are defined in log_quick.h
		
	// Initialize the logging
	g_log_init();

	log_manager = g_log_manager_new(NULL);

	// Get a logger from the manager. 
	gpDefaultLogger = g_get_logger(log_manager, "imperson", NULL, LOG_ALL);

	// trace formatter
	trace_formatter = log_trace_formatter_new( );

	// syslog handler
	// Log to LOG_LOCAL1 facility
	native_handler = g_create_log_syslog_handler("imperson", SYSLOG_LOCAL1);
	
	// Mask log level for this logHandler
	log_handler_set_level(native_handler, LOG_ALL);
	
	// Assign formatter for this handler
	log_handler_set_formatter(native_handler, trace_formatter);
	
	// Add handler to this logger
	logger_add_handler(gpDefaultLogger, native_handler);
	
	// Mask log level for the whole logger
    	// global variable defined in log_quick.h
    	// By default log level mask is set to LOG_ALL
    	// which means that all levels of logs will be 
    	// sent to output.
    	// Reset the mask here if needed.
	logger_set_level(gpDefaultLogger, LOG_INFO);

	// Allow logging from auth_client library
	log_include_modules(LOG_AUTH_CLIENT_LIB);
	
}

/*************************************************
 *
 * Cleanup logger
 * DO NOT add stdout handler to this func.
 * It is used by the impersonation server
 * where its stdout is redirected to socket
 * for sending HTTP response to client.
 *
 *************************************************/
void close_syslog()
{
	// Global variables are defined in log_quick.h
	
	// Free memory in the correct order
	g_logger_free(log_manager, gpDefaultLogger);

	log_handler_free(native_handler);
	log_formatter_free(trace_formatter);

	// Uninitialize the logging system
	g_log_manager_free(log_manager);
	g_log_clean_up();
	
}

/*************************************************
 *
 * Main routine
 *
 *************************************************/
int main(int argc, char *argv[])
{
	try {

	// Disable xos_error logging to stderr or stdout
	xos_error_set_stream(NULL);
    
	// Initialize logging
	open_syslog();
        
	std::string authHost = "localhost";
	int authPort = 8080;
	int authSecurePort = 0;
	std::string appName = "SMBTest";
	std::string authMethod = "";
	std::string caFile = "";
	std::string caDir = "";
	std::string ciphers = "";
	std::string defShell = "";
    
	// Stop xos_socket from printing errors to stderr
	// Otherwise it will be streamed out to client socket.
	xos_socket_set_print_error_flag(0);

	// Create an imp server that will
	// handle a specific command received
	// via an http request
	ImpServer* server = new ImpServer("Impersonation Server/2.0");

	// Parse commandline arguments set in /etc/xinetd.d/imperson file
	// server_args host=smbws1.slac.stanford.edu port=8084 securePort=8447 method=smb_config_database appName=SMBTest 
	// readonly=true caFile=/usr/local/dcs/dcsconfig/data/server.crt caDir=/usr/local/dcs/dcsconfig/data/trusted_ca_dir
	// defShell=/bin/tcsh
	for (int i = 1; i < argc; ++i) {
		std::string str = argv[i];
		if (str.find("host=") == 0) {
			authHost = str.substr(5);
		} else if (str.find("port=") == 0) {
			std::string tt = str.substr(5);
			authPort = XosStringUtil::toInt(tt, 0);
		} else if (str.find("securePort=") == 0) {
			std::string tt = str.substr(11);
			authSecurePort = XosStringUtil::toInt(tt, 0);
            //LOG_INFO1( "got securePort=%d", authSecurePort );
		} else if (str.find("method=") == 0) {
			authMethod = str.substr(7);
		} else if (str.find("appName=") == 0) {
			appName = str.substr(8);
		} else if (str.find("caFile=") == 0) {
			caFile = str.substr(7);
		} else if (str.find("caDir=") == 0) {
			caDir = str.substr(6);
		} else if (str.find("ciphers=") == 0) {
			ciphers = str.substr(8);
		} else if (str.find("defShell=") == 0) {
			defShell = str.substr(9);
		} else if (str.find("logLevel=") == 0) {
			std::string logLevel = str.substr(9);
			// OFF, SEVERE, WARNING, INFO, CONFIG, FINE, FINER, FINEST, ALL
			log_level_t* level = log_level_parse(logLevel.c_str());
			if (level != null)
				logger_set_level(gpDefaultLogger, level);
		} else if (str.find("readonly=") == 0) {
			std::string tt = str.substr(9);
			if (tt == "true")
				server->setReadOnly(true);
		} else {
			// Old style arguments
			// server_args <auth host> <auth port> <readonly> <auth appName> <auth method>
			if (i == 1) {
				authHost = str;
			} else if (i == 2) {
				authPort = XosStringUtil::toInt(str, 80);
			} else if (i == 3) {
				if (str == "readonly")
					server->setReadOnly(true);
			} else if (i == 4) {
				appName = str;
			} else if (i == 5) {
				authMethod = str;
			}
		}
	}

	// For debug only
/*	printf("authHost = %s\n", authHost.c_str());
	printf("authPort = %d\n", authPort);
	printf("authSecurePort = %d\n", authSecurePort);
	printf("authAppName = %s\n", appName.c_str());
	printf("authMethod = %s\n", authMethod.c_str());
	printf("authCaFile = %s\n", authCaFile.c_str());
	printf("authCaDir = %s\n", authCaDir.c_str());
	printf("readonly = %d\n", server->isReadOnly());
	printf("ciphers = %d\n", server->ciphers.c_str());*/

	// Set default cipher suite
	if (ciphers.size() > 0)
		HttpClientSSLImp::setDefaultCiphers(ciphers.c_str());

	server->setDefShell(defShell);
	server->setAuthentication(authHost, authPort, authSecurePort, appName, authMethod, caFile, caDir, ciphers);
	
	// Set parameters specific to the server
	server->setTmpDir("/tmp");


    // Create an http server stream
    // The stream will be used to extract the command
    // and parameters from the http request
    // and send the result back to the client
    HttpServer* conn =
        HttpServerFactory::createServer(INETD_STREAM);

    conn->setHandler(server);

    // Start waiting for the request
    conn->start();

    delete conn;
    delete server;

    // Free logging resources
    close_syslog();

    return 0;

    } catch (XosException& e) {
        LOG_SEVERE2("XosException in main (%d): %s\n",
                e.getCode(), e.getMessage().c_str());
    } catch (std::exception& e) {
        LOG_SEVERE1("std::exception in main: %s\n",
                e.what());
    } catch (...) {
        LOG_SEVERE("Unknown exception in main\n");
    }

}

