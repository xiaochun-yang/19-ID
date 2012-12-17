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

#include "xos.h"

/* local include files */
#include "dhs_network.h"
#include "dhs_database.h"
#include "dhs_config.h"
#include "dhs_motor_messages.h"
#include "dhs_monitor.h"
#include "DcsConfig.h"
#include "log_quick.h"
#include "XosStringUtil.h"

void initLogging();
bool updateLogging(char * logFilePattern);
bool isLoggingDirectoryWritable(char * logFilePattern);
bool isDirectoryWritable( const char * dirpath );

FILE* gLockFileHandle = NULL;

/*global data*/
string   gDhsInstanceName;
string   gBeamlineName;
string   gHardwareType;
long     gWatchdogKickPeriod;

DcsConfig gConfig;

static log_manager_t* log_manager = NULL;
static log_handler_t* file_handler = NULL;
static log_handler_t* stdout_handler = NULL;
static log_formatter_t* trace_formatter = NULL;

int main( int argc, char *argv[] )
	{
	/* Several DHS's are allowed to run on a single host computer. */
	/* user specifies which DHS at the command prompt */
	if ( argc < 3  )
		{
      printf("usage: dhs beamlineName hardwarename [-b]\n");
      xos_error_exit("exit");
		}
    bool backgroundMode = false;
    for (int i = 1; i < argc; ++i) {
        if (strcmp( argv[i], "-b" ) == 0) {
            backgroundMode = true;
        }
    }
    if (backgroundMode) {
        restart_in_daemon( argc, argv );
    }


    char lockFilename[1024] = "/tmp/dhs";
    //generate lock file name
    //because dhs is used for many hardware
    //we will use command line arguements to distinguish them
    for (int i = 1; i < argc; ++i)
    {
        size_t llAvailable = sizeof(lockFilename) - strlen(lockFilename) - 1;
        if (argv[i][0] != '-' && llAvailable > 1 + strlen( argv[i] ))
        {
            strcat( lockFilename, "_" );
            strcat( lockFilename, argv[i] );
        }
    }
    strcat( lockFilename, ".lock" );
    printf( "lockfile: %s\n", lockFilename );
    gLockFileHandle = checkLockFile( lockFilename );
    if (gLockFileHandle == NULL)
    {
        printf( "failed to pass lock file check\n" );
        printf(
        "Please kill the previous one and remove lock file before restart\n" );
        xos_error_exit( "exit" );
    }

	/* local variables */
	xos_socket_port_t		dcsServerListeningPort;
	string					dcsServerHostName;
	xos_boolean_t			needConfigurationFromServer;
	xos_thread_t			databaseRefreshThread;
	xos_thread_t			devicePollingThread;
	xos_thread_t			watchDogThread;
	string		  			localDatabaseFileName;
	xos_time_t				autoFlushPeriod;
	xos_time_t				devicePollPeriod;
	threadList				controllerList;

	char lineStr[500];

	initLogging();


   gBeamlineName=argv[1];
	gDhsInstanceName = argv[2];

	gConfig.setConfigRootName(gBeamlineName);
	bool ret = gConfig.load();

	if (!ret)
      {
		LOG_SEVERE1("Failed to load config file %s\n", gConfig.getConfigFile().c_str());
      xos_error_exit("exit");
      }


	LOG_INFO("main:  get dcss hostname\n");
	dcsServerHostName = gConfig.getDcssHost();

    if (getenv("HOST") != 0 && getenv("HOST") == dcsServerHostName) dcsServerHostName = "localhost";
    if (getenv("HOSTNAME") != 0 && getenv("HOSTNAME") == dcsServerHostName) dcsServerHostName = "localhost";

    LOG_FINEST1( "connecting to dcss at %s",dcsServerHostName.c_str() );

   if (dcsServerHostName == "" ) {
		LOG_SEVERE1("DCSS hostname not specified in %s\n", gConfig.getConfigFile().c_str());
      xos_error_exit("exit");
	}

	LOG_INFO("main: get listening port\n");
	dcsServerListeningPort = gConfig.getDcssHardwarePort();
   if (dcsServerListeningPort == 0 ) {
		LOG_SEVERE1("main -- DCSS listening port not specified in %s\n", gConfig.getConfigFile().c_str());
		xos_error_exit("exit");
   }



	StrList dhsInstanceList;
   if ( gConfig.getRange("dhs.instance", dhsInstanceList)  == 0 ) {
		LOG_SEVERE("Could not find dhs.instance in config.\n");
		xos_error_exit("exit");
	}

   char instanceName[500];
   char hardwareType[500];
   char localDatabaseName[500];
   char logFilePattern[500];

   bool foundDhsInstance = 0;
	StrList::const_iterator i = dhsInstanceList.begin();
	for (; i != dhsInstanceList.end(); ++i)
		{
		strncpy(lineStr, (*i).c_str(), 500);
		if ( sscanf( lineStr, "%s %s %s %s %ld %ld %ld",
						 instanceName,
						 hardwareType,
                   logFilePattern,
						 localDatabaseName,
                   &autoFlushPeriod,
                   &gWatchdogKickPeriod,
                   &devicePollPeriod ) != 7 )
			{
			//only throw away blank lines
			if ( strcmp(lineStr,"\n") != 0 )
				{
				LOG_SEVERE1("Invalid dhs.instance definition in config file: %s",lineStr);
            printf("====================CONFIG ERROR=================================\n");
				printf("Invalid dhs.instance definition in config file: %s",lineStr);
            printf("Example:\n");
            printf("dhs.instance=instanceName hardwareType logFilePattern memoryMapName autoflush watchdog devicepollTime\n");
            printf("   where -instanceName- the name of the dhs\n");
            printf("         -hardwareType- dmc2180,axis2400,quantum4,quantum315, or marccd\n");
            printf("         -logFilePattern- the name of the log file to be generated\n");
            printf("         -memoryMapName- the name of the memory mapped file for storing the latest motor positions\n");
            printf("         -autoflush- how often to update the localDatabase in ms\n");
            printf("         -watchdog- how often to kick the watchdog. Used in the dmc2180 hardware type\n");
            printf("         -devicepollTime- how often to update the motor position to dcss in ms\n");
				exit(1);
				}
			}

		if (strcmp(instanceName, gDhsInstanceName.c_str() ) == 0 )
			{
         foundDhsInstance = 1;
         LOG_INFO1("found definition in config file: %s\n",lineStr);
         break;
			}
		}

   if ( !foundDhsInstance )
      {
      LOG_SEVERE1("Could not find DHS instance '%s' in the config file.", gDhsInstanceName.c_str());
      printf("====================CONFIG ERROR=================================\n");
      printf("Could not find DHS instance '%s' in the config file.\n", gDhsInstanceName.c_str());
      printf("Example:\n");
      printf("dhs.instance=%s hardwareType localdatabasename logFilePattern autoflush watchdog devicepollTime\n",gDhsInstanceName.c_str());
      xos_error_exit("Exit");
      }


   if ( ! updateLogging( logFilePattern ) ) {
      xos_error_exit("exit");
   }


   gHardwareType=hardwareType;
   localDatabaseFileName = localDatabaseName;
	LOG_FINEST1("Local database: %s\n", localDatabaseFileName.c_str() );

	LOG_FINEST("main: initialize local database\n");
	/* initialize local database */
	if ( dhs_database_initialize( localDatabaseFileName.c_str(),
											& needConfigurationFromServer ) == XOS_FAILURE )
		{
		LOG_SEVERE( "main -- error opening local database");
      xos_error_exit("Exit");
		}

	LOG_INFO("main start flush thread.\n");
	/* start a thread to flush database to disk periodically */
	if ( xos_thread_create( & databaseRefreshThread,
									 dhs_database_flush_thread_routine,
									 (void *) autoFlushPeriod ) == XOS_FAILURE )
		{
		LOG_SEVERE( "main -- error starting database flush thread");
        xos_error_exit("Exit");
		}

	LOG_FINEST("main start devices and threads\n");
	/* configure devices and start threads */
	if ( dhs_config_initialize( controllerList ) == XOS_FAILURE )
		{
		LOG_SEVERE( "main -- error initializing configuration");
      xos_error_exit("Exit");
		}

	LOG_FINEST("Change title bar\n");
	//change the title bar for convience.
	printf("\033]2;dhs %s for %s%c", gDhsInstanceName.c_str(), gBeamlineName.c_str(),7);

	/*CODE REVIEW 1: add synchronization step to make sure all boards are
	  configured before proceeding.  */

	//	xos_thread_sleep(10000);

	MonitorThreadStruct monitorThreadInitData;
	monitorThreadInitData.devicePollingPeriod=devicePollPeriod;
	xos_semaphore_create( &monitorThreadInitData.semaphore, 0);

	LOG_FINEST("main -- start polling thread\n");
	/* start a thread to poll devices periodically */
	if ( xos_thread_create( & devicePollingThread,
									(xos_thread_routine_t *)dhs_device_polling_thread_routine,
									(void *) &monitorThreadInitData ) == XOS_FAILURE )
	  	{
		LOG_SEVERE( "main -- error starting device polling thread");
      xos_error_exit("Exit");
		}

	/* wait for semaphores */
	if ( xos_semaphore_wait( &monitorThreadInitData.semaphore, 10000 ) != XOS_WAIT_SUCCESS )
		{
		LOG_SEVERE("Error waiting for semaphore for monitor thread.");
		}

	LOG_FINEST("main -- start watchdog thread\n");
	/* start a thread to kick watchdogs on all controller threads */
	if ( xos_thread_create( & watchDogThread,
									(xos_thread_routine_t *)dhs_watchdog_thread_routine,
									(void *)&controllerList ) == XOS_FAILURE )
		{
		LOG_SEVERE( "main -- error starting watchdog thread");
      xos_error_exit("Exit");
		}

    updateLockFile( gLockFileHandle );
	LOG_FINEST("main -- start message processing loop\n");
	/* enter dcs message processing loop -- never returns */
	if ( dhs_handle_dcs_connection( dcsServerHostName, dcsServerListeningPort
											  ) == XOS_FAILURE )
		{
		LOG_SEVERE("main -- error handling dcs connection");
      xos_error_exit("Exit");
		}

	LOG_QUICK_CLOSE;

	/* never executes */
	return 0;
	}



