#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "RobotSystem.h"
#include "log_quick.h"

static CRobotSystem* gpRobotSystem = NULL;

static void ctrl_c_handler( int value )
{
    if (gpRobotSystem)
    {
        gpRobotSystem->OnStop( );
    }
}

int main(int argc, char** argv)
{

    LOG_QUICK_OPEN;
    CRobotSystem mySystem;

    //setup signal to stop the program
    gpRobotSystem = &mySystem;
	signal( SIGINT, ctrl_c_handler );
    LOG_FINEST( "run from front, not as a service ");
    mySystem.RunFront( );   //block until Ctrl-C
    LOG_FINEST( "out of running: received ctrl-c ");

	LOG_QUICK_CLOSE;

	return 0;
}

