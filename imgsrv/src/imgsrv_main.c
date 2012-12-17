/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/

/* local include files */

#include "xos.h"
#include "xos_socket.h"
#include "diffimage.h"
#include "imgsrv_cache.h"
#include "imgsrv_client.h"
#include "XosStringUtil.h"
#include "DcsConfig.h"
#include "LogConfig.h"
#include <string>

int gListeningPort[3];
std::string gTempJpgDirectory;
std::string gImpersonHost;
byte gImpersonIpArray[4];
int gImpersonPort;
int gMaxIdleTime;
std::string gAuthHost;
int gAuthPort;
int gAuthSecurePort;
std::string gAuthAppName;
std::string gAuthMethod;
std::string gAuthCaFile;
std::string gAuthCaDir;
int gImageCacheSize = 10;
int gMaxClientCount = 100;

/****************************************************************
	main:
****************************************************************/

int main( int 	argc, char 	*argv[] )
{
	// Do not save errors in LOG_SELF_ERROR.txt
	// because imgsrv runs for a long period of time
	// and the file can get too big.
	set_save_logger_error(0);

	log_quick_set_file_mode(S_IRUSR |S_IWUSR | S_IRGRP | S_IROTH);

	LogConfig dcsLog("imgsrv");

	/* check to make sure that the program was issued with the correct number of arguments */
	if ( argc < 2) {
		xos_error_exit("Usage: imgsrv <config file>");
	}

	DcsConfig config;
	config.setUseDefaultConfig(false);
	config.setConfigFile(argv[1]);

	if (!config.load()) {
		LOG_SEVERE("error failed to load config file");
		xos_error_exit("Error: failed to load config\n");
	}
		
	dcsLog.update(config);


	gListeningPort[WEB_INTERFACE] = config.getImgsrvWebPort();
	gListeningPort[GUI_INTERFACE] = config.getImgsrvGuiPort();
	gListeningPort[HTTP_INTERFACE] = config.getImgsrvHttpPort();
	gTempJpgDirectory = config.getImgsrvTmpDir();
	gMaxIdleTime = config.getImgsrvMaxIdleTime();
	gImpersonHost = config.getImpersonHost();
	gImpersonPort = config.getImpersonPort();
	gAuthHost = config.getAuthHost();
	gAuthPort = config.getAuthPort();
	gAuthSecurePort = config.getAuthSecurePort();
	gAuthAppName = "SMBTest";
	gAuthCaFile = "";
	gAuthCaDir = "";
	gAuthMethod = "";
	std::string tmp;
	if (config.get("auth.trusted_ca_file", tmp))
		gAuthCaFile = XosStringUtil::trim(tmp);
	if (config.get("auth.trusted_ca_directory", gAuthCaDir))
		gAuthCaDir = XosStringUtil::trim(tmp);

	gImageCacheSize = config.getInt("imgsrv.imageCacheSize", 10);
	gMaxClientCount = config.getInt("imgsrv.maxClientCount", 100);
	
	struct 	hostent* host;

	/* get host information from host name */
	host = gethostbyname( gImpersonHost.c_str() );
		
	/* check for error looking up the name */
	if ( host == NULL ) {
		LOG_SEVERE("Could not resolved impersonation hostname");
		xos_error_exit("Could not resolved impersonation hostname");
	}

	gImpersonIpArray[0] = host->h_addr[0];
	gImpersonIpArray[1] = host->h_addr[1];
	gImpersonIpArray[2] = host->h_addr[2];
	gImpersonIpArray[3] = host->h_addr[3];
	
	
    LOG_INFO1("http port = %d\n", gListeningPort[HTTP_INTERFACE]);
    LOG_INFO1("imperson host = %s\n", gImpersonHost.c_str());
    LOG_INFO1("imperson port = %d\n", gImpersonPort);
    LOG_INFO1("max idle time = %d seconds\n", gMaxIdleTime);

	//change the title bar on unix terminal for convenience.
	printf("\033]2;Image Server %c",7);

	LOG_INFO("STARTING IMAGE SERVER.\n");

	//set the appropriate environment for sockets.
	if ( xos_socket_library_startup() != XOS_SUCCESS ) {
		LOG_SEVERE("start_server -- error initializing socket library");
		xos_error_exit("start_server -- error initializing socket library");
	}
		
	/* use main thread to handle incoming connections from http clients */
	incoming_client_handler( (void*)HTTP_INTERFACE );

}