/****************************************************************
 *
 * initLogging
 *
 ****************************************************************/
void initLogging()
{
	g_log_init();

	log_manager = g_log_manager_new(NULL);
	gpDefaultLogger = g_get_logger(log_manager, "dhs", NULL, LOG_ALL);

	trace_formatter = log_trace_formatter_new( );

	stdout_handler = g_create_log_stdout_handler();
	if (stdout_handler != NULL) {
		log_handler_set_level(stdout_handler, LOG_ALL);
		log_handler_set_formatter(stdout_handler, trace_formatter);
		logger_add_handler(gpDefaultLogger, stdout_handler);
	}

}

/****************************************************************
 *
 * setLogging
 *
 ****************************************************************/
bool updateLogging( char * logFilePattern )
{
	std::string level;
	bool isStdout = true;
	std::string udpHost;
	std::string filePattern;
	int fileSize = 31457280;
	int numFiles = 3;
	bool append = false;

	if ( ! isLoggingDirectoryWritable(logFilePattern) ) return false;

	std::string tmp;
	if (!gConfig.get("dhs.logStdout", tmp)) {
		LOG_WARNING("Could not find dhs.logStdout in config file\n");
		return false;
	}

	if (tmp == "false")
		isStdout = false;

	if (!gConfig.get("dhs.logFileSize", tmp)) {
		LOG_WARNING("Could not find dhs.logFileSize in config file\n");
		return false;
	}

	if (!tmp.empty())
		fileSize = XosStringUtil::toInt(tmp, fileSize);

	if (!gConfig.get("dhs.logFileMax", tmp)) {
		LOG_WARNING("Could not find dhs.logFileMax in config file\n");
		return false;
	}

	if (!tmp.empty())
		numFiles = XosStringUtil::toInt(tmp, numFiles);

	if (!gConfig.get("dhs.logLevel", level)) {
		LOG_WARNING("Could not find dhs.logLevel in config file\n");
		return false;
	}

	log_level_t* logLevel = log_level_parse(level.c_str());

	if (logLevel == NULL)
		logLevel = LOG_ALL;

	logger_set_level(gpDefaultLogger, logLevel);

	// Turn off stdout log
	if (!isStdout && stdout_handler) {
		printf("Turning off stdout log\n");
		logger_remove_handler(gpDefaultLogger, stdout_handler);
	}

	file_handler = g_create_log_file_handler(logFilePattern, append, fileSize, numFiles);
   if (file_handler != NULL) {
		log_handler_set_level(file_handler, logLevel);
		log_handler_set_formatter(file_handler, trace_formatter);
		logger_add_handler(gpDefaultLogger, file_handler);
	}

	return true;

}



bool isLoggingDirectoryWritable(char * logFilePattern) {

	char * lastSlashPtr = strrchr(logFilePattern,'/');

	if (lastSlashPtr == (char *)null) {
		LOG_SEVERE1("Logging directory needs full path: %s", logFilePattern);
		return false;
	}

	int lastSlash=lastSlashPtr - logFilePattern + 1;
	char logDirectory[500];
	strncpy(logDirectory,logFilePattern,lastSlash);
	logDirectory[lastSlash]=0x00;

	if ( !isDirectoryWritable( logDirectory )) {
		LOG_SEVERE1("Cannot write to logging directory: %s", logDirectory);
		return false;
	}

	return true;
}

bool isDirectoryWritable( const char * dirpath ) {
    return access( dirpath, W_OK )?false:true;
}
