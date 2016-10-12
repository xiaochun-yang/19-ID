#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include "xiaSaturnSystem.h"
#include "log_quick.h"
#include "DcsConfig.h"


xiaSaturnSystem* gpSystem = NULL;

/*static void ctrl_c_handler( int value )
{
    if (gpSystem)
    {
        gpSystem->OnStop( );
    }

	printf("Got a signal\n");
	exit(0);
}*/

int main(int argc, char** argv)
{

    LOG_QUICK_OPEN_STDOUT;

    if (argc != 2) {
    	LOG_SEVERE("Usage: xiaSaturn <beamline>\n");
    	return 1;
   }

    puts (argv[1]);

    //setup signal to stop the program
    xiaSaturnSystem* gpSystem = xiaSaturnSystem::getInstance();


    LOG_FINEST( "Loading Properties file\n");

    if (!gpSystem->loadProperties(argv[1]))
    	return 1;

    LOG_FINEST( "Loaded Properties file\n");


    LOG_FINEST( "run from front, not as a service");



//	signal( SIGINT, ctrl_c_handler );

    gpSystem->RunFront( );   //block until Ctrl-C
    LOG_FINEST( "out of running: received ctrl-c ");

	LOG_QUICK_CLOSE;

	return 0;
}

