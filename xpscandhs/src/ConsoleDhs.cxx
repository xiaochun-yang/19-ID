#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "ConsoleSystem.h"
#include "log_quick.h"

static CConsoleSystem* gpConsoleSystem = NULL;

static void ctrl_c_handler( int value )
{
    if (gpConsoleSystem)
    {
        gpConsoleSystem->OnStop( );
    }
}

int main(int argc, char** argv)
{

    LOG_QUICK_OPEN;

    CConsoleSystem mySystem;

    //setup signal to stop the program
    gpConsoleSystem = &mySystem;
    signal( SIGINT, ctrl_c_handler );

    LOG_FINEST( "run from front, not as a service ");
    mySystem.RunFront( );   //block until Ctrl-C
    LOG_FINEST( "out of running: received ctrl-c ");

    LOG_QUICK_CLOSE;

    return 0;
}

