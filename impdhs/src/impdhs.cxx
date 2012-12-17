#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "ImpersonSystem.h"
#include "log_quick.h"
#include "DcsConfig.h"

static FILE* gLockFileHandle = NULL;

static ImpersonSystem* gpSystem = NULL;

static void ctrl_c_handler( int value )
{
    if (gpSystem)
    {
        gpSystem->OnStop( );
    }

	printf("Got a signal\n");
    signal(SIGINT, NULL);
}

int main(int argc, char** argv)
{
    if (argc < 2 || argv[1][0] == '-') {
    	printf("Usage: impdhs <beamline> [-b]\n");
    	return 1;
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

    char lockFilename[1024] = "/tmp/impdhs_";
    strcat( lockFilename, argv[1] );
    strcat( lockFilename, ".lock" );
    printf( "lockfile: %s\n", lockFilename );
    gLockFileHandle = checkLockFile( lockFilename );
    if (gLockFileHandle == NULL) {
        printf( "failed to pass lock file check\n" );
        printf( "Please kill the previous one before restart\n" );
        xos_error_exit( "exit" );
    }

    char logFilePattern[256] = "impdhs_";
    strcat( logFilePattern, argv[1] );
    strcat( logFilePattern, "_%g_%u.txt" );
    log_quick_set_file_pattern( logFilePattern );

    LOG_QUICK_OPEN;
    if (backgroundMode) {
        LOG_FINEST( "run as a daemon");
    } else {
        LOG_FINEST( "run from front, not as a daemon");
    }

	std::string hostName;
	if (getenv("HOSTNAME") != null)
		hostName = getenv("HOSTNAME");
   else
	   hostName = getenv("HOST");

	//change the title bar for convenience.
	printf("\033]2;impdhs %s on %s\07", argv[1], hostName.c_str());


    //setup signal to stop the program
   	gpSystem = ImpersonSystem::getInstance();


    if (!gpSystem->loadProperties(argv[1]))
    	return 1;


	signal( SIGINT, ctrl_c_handler );

    //tell waiter that we are ready
    updateLockFile( gLockFileHandle );

    gpSystem->RunFront( );   //block until Ctrl-C
    LOG_FINEST( "out of running: received ctrl-c ");

	LOG_QUICK_CLOSE;

	return 0;
}

