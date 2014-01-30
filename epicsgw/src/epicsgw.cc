#include <signal.h>
#include <stdio.h>
#include "gw_system.h"
#include "log_quick.h"

static GatewaySystem* gpSystem(NULL);
static FILE* gLockFileHandle = NULL;

void ctrl_c_handler( int value )
{
    if (gpSystem)
    {
        gpSystem->onStop( );
    }
    signal( SIGINT, NULL );
}

int main( int argc, char** argv )
{
    if (argc < 2)
    {
        LOG_SEVERE1( "%s beameline_name [-b]\n", argv[0] );
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
    char lockFilename[1024] = "/tmp/epicsgw_";
    strcat( lockFilename, argv[1] );
    strcat( lockFilename, ".lock" );
    printf( "lockfile: %s\n", lockFilename );
    gLockFileHandle = checkLockFile( lockFilename );
    if (gLockFileHandle == NULL) {
        printf( "failed to pass lock file check\n" );
        printf( "Please kill the previous one before restart\n" );
        xos_error_exit( "exit" );
    }
    char logFilePattern[256] = "epicsgw_";
    strcat( logFilePattern, argv[1] );
    strcat( logFilePattern, "_%g_%u.txt" );
    log_quick_set_file_pattern( logFilePattern );
    LOG_QUICK_OPEN;
    if (backgroundMode) {
        LOG_FINEST( "run as a daemon");
    } else {
        LOG_FINEST( "run from front, not as a daemon");
    }
    
    LOG_FINEST1( "context=%p", ca_current_context( ));


    gpSystem = new GatewaySystem( );

    signal( SIGINT, ctrl_c_handler );

    gpSystem->loadConfig( argv[1] );

    //change the title bar for the convience.
    printf("\033]2;epicsgw for %s%c", argv[1],7);

    updateLockFile( gLockFileHandle );
    gpSystem->runFront( );

    delete gpSystem;
    gpSystem = NULL;
    LOG_FINEST1( "context=%p", ca_current_context( ));
    LOG_FINEST( "done" );
    LOG_QUICK_CLOSE;

    printf( "system shutdown ok\n" );
    return 0;
}
