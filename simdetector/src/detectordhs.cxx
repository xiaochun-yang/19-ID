#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "DetectorSystem.h"
#include "log_quick.h"

/**
 * Global DetectorSystem. Used by other classes to access the config.
 */
DetectorSystem* gDetectorSystem = NULL;

static FILE* gLockFileHandle = NULL;

static void ctrl_c_handler( int value )
{
	printf("in ctrl_c_handler\n");
    if (gDetectorSystem)
    {
        gDetectorSystem->OnStop( );
    }
}

int main(int argc, char** argv)
{
    if (argc < 2 || argv[1][0] == '-') {
		printf("Usage: detectordhs <beamline> [-b]\n"); fflush(stdout);
		return 0;
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

    char lockFilename[1024] = "/tmp/dhs_detector_";
    strcat( lockFilename, argv[1] );
    strcat( lockFilename, ".lock" );
    printf( "lockfile: %s\n", lockFilename );
    gLockFileHandle = checkLockFile( lockFilename );
    if (gLockFileHandle == NULL) {
        printf( "failed to pass lock file check\n" );
        printf( "Please kill the previous one before restart\n" );
        xos_error_exit( "exit" );
    }
    char logFilePattern[256] = "simdetector_";
    strcat( logFilePattern, argv[1] );
    strcat( logFilePattern, "_%g_%u.txt" );
    log_quick_set_file_pattern( logFilePattern );

    LOG_QUICK_OPEN;
    if (backgroundMode) {
        LOG_FINEST( "run as a daemon");
    } else {
        LOG_FINEST( "run from front, not as a daemon");
    }

	//change the title bar for convenience.
	printf("\033]2;simdetector for %s on %s\07", argv[1], getenv("HOSTNAME"));

    DetectorSystem mySystem(argv[1]);
        
    //setup signal to stop the program
    gDetectorSystem = &mySystem;
//	signal( SIGINT, ctrl_c_handler );

    updateLockFile( gLockFileHandle );
    mySystem.RunFront( );   //block until Ctrl-C
    LOG_FINEST( "Exiting detectordhs");

	LOG_QUICK_CLOSE;

	return 0;
}

